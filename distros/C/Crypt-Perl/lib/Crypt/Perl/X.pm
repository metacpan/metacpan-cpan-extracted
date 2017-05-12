package Crypt::Perl::X;

=encoding utf-8

=head1 NAME

Crypt::Perl::X - Exception objects for Crypt::Perl

=cut

use strict;
use warnings;

use Module::Load ();

sub create {
    my ( $type, @args ) = @_;

    my $x_package = "Crypt::Perl::X::$type";

    Module::Load::load($x_package);

    return $x_package->new(@args);
}

1;
