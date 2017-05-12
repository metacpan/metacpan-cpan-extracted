package Business::eWAY::RapidAPI::Items;
$Business::eWAY::RapidAPI::Items::VERSION = '0.11';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has 'LineItem' => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Business::eWAY::RapidAPI::LineItem'] ],
    default => sub { [] }
);

sub TO_JSON { return { %{ $_[0] } }; }

no Moo;

package    # hidden from PAUSE
  Business::eWAY::RapidAPI::LineItem;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has $_ => ( is => 'rw', isa => Str )
  foreach ( 'SKU', 'Description', 'Quantity', 'UnitCost', 'Tax', 'Total' );

sub TO_JSON { return { %{ $_[0] } }; }

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::eWAY::RapidAPI::Items

=head1 VERSION

version 0.11

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
