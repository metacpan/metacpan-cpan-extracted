package Catalyst::Model::Bitcoin;

use 5.8.0;
use strict;
use warnings;
use Moose;
use Finance::Bitcoin;
use Carp qw( croak ); 

extends 'Catalyst::Model';

our $VERSION = '0.02';

has jsonrpc_uri => (is => 'rw');
has api => (is => 'rw');
has wallet => (is => 'rw');

sub new {
  my $self = shift->next::method(@_);
  my $class = ref($self);
  my ($c, $arg_ref) = @_;

  croak "->config->{uri} must be set for $class\n"
    unless $self->{uri};

  $self->api( Finance::Bitcoin::API->new( endpoint => $self->{uri} ) );
  $self->wallet( Finance::Bitcoin::Wallet->new( $self->api ) );

  return $self;
}


sub find {
  my ($self, $address) = @_;

  my $address_object = Finance::Bitcoin::Address->new(
    $self->api,
    $address,
  );

  return $address_object;
}

sub get_received_by_address {
  my ($self, $address) = @_;

  my $address_object = $self->find($address);

  return $address_object->received();
}


sub send_to_address {
  my ($self, $address, $amount) = @_;

  # This is required to force $amount to be json-coded as real type,
  # not string, in following JSON-RPC request
  $amount += 0;
  
  return $self->wallet->pay($address, $amount);
}


sub get_new_address {
  my $self = shift;

  my $address = $self->wallet->create_address();
  return $address->address;
}


sub get_balance {
  my $self = shift;

  return $self->wallet->balance();
}


1;
__END__

=head1 NAME

Catalyst::Model::Bitcoin - Catalyst model class that interfaces 
with Bitcoin Server via JSON RPC

=head1 SYNOPSIS

Use the helper to add a Bitcoin model to your application:

   ./script/myapp_create.pl model BitcoinServer Bitcoin

After new model created, edit config:

   # ./lib/MyApp/Model/BitcoinServer.pm
   __PACKAGE__->config(
     uri => 'http://rpcuser:rpcpassword@localhost:8332',
   );

In controller:

   # Get address object (see Finance::Bitcoin::Address)
   my $address = $c->model('BitcoinServer')->find($address_string);

   # Send coins to address.
   $c->model('BitcoinServer')->send_to_address($address_string, $amount);

   # Generate new address to receive coins.
   my $new_address_string = $c->model('BitcoinServer')->get_new_address();

   # Get current wallet balance.
   my $balance = $c->model('BitcoinServer')->get_balance();

=head1 DESCRIPTION

This model class uses L<Finance::Bitcoin> to access Bitcoin Server
via JSON RPC.

=head1 SEE ALSO

L<https://github.com/hippich/Catalyst--Model--Bitcoin>, L<https://www.bitcoin.org>, L<Finance::Bitcoin>, L<Catalyst>

=head1 AUTHOR

Pavel Karoukin 
E<lt>pavel@yepcorp.comE<gt>
http://www.yepcorp.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pavel Karoukin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
