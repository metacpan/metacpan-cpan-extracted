package Astro::Montenbruck::Ephemeris::Pert;

use strict;
use warnings;
use Exporter qw/import/;
our @EXPORT_OK = qw(pert addthe);

our $VERSION = 0.01;

use constant OFFSET => 16;
use constant {
    OFFSET_M => OFFSET - 1,
    OFFSET_P => OFFSET + 1,
};

sub addthe {
    $_[0] * $_[2] - $_[1] * $_[3], $_[1] * $_[2] + $_[0] * $_[3];
}

sub pert {
    my %arg = @_;
    my ($callback, $t, $M, $m, $I_min, $I_max, $i_min, $i_max, $phi) =
        map{ $arg{$_} } qw/callback T M m I_min I_max i_min i_max phi/;
    $phi //= 0;

    my $cos_m  = cos( $M );
    my $sin_m  = sin( $M );
    my @C;
    my @S;
    my @c;
    my @s;

    $C[OFFSET] = cos($phi);
    $S[OFFSET] = sin($phi);

    for ( my $i = 0; $i < $I_max; $i++ ) {
        my $j  = OFFSET + $i;
        my $k = $j + 1;
        ( $C[$k], $S[$k] ) = addthe( $C[$j], $S[$j], $cos_m, $sin_m );
    }
    for ( my $i = 0; $i > $I_min; $i-- ) {
        my $j  = OFFSET + $i;
        my $k = $j - 1;
        ( $C[$k], $S[$k] ) = addthe( $C[$j], $S[$j], $cos_m, -$sin_m );
    }
    $c[OFFSET]   = 1.0;
    $c[OFFSET_P] = cos( $m );
    $c[OFFSET_M] = $c[OFFSET_P];
    $s[OFFSET]   = 0.0;
    $s[OFFSET_P] = sin( $m );
    $s[OFFSET_M] = -$s[OFFSET_P];
    for ( my $i = 1; $i < $i_max; $i++ ) {
        my $j  = OFFSET + $i;
        my $k = $j + 1;
        ( $c[$k], $s[$k] ) = addthe( $c[$j], $s[$j], $c[OFFSET_P], $s[OFFSET_P] );
    }
    for ( my $i = -1; $i > $i_min; $i-- ) {
        my $j  = OFFSET + $i;
        my $k = $j - 1;
        ( $c[$k], $s[$k] ) = addthe( $c[$j], $s[$j], $c[OFFSET_M], $s[OFFSET_M] );
    }

    my ($u, $v) = (0, 0);

    sub {
        my ( $I, $i, $iT, $dlc, $dls, $drc, $drs, $dbc, $dbs ) = @_;
        my $k = OFFSET + $I;
        my $j = OFFSET + $i;
        if ( $iT == 0 ) {
            ( $u, $v ) = addthe( $C[$k], $S[$k], $c[$j], $s[$j] );
        }
        else {
            $u *= $t;
            $v *= $t;
        }
        $callback->(
            $dlc * $u + $dls * $v,
            $drc * $u + $drs * $v,
            $dbc * $u + $dbs * $v
        );
      }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Pert - Calculation of perturbations.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Pert qw /pert/;

  ($dl, $dr, $db) = (0, 0, 0); # Corrections in longitude ["],
  $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

  $term
    = pert( T     => $t,
            M     => $m1,
            m     => $m3,
            I_min => 0,
            I_max => 2,
            i_min =>-4,
            i_max =>-1,
            callback => $pert_cb);
 $term->(-1, -1,0, -0.2, 1.4, 2.0,  0.6,  0.1, -0.2);
 $term->( 0, -1,0,  9.4, 8.9, 3.9, -8.3, -0.4, -1.4);
 ...

=head1 DESCRIPTION

Calculates perturbations for Sun, Moon and the 8 planets. Used internally by
L<Astro::Montenbruck::Ephemeris> module.

=head2 EXPORT

=over

=item * L<pert(%args)>

=item * L<addthe($a, $b, $c, $d)>

=back

=head1 SUBROUTINES/METHODS

=head2 pert(%args)

Calculates perturbations to ecliptic heliocentric coordinates of the planet.

=head3 Named arguments

=over

=item * B<T> — time in centuries since epoch 2000.0

=item *

B<M>, B<m>, B<I_min>, B<I_max>, B<i_min>, B<i_max> — internal indices

=item *

B<callback> — reference to a function which recievs corrections to the 3
coordinates and typically applies them (see L</SYNOPSIS>)

=back

=head2 addthe($a, $b, $c, $d)

Calculates C<c=cos(a1+a2)> and C<s=sin(a1+a2)> from the addition theorems for
C<c1=cos(a1), s1=sin(a1), c2=cos(a2) and s2=sin(a2)>

=head3 Arguments

c1, s1, c2, s2


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
