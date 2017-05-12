use strict;
use warnings;
package AnyEvent::OWNet::Response;
$AnyEvent::OWNet::Response::VERSION = '1.163170';
# ABSTRACT: Module for responses from 1-wire File System server


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub is_success {
  shift->{ret} == 0
}


sub return_code {
  shift->{ret}
}


sub version {
  shift->{version}
}


sub flags {
  shift->{sg}
}


sub payload_length {
  shift->{payload}
}


sub size {
  shift->{size}
}


sub offset {
  shift->{offset}
}


sub data_list {
  my $self = shift;
  unless (ref $self->{data}) {
    $self->{data} = [ split /,/, substr $self->{data}, 0, -1 ];
  }
  @{$self->{data}}
}


sub data {
  shift->{data}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::OWNet::Response - Module for responses from 1-wire File System server

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # normally instantiated by AnyEvent::OWNet command methods

=head1 DESCRIPTION

Module to represent responses from owfs 1-wire server daemon.

=head1 METHODS

=head2 C<new()>

Constructs a new L<AnyEvent::OWNet::Response> object.  It is called by
L<AnyEvent::OWNet> in response to messages received from the
C<owserver> daemon.

=head2 C<is_success()>

Returns true if the response object represents a successful request.

=head2 C<return_code()>

Returns the return code of the response from the C<owserver> daemon.

=head2 C<version()>

Returns the protocol version number of the response from the
C<owserver> daemon.

=head2 C<flags()>

Returns the flags field of the response from the C<owserver> daemon.
The L<AnyEvent::OWNet::Constants::ownet_temperature_units()|AnyEvent::OWNet::Constants/"ownet_temperature_units( $flags )">,
L<AnyEvent::OWNet::Constants::ownet_pressure_units()|AnyEvent::OWNet::Constants/"ownet_pressure_units( $flags )">,
and
L<AnyEvent::OWNet::Constants::ownet_display_format()|AnyEvent::OWNet::Constants/"ownet_display_format( $flags )">
functions can be used to extract some elements from this value.

=head2 C<payload_length()>

Returns the payload length field of the response from the C<owserver>
daemon.

=head2 C<size()>

Returns the size of the data element of the response from the
C<owserver> daemon.

=head2 C<offset()>

Returns the offset field of the response from the C<owserver> daemon.

=head2 C<data_list()>

Returns the data from the response as a list.  This is a intend for use
when the response corresponds to a directory listing request.

=head2 C<data()>

Returns the data from the response as a scalar.  This is a intend for
use when the response corresponds to a file C<read>.  However, it
returns the raw data for any request so while for a C<read> it may be
a simple scalar value, it may also be a comma separated list (e.g. for
a C<dirall> request) or an array reference (e.g. for a C<dir> request).

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
