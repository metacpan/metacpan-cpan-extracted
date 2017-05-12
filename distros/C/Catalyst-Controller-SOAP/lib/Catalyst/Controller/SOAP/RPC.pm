{ package Catalyst::Controller::SOAP::RPC;
  use strict;
  use base 'Catalyst::Controller::SOAP';
  sub rpc_endpoint :Path('') :ActionClass('SOAP::RPCEndpoint') {};
};

1;

__END__

=head1 NAME

Catalyst::Controller::SOAP::RPC - Helper controller for SOAP

=head1 SYNOPSIS

 use base 'Catalyst::Controller::SOAP::RPC';

=head1 DESCRIPTION

This is a direct subclass of Catalyst::Controller::SOAP that
predefines a rpc_endpoint method which is dispatched in the URI of the
controller as the RPC endpoint. It's simply inteded to save you the
job of defining that in each SOAP RPC controller you implement,
considering that is the standard behaviour.

=head1 TODO

Well, here? nothing, all the work is done in the superclass.

=head1 AUTHOR

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

