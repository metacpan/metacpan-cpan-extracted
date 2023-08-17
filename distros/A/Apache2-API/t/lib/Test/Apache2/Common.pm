package Test::Apache2::Common;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use Apache::TestConfig;
    use APR::URI ();
    use Apache2::API;
    use Module::Generic::File qw( file );
    use Scalar::Util;
};

use strict;
use warnings;

our $config = Apache::TestConfig->thaw->httpd_config;
our $class2log = {};

sub handler : method
{
    my( $class, $r ) = @_;
    my $debug = $r->dir_config( 'API_DEBUG' );
    $r->log_error( "${class}: Received request for uri \"", $r->uri, "\" matching file \"", $r->filename, "\": ", $r->as_string );
    my $uri = APR::URI->parse( $r->pool, $r->uri );
    my $path = [split( '/', $uri->path )]->[-1];
    my $api = Apache2::API->new( $r, debug => $debug, compression_threshold => 102400 ) || do
    {
        $r->log_error( "$class: Error instantiating Apache2::API object: ", Apache2::API->error );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $self = bless( { request => $r, api => $api, debug => int( $r->dir_config( 'API_DEBUG' ) ) } => $class );
    my $code = $self->can( $path );
    if( !defined( $code ) )
    {
        $r->log_error( "No method \"$path\" for testing." );
        return( Apache2::Const::DECLINED );
    }
    $r->err_headers_out->set( 'Test-No' => $path );
    my $rc = $code->( $self );
    $r->log_error( "$class: Returning HTTP code '$rc' for method '$path'" );
    if( $rc == Apache2::Const::HTTP_OK )
    {
        # https://perl.apache.org/docs/2.0/user/handlers/intro.html#item_RUN_FIRST
        # return( Apache2::Const::DONE );
        return( Apache2::Const::OK );
    }
    else
    {
        return( $rc );
    }
    # $r->connection->client_socket->close();
    exit(0);
}

sub api { return( shift->{api} ); }

sub request { return( shift->{request} ); }

sub debug
{
    my $self = shift( @_ );
    $self->{debug} = shift( @_ ) if( @_ );
    return( $self->{debug} );
}

sub error
{
    my $self = shift( @_ );
    my $r = $self->request;
    $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    my $ref = [@_];
    my $error = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) );
    warn( $error );
    $r->log_error( $error );
    $r->print( $error );
    $r->rflush;
    return;
}

sub failure { return( shift->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => 'failed' ) ); }

sub is
{
    my $self = shift( @_ );
    my( $what, $expect ) = @_;
    return( $self->success ) if( $what eq $expect );
    return( $self->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => "failed\nI was expecting \"$expect\", but got \"$what\"." ) );
}

sub message
{
    my $self = shift( @_ );
    return unless( $self->{debug} );
    my $class = ref( $self );
    my $r = $self->request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $ref = [@_];
    my $sub = (caller(1))[3] // '';
    my $line = (caller())[2] // '';
    $sub = substr( $sub, rindex( $sub, ':' ) + 1 );
    $r->log_error( "${class} -> $sub [$line]: ", join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) ) );
    return( $self );
}

sub ok
{
    my $self = shift( @_ );
    my $cond = shift( @_ );
    return( $cond ? $self->success : $self->failure );
}

sub reply
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my $r = $self->request;
    $r->content_type( 'text/plain' );
    $r->status( $code );
    $r->rflush;
    $r->print( @_ );
    return( $code );
}

sub success { return( shift->reply( Apache2::Const::HTTP_OK => 'ok' ) ); }

sub _request { return( shift->{request} ); }

sub _target { die( "This method needs to be superseeded in the inheriting package." ) }

sub _test
{
    my $self = shift( @_ );
    my $opts = shift( @_ );
    die( "Argument provided is not an hash reference." ) if( ref( $opts ) ne 'HASH' );
    my $class = ref( $self );
    my $api = $self->api;
    my $r = $self->request;
    my $debug = $self->debug;
    my $meth = $opts->{method} || do
    {
        $r->log_error( "$[class}: no method provided to test." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    # expect may be undef
    exists( $opts->{expect} ) || do
    {
        $r->log_error( "$[class}: no expected value provided to test method '$meth'." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $expect = $opts->{expect};
    my $args = exists( $opts->{args} ) ? $opts->{args} : undef;
    $opts->{type} //= '';
    my $obj = $self->_target || do
    {
        $r->log_error( "$[class}: Cannot get a target object." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $code = $obj->can( $meth ) || do
    {
        $r->log_error( "$[class}: Method '$meth' is not supported in ", ref( $obj ), "." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $base_path;
    unless( $base_path = $class2log->{ ref( $obj ) } )
    {
        my @parts = split( /::/, ref( $obj ) );
        my $parent_path = $config->{vars}->{t_logs} || die( "No 't_logs' variable in Apache::TestConfig->thaw->httpd_config" );
        $parent_path = file( $parent_path );
        $base_path = $parent_path->child( join( '/', map( lc( $_ ), split( /::/, ref( $obj ) ) ) ) );
        $base_path->mkpath if( !$base_path->exists );
        $class2log->{ ref( $obj ) } = $base_path;
    }
    my $log_file = $base_path->child( "${meth}.log" );
    my $io = $log_file->open( '>', { autoflush => 1, binmode => 'utf8' } ) || 
        die( "Unable to open test log file \"$log_file\" in write mode: $!" );
    
    my $val = $args ? $code->( $obj, @$args ) : $code->( $obj );
    my $rv;
    if( ref( $expect ) eq 'CODE' )
    {
        $rv = $expect->( $val, { object => $self, log => sub{ $io->print( @_, "\n" ) } } );
    }
    elsif( $opts->{type} eq 'boolean' )
    {
        $rv = ( int( $val // '' ) == $expect );
        if( !$rv )
        {
            $io->print( "Boolean value expected (", ( $expect // 'undef' ), "), but got '", int( $val // '' ), "'\n" );
        }
    }
    elsif( $opts->{type} eq 'isa' )
    {
        $rv = ( Scalar::Util::blessed( $val ) && $val->isa( $expect ) );
        if( !$rv )
        {
            $io->print( "Object of class '", ( $expect // 'undef' ), "', but instead got '", ( $val // 'undef' ), "'\n" );
        }
    }
    else
    {
        if( !defined( $val ) )
        {
            $rv = !defined( $expect );
            if( !$rv )
            {
                $io->print( "Expected a defined value (", ( $expect // 'undef' ), "), but instead got an undefined one.\n" );
            }
        }
        elsif( !defined( $expect ) )
        {
            $rv = 0;
            if( !$rv )
            {
                $io->print( "Expected an undefined value, but instead got a defined one (", ( $val // 'undef' ), ").\n" );
            }
        }
        else
        {
            $rv = ( $val eq $expect );
            if( !$rv )
            {
                $io->print( "Expected the value to be '", ( $expect // 'undef' ), "', but instead got '", ( $val // 'undef' ), "'\n" );
            }
        }
    }
    $io->close;
    $log_file->remove if( $log_file->is_empty );
    $r->log_error( "$[class}: ${meth}() -> ", ( $rv ? 'ok' : 'not ok' ) ) if( $debug );
    return( $self->ok( $rv ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Test::Apache2::Common - Apache2::API Testing Common Class

=head1 SYNOPSIS

    package Test::Apache2::API;
    use parent qw( Test::Apache2::Common );
    # etc.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package to inherit from for the test modules.

=head1 METHODS

=head2 failure

Calls L</reply> with C<Apache2::Const::HTTP_EXPECTATION_FAILED> and C<failed> and returns its value, which is the HTTP code.

=head2 is

Provided with a resulting value and an expected value and this returns C<ok> if both match, or a string explaining the failure to match.

=head2 ok

Provided with a boolean value, and this returns the value returned by L</success> or L</failure> otherwise.

=head2 reply

Provided with a response http code and some text data, and this will return the response to the http client.

=head2 success

Calls L</reply> with C<Apache2::Const::HTTP_OK> and C<ok> and returns its value, which is the http code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API>, L<Apache2::API::Request>, L<Apache2::API::Response>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
