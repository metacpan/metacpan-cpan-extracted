{ package Catalyst::Action::SOAP::RPCLiteral;

  use base 'Catalyst::Action::SOAP';
  use MRO::Compat;
  use mro 'c3';

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;
      $self->next::method($controller, $c, $c->stash->{soap}->arguments);
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::RPCLiteral - RPC style Literal encoding service

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This class implements the literal encoding dispatch on the service,
which means that the arguments are passed to the service as a xml
object in the parameters.

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

