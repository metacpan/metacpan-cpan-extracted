##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Request/Params.pm
## Version v0.1.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2023/10/21
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Request::Params;
BEGIN
{
    use strict;
    use warnings;
    use version;
    use APR::Request::Param;
    # Which itself inherits from APR::Request
    use parent qw( APR::Request::Apache2 );
    use vars qw( $ERROR $VERSION );
    use Scalar::Util ();
    our $ERROR;
    our $VERSION = 'v0.1.1';
};

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $r;
    $r = shift( @_ ) if( @_ && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Apache2::RequestRec' ) );
    my $hash = {};
    if( @_ )
    {
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $hash = shift( @_ );
        }
        elsif( !( scalar( @_ ) % 2 ) )
        {
            $hash = { @_ };
        }
        else
        {
            return( __PACKAGE__->error( "Odd number of parameters provided. I was expecting a hash or hash reference." ) );
        }
    }
    $hash->{request} = $r if( $r );
    return( $this->error( "No Apache2::RequestRec was provided to instantiate our object Apache2::API::Request::Params" ) ) if( !$hash->{request} );
    return( $this->error( "Object provided is not an Apache2::RequestRec object." ) ) if( !ref( $hash->{request} ) || ( Scalar::Util::blessed( $hash->{request} ) && !$hash->{request}->isa( 'Apache2::RequestRec' ) ) );
    my $req = $class->APR::Request::Apache2::handle( $hash->{request} );
    my @ok_meth = qw( brigade_limit disable_uploads read_limit temp_dir upload_hook  );
    foreach my $meth ( @ok_meth )
    {
        if( CORE::exists( $hash->{ $meth } ) )
        {
            $req->$meth( $hash->{ $meth } );
        }
    }
    return( $req );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        $ERROR = join( '', @_ );
        return;
    }
    return( $ERROR );
}

# Borrowed from Apache2::Upload so we can better trap exception and implement more methods
sub upload
{
    # $self is a APR::Request::Apache2 object itself inheriting from APR::Request
    my $self = shift( @_ );
    # As per APR::Request: "upload() will throw an APR::Request::Error object whenever body_status() is non-zero"
    my $body;
    my $return = 0;
    # try-catch
    local $@;
    eval
    {
        if( $self->body_status != 0 )
        {
            $ERROR = "APR::Request::body_status returned non-zero (" . $self->body_status . ")";
            $return++;
        }
        $body = $self->body or ++$return;
    };
    return if( $return );
    if( $@ )
    {
        return( $self->error( "Unable to get the APR::Request body objet: $@" ) );
    }
    # So further call on this object will be handled by Apache2::API::Request::Params::Field below
    $body->param_class( 'Apache2::API::Request::Upload' );
    if( @_ )
    {
        my @uploads = grep( $_->upload, $body->get( @_ ) );
        return( wantarray() ? @uploads : $uploads[0] );
    }

    return map{ $_->upload ? $_->name : () } values( %$body ) if( wantarray() );
    return( $body->uploads( $self->pool ) );
}

sub uploads
{
    my $self = shift( @_ );
    my $body;
    my $return = 0;
    # try-catch
    local $@;
    eval
    {
        if( $self->body_status != 0 )
        {
            $ERROR = "APR::Request::body_status returned non-zero (" . $self->body_status . ")";
            $return++;
        }
        $body = $self->body or ++$return;
    };
    return if( $return );
    if( $@ )
    {
        return( $self->error( "Unable to get the APR::Request body objet: $@" ) );
    }
    # So further call on this object will be handled by Apache2::API::Request::Params::Field below
    $body->param_class( __PACKAGE__ . '::Field' );
    return( $body->uploads( $self->pool ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Apache2::API::Request::Params - Apache2 Request Fields Object

=head1 SYNOPSIS

    use Apache2::API::Request::Params;
    ## $r is the Apache2::RequestRec object
    my $req = Apache2::API::Request::Params->new(
        request         => $r,
        # pool of 2Mb
        brigade_limit   => 2097152,
        disable_uploads => 0,
        # For example: 3Mb
        read_limit      => 3145728,
        temp_dir        => '/home/me/my/tmp'
        upload_hook     => sub
        {
            my( $upload, $new_data ) = @_; 
            # do something
        },
    );

    my $form = $req->args;
    # but it is more efficient to call $request->params with $request being a Apache2::API::Request object
    my @args = $req->args;
    my $val = $req->args( 'first_name' );

    my $status = $req->args_status;

    my @names = $req->body;
    my @vals = $req->body( 'field' );
    my $status = $req->body_status;

    $req->brigade_limit( 1024 );
    my $bucket = $req->bucket_alloc;

    # No upload please
    $req->disable_uploads( 1 );

    # Returns a APR::Request::Cookie::Table object
    my $jar = $req->jar;
    my $cookie = $req->jar( 'cookie_name' );
    my @all = $req->jar( 'cookie_name' );
    my $status = $req->jar_status;

    # Returns a APR::Request::Param::Table object
    my $object = $req->param;
    my $val = $req->param( 'first_name' );
    my @multi_choice_values = $req->param( 'multi_choice_field' );
    # Note that $self->request->param( 'multi_choice_field' ) would return an array reference
    # $self being your object inheriting from Apache2::API
    my $status = $req->param_status;

    $req->parse;
    # Returns a APR::Pool object
    my $pool = $req->pool;

    my $limit = $req->read_limit;

    my $temp_dir = $req->temp_dir;

    my $upload_accessor = $req->upload;
    # Returns a Apache2::API::Request::Upload object
    my $object = $req->upload( 'file_upload' );
    # Returns a APR::Request::Param::Table object
    my $uploads = $req->uploads;

    $req->upload_hook( \&some_sub );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This is an interface to Apache mod_perl methods to access and manipulate the request data and the way Apache handles those incoming data.

This is taken from L<APR::Request>, L<APR::Request::Params>, L<APR::Request::Apache2> and L<Apache2::Request>

There are some differences with L<Apache2::Request> that provides similar interface. L<Apache2::API::Request::Params> is more cautious when dealing with L<APR::Request::body> and checks its status is 0 (i.e. successful) and traps any exceptions. 

The instantiation makes no assumptions as to the data provided, which otherwise could lead to some unpleasant error, and we thrive to provide reliability as the backbone of a REST API.

Finally, it provides access to more L<APR::Request> methods.

=head1 METHODS

=head2 new

This takes an hash or an hash reference of parameters, of which 1 is mandatory: the C<request> parameter that must be an L<Apache2::RequestRec> object.

The L<Apache2::RequestRec> object can be retrieved with L<Apache2::API::Request/request> and this module object can be instantiated more simply by calling L<Apache2::API::Request/apr>, which is basically a shortcut.

Other possible parameters are: L</brigade_limit>, L</disable_uploads>, L</read_limit>, L</temp_dir>, L</upload_hook>.

They can also be accessed as methods as documented below.

=head2 args

With no arguments, this method returns a tied L<APR::Request::Param::Table> object (or undef if the query string is absent) in scalar context, or the names (in order, with repetitions) of all the parsed query-string arguments.

With the $key argument, in scalar context this method fetches the first matching query-string arg. In list context it returns all matching args.

args() will throw an L<APR::Request::Error> object whenever args_status() is non-zero and the return value is potentially invalid (eg C<< scalar $req->args($key) >> will not die if the desired query argument was successfully parsed).

    $args = $req->args;
    @arg_names = $req->args;
    if( $args->isa('APR::Request::Param::Table') )
    {
        # ok then
    }
    ok shift( @arg_names ) eq $_ for( keys( %$args ) );

    $foo = $req->args( 'foo' );
    @bar = $req->args( 'bar' );

=head2 args_status

Returns the final status code of the L<Apache2::RequestRec> handle's query-string parser.

=head2 body

With no arguments, this method returns a tied L<APR::Request::Param::Table> object (or undef if the request body is absent) in scalar context, or the names (in order, with repetitions) of all the parsed cookies.

With the $key argument, in scalar context this method fetches the first matching body param. In list context it returns all matching body params.

L</body> will throw an L<APR::Request::Error> object whenever body_status() is non-zero and the return value is potentially invalid (eg C<< scalar $req->body($key) >> will not die if the desired body param was successfully parsed).

    my $body = $req->body;
    my @body_names = $req->body;
    if( $body->isa('APR::Request::Param::Table') )
    {
        # ok then
    }
    ok shift( @body_names ) eq $_ for( keys( %$body ) );

    my $alpha = $req->body( 'alpha' );
    my @beta = $req->body( 'beta' );

=head2 body_status

Returns the final status code of the L<Apache2::RequestRec> handle's body parser.

=head2 brigade_limit integer

Get or sets the brigade_limit for the current parser. This limit determines how many bytes of a file upload that the parser may spool into main memory. Uploads exceeding this limit are written directly to disk.

=head2 bucket_alloc

Returns the L<APR::BucketAlloc> object associated to this L<Apache2::RequestRec> handle.

=head2 disable_uploads boolean

Engage the disable_uploads hook for this request.

=for Pod::Coverage error

=head2 jar

With no arguments, this method returns a tied L<APR::Request::Cookie::Table> object (or undef if the "Cookie" header is absent) in scalar context, or the names (in order, with repetitions) of all the parsed cookies.

With the C<$key> argument, in scalar context this method fetches the first matching cookie. In list context it returns all matching cookies. The returned cookies are the values as they appeared in the incoming Cookie header.

This will trigger an L<APR::Request::Error> if L</jar_status> returned value is not zero.

    my $jar = $req->jar;
    my @cookie_names = $req->jar;
    if( $jar->isa( 'APR::Request::Cookie::Table' ) )
    {
        # ok then
    }
    ok shift( @cookie_names ) eq $_ for( keys( %$jar ) );

    my $cookie = $req->jar('apache');
    my @cookies = $req->jar('apache');

=head2 jar_status

Returns the final status code of the L<Apache2::RequestRec> handle's cookie header parser.

=head2 param

With no arguments, this method returns a tied L<APR::Request::Param::Table> object (or undef, if the query string and request body are absent) in scalar context, or the names (in order, with repetitions) of all the incoming (args + body) params.

With the $key argument, in scalar context this method fetches the first matching param. In list context it returns all matching params.

L</param> will throw an L<APR::Request::Error> object whenever param_status() is non-zero and the return value is potentially invalid (eg C<scalar $req->param($key)> will not die if the desired param was successfully parsed).

    my $param = $req->param;
    my @param_names = $req->param;
    if( $param->isa(' APR::Request::Param::Table' ) )
    {
        # ok then
    }
    ok shift( @param_names ) eq $_ for( keys( %$param ) );

    my $foo = $req->param( 'foo' );
    my @foo = $req->param( 'foo' );

=head2 param_status

Returns C<($req->args_status, $req->body_status)> in list context; otherwise returns C<< $req->args_status || $req->body_status >>.

=head2 parse

Parses the jar, args, and body tables. Returns C<< $req->jar_status, $req->args_status, $req->body_status >>.

However, it is more efficient to write:

    sub handler
    {
        my $r = shift( @_ );
        my $req = Apache2::API::Request::Params->new( request => $r );
        # efficiently parses the request body
        $r->discard_request_body;
        my $parser_status = $req->body_status;
        # ...
    }

=head2 pool

Returns the L<APR::Pool> object associated to this L<Apache2::RequestRec> handle.

=head2 read_limit integer

Get/set the read limit, which controls the total amount of bytes that can be fed to the current parser.

=head2 temp_dir string

Get/set the spool directory for uploads which exceed the configured brigade_limit.

=head2 upload

With no arguments, this method returns a tied L<APR::Request::Param::Table> object (or undef if the request body is absent) in scalar context (whose entries are L<Apache2::API::Request::Params::Upload> objects inherited from L<APR::Request::Param>), or the names (in order, with repetitions) of all the incoming uploads.

If one ore more arguments are provided, they are taken as data upload field names and their corresponding L<Apache2::API::Request::Params::Upload> objects are returned as a list in list context or the first one on the list in scalar context.

More generally, L</upload> follows the same pattern as L</param> with respect to its return values and argument list. The main difference is that its returned values are L<Apache2::API::Request::Param::Upload> object refs, not simple scalars.

=head2 uploads

This returns an L<APR::Request::Param::Table>. This is different from the L<Apache2::API::Request/upload> who returns an array reference of L<Apache2::API::Request::Params::Upload> objects.

=head2 upload_hook code reference

Provided with a code reference, this adds an upload hook callback for this request. The arguments to the C<$callback> sub are (C<$upload>, C<$new_data>).

    $r->upload_hook(sub
    {
        my( $upload, $new_data ) = @_;
        # do something
    });

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::Request>, L<APR::Request>, L<APR::Request::Param>, L<APR::Request::Apache2>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
