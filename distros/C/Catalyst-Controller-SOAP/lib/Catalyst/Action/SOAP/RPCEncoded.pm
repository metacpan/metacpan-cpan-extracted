{ package Catalyst::Action::SOAP::RPCEncoded;

  use base 'Catalyst::Action::SOAP';

  __PACKAGE__->mk_accessors('operations');

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;

      

  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::RPCEncoded - RPC Encoded service

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This class implements the soap encoding dispatch on the service, which
means that the arguments are passed to the service as an list of the
parsed arguments.

=head1 TODO

Almost all the SOAP protocol is unsupported, only the method
dispatching and, optionally, the soap-decoding of the arguments are
made.

=head1 AUTHORS

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

