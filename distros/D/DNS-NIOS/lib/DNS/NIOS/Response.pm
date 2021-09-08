#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package DNS::NIOS::Response;
$DNS::NIOS::Response::VERSION = '0.005';

# ABSTRACT: WAPI Response object
# VERSION
# AUTHORITY

## use critic
use strictures 2;
use Carp qw(croak);
use JSON qw(from_json to_json);
use Try::Tiny;
use namespace::clean;
use Class::Tiny qw( _http_response );

sub BUILD {
  my $self = shift;
  croak "Missing required attribute" unless defined $self->_http_response;
  croak "Bad attribute" unless ref $self->_http_response eq "HTTP::Response";
}

sub code {
  return shift->_http_response->{_rc};
}

sub is_success {
  return shift->_http_response->is_success;
}

sub content {
  my $self = shift;
  my $h;
  try {
    $h = from_json( $self->_http_response->decoded_content );

  }
  catch {
    $h = $self->_http_response->decoded_content;

    # For some reason <5.28 returns a quoted string during test
    $h =~ s/^"|"$//g;
  };
  return $h;
}

sub json {
  my $self = shift;
  try {
    my $h = to_json( $self->content, @_ );
    return $h;
  };
  return to_json( { content => $self->content }, @_ );
}

sub pretty {
  return shift->json( { utf8 => 1, pretty => 1 } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::NIOS::Response - WAPI Response object

=head1 VERSION

version 0.005

=head1 METHODS

=head2 code

Response code

=head2 is_success

Wether the request was successful

=head2 content

Response content as hashref. If the content for some reason cannot be converted,
it will return the decoded_content as is.

=head2 json

Return a json string.

=head2 pretty

Return a prettified json string.

=for Pod::Coverage BUILD

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
