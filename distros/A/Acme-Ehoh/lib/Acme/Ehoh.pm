package Acme::Ehoh;
use 5;
use strict;
use warnings;

our $VERSION = "0.01";

my @dir = (255, 165, 345, 165, 75);

sub direction {
    my $arg = shift;

    $arg =~ /^(-?\d+)$/;

    my $year = $1;

    if(!defined $year || $year <= 0){
	return undef;
    }

    return $dir[$year % 5];
}

1;
__END__

=head1 NAME

Acme::Ehoh - Calclate ehoh

=head1 SYNOPSIS

    use Acme::Ehoh;
    print Acme::Ehoh::direction(2014);

=head1 DESCRIPTION

Acme::Ehoh caluclate ehoh (lucky direction on Onmyodo).

=head1 FUNCTION

=over

=item direction($year)

Return ehoh direction of specified year (value 0 means north, 90 means east,
and so on).

On error, return undef.

=back

=head1 LICENSE

Copyright (C) SHIRAKATA Kentaro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

SHIRAKATA Kentaro E<lt>argrath@ub32.orgE<gt>

=cut

