# Proxy class to get/set data using HTTP POST
#
package Connector::Proxy::HTTP;

use strict;
use warnings;
use English;
use Template;

use Moose;
extends 'Connector::Proxy';
with qw( 
    Connector::Role::SSLUserAgent 
    Connector::Role::LocalPath
);
 
# If not set, the path items are added to the base url as uri path
# if set, the keys from named parameters are combined and used as query string
# not implemented
#has named_parameters => (
#    is => 'rw',
#    isa => 'ArrayRef|Str|Undef',
#    trigger => \&_convert_parameters,
#    );
 

has content => (
    is  => 'rw',
    isa => 'Str',
    );

has header => (
    is  => 'ro',
    isa => 'HashRef',
    );

has content_type => (
    is  => 'rw',
    isa => 'Str',
    );

has http_method => (
    is => 'rw',
    isa => 'Str',
    default => 'PUT',
    );

has http_auth => (
    is  => 'ro',
    isa => 'HashRef',
    );

has undef_on_404 => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
    );

has chomp_result => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
    );


# If named_parameters is set using a string (necessary atm for Config::Std)
# its converted to an arrayref. Might be removed if Config::* improves
# This might create indefinite loops if something goes wrong on the conversion!
sub _convert_parameters {
    my ( $self, $new, $old ) = @_;

    # Test if the given value is a non empty scalar
    if ($new && !ref $new && (!$old || $new ne $old)) {
        my @attrs = split(" ", $new);
        $self->named_parameters( \@attrs )
    }

}
 
sub get {
    my $self = shift;

    my @args = $self->_build_path( shift );

    my $url = $self->LOCATION();
    if (@args) {
        $url .= '/'.join('/', @args);
    }
    $self->log()->debug('Make LWP call to ' . $url );

    my $req = HTTP::Request->new('GET' => $url);

    # use basic auth if supplied
    my $auth=$self->http_auth();
    if ($auth){
        $req->authorization_basic($auth->{user},$auth->{pass});
    }

    # extra headers
    my $header = $self->header();
    foreach my $key (%{$header}) {
        $req->header($key, $header->{$key} );
    }

    my $response = $self->agent()->request($req);
    
    if (!$response->is_success) {
        if ( $response->code == 404 && $self->undef_on_404()) {
            $self->log()->warn("Resource not found");
            return $self->_node_not_exists();
        }
        $self->log()->error($response->status_line);
        die "Unable to retrieve data from server";
    }

     return $self->_parse_result($response);
}

sub set {

    my $self = shift;
    my $file = shift;
    my $data = shift;
    # build url
    my $url = $self->_sanitize_path( $file, $data );
    # create content from template
    my $content;
    if ($self->content()) {
        $self->log()->debug('Process template for content ' . $self->content());
        my $template = Template->new({});

        $data = { DATA => $data } if (ref $data eq '');

        $template->process( \$self->content(), $data, \$content) || die "Error processing content template.";
    } else {
        if (ref $data ne '') {
            die "You need to define a content template if data is not a scalar";
        }
        $content = $data;
    }

    # create request
    my $req = HTTP::Request->new($self->http_method() => $url);
    # use basic auth if supplied
    my $auth=$self->http_auth();
    if ($auth){
        $req->authorization_basic($auth->{user},$auth->{pass});
    }
    # set content_type if supplied
    if ($self->content_type()){
        $req->content_type($self->content_type());
    }

    # extra headers
    my $header = $self->header();
    foreach my $key (%{$header}) {
        $req->header($key, $header->{$key} );
    }

    # set generated content
    $req->content($content);

    my $response = $self->agent()->request($req);
    # error handling
    if (!$response->is_success) {
        $self->log()->error($response->status_line);
        $self->log()->error($response->decoded_content);
        die "Unable to upload data to server";
    }

    $self->log()->debug("Set responded with: " . $response->status_line);
    $self->log()->trace($response->decoded_content) if ($self->log()->is_trace());

    return 1;
}

sub _sanitize_path {

    my $self = shift;
    my $inargs = shift;
    my $data = shift;

    my @args = $self->_build_path_with_prefix( $inargs );

    my $file = $self->_render_local_path( \@args, $data );

    my $filename = $self->LOCATION();
    if (defined $file && $file ne "") {
        $filename .= '/'.$file;
    }

    $self->log()->debug('Filename evaluated to ' . $filename);

    return $filename;
}

sub _parse_result {

    my $self  = shift;
    my $response = shift;

    my $res = $response->decoded_content;
    chomp $res if ($self->chomp_result());
    return $res;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Proxy::HTTP

=head1 DESCRIPTION

Send or retrieve data from a defined URI using HTTP.

=head1 USAGE

=head2 minimal setup

  Connector::Proxy::HTTP->new({
    LOCATION => 'https://127.0.0.1/my/base/url',
  });

=head2 connection settings

See Connector::Role::SSLUserAgent for SSL and HTTP related settings

=head2 additional options

=over

=item named_parameters

not implemented yet

=item header

A HashRef, the key/value pairs are set as HTTP headers.

=item http_auth

A HashRef with I<user> and I<pass> used as credentials to perform a
HTTP Basic Authentication.

=item chomp_result

When working with text documents the transport layer adds a trailing
newline which might be unhandy when working with scalar values. If
set to a true value, a trailing newline will be removed by calling C<chomp>.

=item undef_on_404

By default, the connector will die if a resource is not found. If set
to a true value the connector returns undef, note that die_on_undef
will be obeyed.

=back

=head2 Parameter used with set

=over

=item file/path

You can append a templated string to the LOCATION by setting I<file>,
I<path> or simply pass I<ARGS>. See Connector::Role::LocalPath for details.

=item content

A template toolkit string to generate the payload, receives the payload
argument as HasRef in I<DATA>.

=item content_type

The Content-Type header to use, default is no header.

=item http_method

The http method to use, default is PUT.

=back


=head1 Result Handling

If you need to parse the result returned by get, inherit from the class
an implement I<_parse_result>. This method receives the response object
from the user agent call and must return a scalar value which is returned
to the caller.