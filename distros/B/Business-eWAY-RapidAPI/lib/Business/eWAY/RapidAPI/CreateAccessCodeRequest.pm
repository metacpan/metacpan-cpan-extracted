package Business::eWAY::RapidAPI::CreateAccessCodeRequest;
$Business::eWAY::RapidAPI::CreateAccessCodeRequest::VERSION = '0.11';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Business::eWAY::RapidAPI::Customer;
use Business::eWAY::RapidAPI::Items;
use Business::eWAY::RapidAPI::Options;
use Business::eWAY::RapidAPI::Payment;
use Business::eWAY::RapidAPI::ShippingAddress;

has $_ => ( is => 'rw', isa => Str )
  foreach ( 'RedirectUrl', 'IPAddress', 'DeviceID', 'Method' );

has 'Customer' =>
  ( is => 'lazy', isa => InstanceOf ['Business::eWAY::RapidAPI::Customer'] );
sub _build_Customer { Business::eWAY::RapidAPI::Customer->new }
has 'Items' =>
  ( is => 'lazy', isa => InstanceOf ['Business::eWAY::RapidAPI::Items'] );
sub _build_Items { Business::eWAY::RapidAPI::Items->new }
has 'Options' =>
  ( is => 'lazy', isa => InstanceOf ['Business::eWAY::RapidAPI::Options'] );
sub _build_Options { Business::eWAY::RapidAPI::Options->new }
has 'Payment' =>
  ( is => 'lazy', isa => InstanceOf ['Business::eWAY::RapidAPI::Payment'] );
sub _build_Payment { Business::eWAY::RapidAPI::Payment->new }
has 'ShippingAddress' => (
    is  => 'lazy',
    isa => InstanceOf ['Business::eWAY::RapidAPI::ShippingAddress']
);
sub _build_ShippingAddress { Business::eWAY::RapidAPI::ShippingAddress->new }

sub TO_JSON { return { %{ $_[0] } }; }

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::eWAY::RapidAPI::CreateAccessCodeRequest

=head1 VERSION

version 0.11

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
