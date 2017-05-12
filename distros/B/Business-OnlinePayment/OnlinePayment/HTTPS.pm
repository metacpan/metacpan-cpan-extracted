package Business::OnlinePayment::HTTPS;

use strict;
use base qw(Business::OnlinePayment);
use vars qw($VERSION $DEBUG);
use Tie::IxHash;
use Net::HTTPS::Any 0.10;

$VERSION = '0.10';
$DEBUG   = 0;

=head1 NAME

Business::OnlinePayment::HTTPS - Base class for HTTPS payment APIs

=head1 SYNOPSIS

  package Business::OnlinePayment::MyProcessor;
  use base qw(Business::OnlinePayment::HTTPS);
  
  sub submit {
      my $self = shift;
  
      #...
  
      # pass a list (order is preserved, if your gateway needs that)
      ( $page, $response, %reply_headers )
          = $self->https_get( field => 'value', ... );
  
      # or a hashref
      my %hash = ( field => 'value', ... );
      ( $page, $response_code, %reply_headers )
            = $self->https_get( \%hash );
  
      #...
  }

=head1 DESCRIPTION

This is a base class for HTTPS based gateways, providing useful code
for implementors of HTTPS payment APIs.

It depends on Net::HTTPS::Any, which in turn depends on
Net::SSLeay _or_ ( Crypt::SSLeay and LWP::UserAgent ).

=head1 METHODS

=over 4

=item https_get [ \%options ] HASHREF | FIELD => VALUE, ...

Accepts parameters as either a hashref or a list of fields and values.
In the latter case, ordering is preserved (see L<Tie::IxHash> to do so
when passing a hashref).

Returns a list consisting of the page content as a string, the HTTP
response code and message (i.e. "200 OK" or "404 Not Found"), and a list of
key/value pairs representing the HTTP response headers.

The options hashref supports setting headers:

  {
      headers => { 'X-Header1' => 'value', ... },
  }

=cut

#      Content-Type => 'text/namevalue',

sub https_get {
    my $self = shift;

    # handle optional options hashref
    my $opts = {};
    if ( scalar(@_) > 1 and ref( $_[0] ) eq "HASH" ) {
      $opts = shift;
    }

    # accept a hashref or a list (keep it ordered)
    my $post_data;
    if ( ref( $_[0] ) eq 'HASH' ) {
      $post_data = shift;
    } elsif ( scalar(@_) > 1 ) {
      tie my %hash, 'Tie::IxHash', @_;
      $post_data = \%hash;
    } elsif ( scalar(@_) == 1 ) {
      $post_data = shift;
    } else {
      die "https_get called with no params\n";
    }

    $self->build_subs(qw( response_page response_code response_headers ));

    my( $res_page, $res_code, @res_headers) = Net::HTTPS::Any::https_get( 
      'host'    => $self->server,
      'path'    => $self->path,
      'headers' => $opts->{headers},
      'args'    => $post_data,
      'debug'   => $DEBUG,
    );

    $self->response_page( $res_page );
    $self->response_code( $res_code );
    $self->response_headers( { @res_headers } );

    ( $res_page, $res_code, @res_headers );

}

=item https_post [ \%options ] SCALAR | HASHREF | FIELD => VALUE, ...

Accepts form fields and values as either a hashref or a list.  In the
latter case, ordering is preserved (see L<Tie::IxHash> to do so when
passing a hashref).

Also accepts instead a simple scalar containing the raw content.

Returns a list consisting of the page content as a string, the HTTP
response code and message (i.e. "200 OK" or "404 Not Found"), and a list of
key/value pairs representing the HTTP response headers.

The options hashref supports setting headers and Content-Type:

  {
      headers => { 'X-Header1' => 'value', ... },
      Content-Type => 'text/namevalue',
  }

=cut

sub https_post {
    my $self = shift;

    # handle optional options hashref
    my $opts = {};
    if ( scalar(@_) > 1 and ref( $_[0] ) eq "HASH" ) {
        $opts = shift;
    }

    my %post = (
      'host'         => $self->server,
      'path'         => $self->path,
      'headers'      => $opts->{headers},
      'Content-Type' => $opts->{'Content-Type'},
      'debug'        => $DEBUG,
    );

    # accept a hashref or a list (keep it ordered)
    my $post_data = '';
    my $content = undef;
    if ( ref( $_[0] ) eq 'HASH' ) {
      $post{'args'} = shift;
    } elsif ( scalar(@_) > 1 ) {
      tie my %hash, 'Tie::IxHash', @_;
      $post{'args'} = \%hash;
    } elsif ( scalar(@_) == 1 ) {
      $post{'content'} = shift;
    } else {
      die "https_post called with no params\n";
    }

    $self->build_subs(qw( response_page response_code response_headers ));

    my( $res_page, $res_code, @res_headers)= Net::HTTPS::Any::https_post(%post);

    $self->response_page( $res_page );
    $self->response_code( $res_code );
    $self->response_headers( { @res_headers } );

    ( $res_page, $res_code, @res_headers );

}

=back

=head1 SEE ALSO

L<Business::OnlinePayment>, L<Net::HTTPS::Any>

=cut

1;
