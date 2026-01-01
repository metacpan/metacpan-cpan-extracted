package App::newver::Version;
use 5.016;
use strict;
use warnings;
our $VERSION = '0.02';

use Exporter qw(import);
our @EXPORT_OK = qw(version_components version_compare);

# Algorithim adapted from libversion
# https://github.com/repology/libversion/blob/master/doc/ALGORITHM.md

use constant {
    RANK_PRE_RELEASE => 0,
    RANK_ZERO => 1,
    RANK_POST_RELEASE => 2,
    RANK_NONZERO => 3,
};

my %NORMALIZE_PRE = (
    a => 'alpha',
    b => 'beta',
);

# This set isn't actually used, any string that isn't a part of the
# %POST_RELEASE_COMPONENTS set is considered to be a pre-release component.
my %PRE_RELEASE_COMPONENTS = map { $_ => 1 } qw(
    a alpha b beta pre rc
);

# libversion allows for p to either mean patch or pre-release. We'll just
# consider p to mean patch.
my %POST_RELEASE_COMPONENTS = map { $_ => 1 } qw(
    errata patch post pl p
);

sub id_component {

    my ($comp) = @_;
    $comp = lc $comp;

    if ($comp =~ /^\d+$/) {
        if ($comp == 0) {
            return RANK_ZERO;
        } else {
            return RANK_NONZERO;
        }
    } else {
        if ($POST_RELEASE_COMPONENTS{ $comp } or $comp =~ /^post/) {
            return RANK_POST_RELEASE;
        } else {
            return RANK_PRE_RELEASE;
        }
    }

}

sub version_components {

    my ($version) = @_;

    $version =~ s/^\s+|\s+$//g;
    $version =~ s/^v//;

    my @comps = $version =~ /(\d+|[a-zA-Z]+)/g;

    return @comps;

}

sub version_compare {

    my ($v1, $v2) = @_;

    my @v1c = version_components($v1);
    my @v2c = version_components($v2);

    # Pad components with zeros.
    if (@v1c < @v2c) {
        push @v1c, (0) x (@v2c - @v1c);
    } elsif (@v2c < @v1c) {
        push @v2c, (0) x (@v1c - @v2c);
    }

    for my $i (0 .. $#v1c) {
        my $v1r = id_component($v1c[$i]);
        my $v2r = id_component($v2c[$i]);
        if ($v1r != $v2r) {
            return $v1r <=> $v2r;
        }
        if ($v1r == RANK_NONZERO or $v1r == RANK_ZERO) {
            # Treat numerical versions as strings so that we can compare very
            # long version integars that would cause overflow problems when
            # using the '<=>' operator.
            my $tr1 = $v1c[$i] =~ s/^0+//r;
            my $tr2 = $v2c[$i] =~ s/^0+//r;
            if ($tr1 ne $tr2) {
                if (length $tr1 == length $tr2) {
                    return $tr1 cmp $tr2;
                } else {
                    return length $tr1 <=> length $tr2;
                }
            }
        } elsif ($v1r == RANK_PRE_RELEASE) {
            my $p1 = lc $v1c[$i];
            my $p2 = lc $v2c[$i];
            if (exists $NORMALIZE_PRE{ $p1 }) {
                $p1 = $NORMALIZE_PRE{ $p1 };
            }
            if (exists $NORMALIZE_PRE{ $p2 }) {
                $p2 = $NORMALIZE_PRE{ $p2 };
            }
            if ($p1 ne $p2) {
                return $p1 cmp $p2;
            }
        }
    }

    return 0;

}

1;

=head1 NAME

App::newver::Version - Compare version number strings

=head1 SYNOPSIS

  use App::newver::Versoin qw(version_compare);

  my @sorted = sort { version_compare($a, $b) } qw(
    1.0
    1.1
    1.0.1
    1.0alpha1
  );

=head1 DESCRIPTION

B<App::newver::Version> is a module for comparing version strings. This is a
private module, please consult the L<newver> manual for user documentation.

B<App::newver::Version> adapts most of its logic from
L<libversion|https://github.com/repology/libversion>. This module can handle
pre-release version components (alpha, beta, rc, etc.), post-release version
components (post, patch, errata, pl, etc.), and normal numerical versions.

=head1 SUBROUTINES

Subroutines are not exported by default.

=head2 $r = version_compare($v1, $v2)

Compares two version strings and returns C<1> if C<$v1 > $v2>, C<-1> if
C<$v1 < $v2>, and C<0> if C<$v1 == $v2>.

=head2 @components = version_components($version)

Returns the list of version components from C<$version>.

=head1 AUTHOR

Written by L<Samuel Young|samyoung12788@gmail.com>

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/newver.git>. Comments and pull
requests are welcome.

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<newver>

=cut
