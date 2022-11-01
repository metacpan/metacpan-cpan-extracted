package SSITest;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use parent qw( Apache2::SSI );
    use Apache2::SSI::URI;
    use Apache2::SSI::File;
    use Apache2::Const -compile => qw( :common :http DECLINED );
    use APR::URI ();
    use URI::file;
    # use Devel::Confess;
    use constant BASE_URI => '/ssi';
    use constant TEST_URI_1 => './ssi/include.cgi';
    use constant TEST_URI_2 => './not-existing.txt';
};

sub handler : method
{
    my( $class, $r ) = @_;
    $r->log_error( "${class}: Received request for uri \"", $r->uri, "\" matching file \"", $r->filename, "\"." );
    my $uri = APR::URI->parse( $r->pool, $r->uri );
    my $path = [split( '/', $uri->path )]->[-1];
    my $self = bless( { apache_request => $r, debug => int( $r->dir_config( 'Apache2_SSI_DEBUG' ) ) } => $class );
    my $code = $self->can( $path );
    if( !defined( $code ) )
    {
        $r->log_error( "No method \"$path\" for SSI testing." );
        return( Apache2::Const::DECLINED );
    }
    my $res = $code->( $self );
    return( Apache2::Const::OK );
}

sub apache_request { return( shift->{apache_request} ); }

sub error
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
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
    return( $self->reply( "failed\nI was expecting \"$expect\", but got \"$what\"." ) );
}

sub message
{
    my $self = shift( @_ );
    return unless( $self->{debug} );
    my $class = ref( $self );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
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
    my $r = $self->apache_request;
    $r->status( $code );
    $r->print( @_ );
    $r->rflush;
    return( $code );
}

sub success { return( shift->reply( Apache2::Const::HTTP_OK => 'ok' ) ); }
## From 01 to 19 those are the Apache2::SSI::URI test units
sub test01
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1;
    return( $self->ok( defined( $f ) && $f->isa( 'Apache2::SSI::URI' ) ) );
}

sub test02
{
    my $self = shift( @_ );
    my $failed = $self->_get_test_uri_2;
    return( $self->ok( defined( $failed ) && $failed->isa( 'Apache2::SSI::URI' ) ) );
}

sub test03
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->document_path eq BASE_URI . '/include.cgi' ) );
}

sub test04
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->document_directory eq BASE_URI ) );
}

sub test05
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1 || return;
    my $base_uri = $f->base_uri;
    return( $self->ok( "$base_uri" eq '/' ) );
}

sub test06
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->path_info eq '' ) );
}

sub test07
{
    my $self = shift( @_ );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->query_string eq '' ) );
}

sub test08
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->document_filename eq $r->document_root . BASE_URI . "/include.cgi" ) );
}

sub test09
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->document_root eq $r->document_root ) );
}

sub test10
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->document_uri eq BASE_URI . "/include.cgi" ) );
}

sub test11
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    my $f2 = $f->clone;
    $f2->path_info( '/some/pathinfo' );
    return( $self->ok( $f2->document_uri eq BASE_URI . "/include.cgi/some/pathinfo" ) );
}

sub test12
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    my $f2 = $f->clone;
    $f2->path_info( '/some/pathinfo' );
    my $u = APR::URI->parse( $r->pool, $f2->document_uri );
    my $real = $u->rpath;
    return( $self->ok( $real eq BASE_URI . '/include.cgi' ) );
}

sub test13
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    my $f2 = $f->clone;
    $f2->path_info( '/some/pathinfo' );
    $f2->query_string( 'q=something&l=ja_JP' );
    return( $self->ok( $f2->document_uri eq BASE_URI . "/include.cgi/some/pathinfo?q=something&l=ja_JP" ) );
}

sub test14
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    my $f2 = $f->clone;
    $f2->path_info( '/some/pathinfo' );
    $f2->query_string( 'q=something&l=ja_JP' );
    $f2->filename( $r->document_root . BASE_URI . "/../ssi/plop.pl" );
    return( $self->ok( $f2->filename eq $r->document_root . BASE_URI . "/plop.pl" ) );
}

sub test15
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    my $f2 = $f->clone;
    $f2->path_info( '/some/pathinfo' );
    $f2->query_string( 'q=something&l=ja_JP' );
    $f2->filename( $r->document_root . BASE_URI . "/../ssi/plop.pl" );
    return( $self->ok( $f2->document_uri eq BASE_URI . "/plop.pl/some/pathinfo?q=something&l=ja_JP" ) );
}

sub test16
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( ( (CORE::stat( $r->document_root . '/' . TEST_URI_1 ))[2] & 07777 ) eq $f->finfo->mode ) );
}

sub test17
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->finfo->is_file ) );
}

sub test18
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->parent->document_uri eq BASE_URI ) );
}

sub test19
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_uri_1 || return;
    return( $self->ok( $f->uri eq BASE_URI . '/include.cgi' ) );
}

## Tests for Apache2::SSI::File
sub test20
{
    my $self = shift( @_ );
    my $f = $self->_get_test_file_1;
    return( $self->ok( defined( $f ) && $f->isa( 'Apache2::SSI::File' ) ) );
}

## Non-existing file object
sub test21
{
    my $self = shift( @_ );
    my $failed = $self->_get_test_file_2;
    return( $self->ok( defined( $failed ) && $failed->isa( 'Apache2::SSI::File' ) ) );
}

## Non-existing file code
sub test22
{
    my $self = shift( @_ );
    my $failed = $self->_get_test_file_2;
    return( $self->ok( defined( $failed ) && $failed->code == 404 ) );
}

## Non-existing file code
sub test23
{
    my $self = shift( @_ );
    my $failed = $self->_get_test_file_2;
    return( $self->ok( defined( $failed ) && $failed->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE ) );
}

## Filename match expectation
sub test24
{
    my $self = shift( @_ );
    my $f = $self->_get_test_file_1;
    my $base = $f->base_dir;
    return( $self->ok( $f->filename eq $self->apache_request->document_root . BASE_URI . '/include.cgi' ) );
}

## filename updated with non-existing file
sub test25
{
    my $self = shift( @_ );
    my $f = $self->_get_test_file_1;
    my $base = $f->base_dir;
    my $f2 = $f->clone;
    $f2->filename( $self->apache_request->document_root . BASE_URI . "/../ssi/plop.pl" );
    return( $self->ok( $f2->filename eq $self->apache_request->document_root . BASE_URI . "/plop.pl" ) );
}

## Resulting code from filename updated with non-existing file
sub test26
{
    my $self = shift( @_ );
    my $f = $self->_get_test_file_1;
    my $base = $f->base_dir;
    my $f2 = $f->clone;
    $f2->filename( $self->apache_request->document_root . BASE_URI . "/../ssi/plop.pl" );
    return( $self->ok( $f2->code == 404 ) );
}

## Resulting file type from filename updated with non-existing file
sub test27
{
    my $self = shift( @_ );
    my $f = $self->_get_test_file_1;
    my $base = $f->base_dir;
    my $f2 = $f->clone;
    $f2->filename( $self->apache_request->document_root . BASE_URI . "/../ssi/plop.pl" );
    return( $self->ok( $f2->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE ) );
}

sub test28
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_file_1 || return;
    return( $self->ok( ( (CORE::stat( $self->apache_request->document_root . '/' . TEST_URI_1 ))[2] & 07777 ) eq $f->finfo->mode ) );
}

sub test29
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_file_1 || return;
    return( $self->ok( $f->finfo->is_file ) );
}

sub test30
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = $self->_get_test_file_1 || return;
    return( $self->ok( $f->parent->filename eq $self->apache_request->document_root . BASE_URI ) );
}

sub _get_test_uri_1
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = Apache2::SSI::URI->new(
        apache_request => $r,
        document_uri => TEST_URI_1,
        document_root => $r->document_root,
        debug => $self->{debug},
    ) || return( $self->error( "Unable to get the Apache2::SSI::URI object for uri \"", TEST_URI_1, "\"." ) );
    return( $f );
}

sub _get_test_uri_2
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = Apache2::SSI::URI->new(
        apache_request => $r,
        base_uri => BASE_URI,
        document_uri => TEST_URI_2,
        document_root => $r->document_root,
        debug => $self->{debug},
    ) || return( $self->error( "Unable to get the Apache2::SSI::URI object for uri \"", TEST_URI_2, "\"." ) );
    return( $f );
}

sub _get_test_file_1
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = Apache2::SSI::File->new( $r->document_root . '/' . TEST_URI_1,
        apache_request => $r,
        debug => $self->{debug},
    ) || return( $self->error( "Unable to get the Apache2::SSI::File object for file \"", $r->document_root . '/' . TEST_URI_1, "\"." ) );
    return( $f );
}

sub _get_test_file_2
{
    my $self = shift( @_ );
    my $r = $self->apache_request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $f = Apache2::SSI::File->new( $r->document_root . '/' . TEST_URI_2,
        apache_request => $r,
        debug => $self->{debug},
    ) || return( $self->error( "Unable to get the Apache2::SSI::File object for file \"", $r->document_root . '/' . TEST_URI_2, "\"." ) );
    return( $f );
}

1;

__END__

