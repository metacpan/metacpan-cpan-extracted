package App::Math::Tutor::Role::Power;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Power - role for power mathematics

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;
use Module::Runtime qw/use_module/;

with "App::Math::Tutor::Role::VulFrac";    # for _check_vulgar_fraction

our $VERSION = '0.005';

sub _check_power_to { $_[0]->basis != 0 and $_[0]->basis != 1 and $_[0]->exponent != 0; }

has power_types => (
    is => "lazy",
);

requires "format";

sub _build_power_types
{
    [
        {
            name    => "power",
            numbers => 1,
            builder => sub { int( rand( $_[1] ) + 1 ); },
        },
        {
            name    => "sqrt",
            numbers => 1,
            builder => sub {
                VulFrac->new(
                    num   => 1,
                    denum => int( rand( $_[1] ) + 1 )
                );
            },
        },
        {
            name    => "power+sqrt",
            numbers => 2,
            builder => sub {
                my $vf;
                do
                {
                    $vf = VulFrac->new(
                        num   => int( rand( $_[1] ) + 1 ),
                        denum => int( rand( $_[1] ) + 1 )
                    );
                } while ( !$_[0]->_check_vulgar_fraction($vf) );
                $vf;
            },
        },
    ];
}

sub _guess_power_to
{
    my ( $max_basis, $max_exponent ) = @{ $_[0]->format };
    my @types = @{ $_[0]->power_types };
    my $type  = int( rand( scalar @types ) );
    my ( $basis, $exponent ) =
      ( int( rand($max_basis) ), $types[$type]->{builder}->( $_[0], $max_exponent ) );
    Power->new(
        basis    => $basis,
        exponent => $exponent,
        mode     => int( rand(2) )
    );
}

=head1 METHODS

=head2 get_power_to

Returns as many powers as requested. Does Factory :)

=cut

sub get_power_to
{
    my ( $self, $amount ) = @_;
    my @result;

    while ( $amount-- )
    {
        my $pt;
        do
        {
            $pt = $self->_guess_power_to;
        } while ( !_check_power_to($pt) );

        push @result, $pt;
    }

    @result;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
