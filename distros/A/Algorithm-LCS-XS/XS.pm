package Algorithm::LCS::XS;

use 5.008;
use strict;
use warnings;
use version;
our $VERSION = "1.08";

require XSLoader;
XSLoader::load('Algorithm::LCS::XS', $VERSION);

##############################
# code adapted from Algorithm::Diff

sub line_map {
    my $ctx = shift;
    my %lines;
    push @{ $lines{$_[$_]} }, $_ for 0..$#_; # values MUST be SvIOK
    \%lines;
}

sub callback {
    my ($ctx, @b) = @_;
    my $h = $ctx->line_map(@b);
    sub { @_ ? _core_loop($ctx, $_[0], 0, $#{$_[0]}, $h) : @b }
}

sub LCS {
    my ($ctx, $a, $b) = @_;
    my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

    while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
        $amin++;
        $bmin++;
    }
    while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
        $amax--;
        $bmax--;
    }

    my $h = $ctx->line_map(@$b[$bmin..$bmax]); # line numbers are off by $bmin

    return $amin + _core_loop($ctx, $a, $amin, $amax, $h) + ($#$a - $amax)
        unless wantarray;

    my @lcs = _core_loop($ctx,$a,$amin,$amax,$h);
    if ($bmin > 0) {
        $_->[1] += $bmin for @lcs; # correct line numbers
    }

    map([$_ => $_], 0 .. ($amin-1)),
        @lcs,
            map([$_ => ++$bmax], ($amax+1) .. $#$a);
}

1;

__END__

=head1 NAME

Algorithm::LCS::XS - Fast (XS) implementation of the
                 Longest Common Subsequence (LCS) Algorithm

=head1 SYNOPSIS

  use Algorithm::LCS::XS;

  $alg = Algorithm::LCS::XS->new;
  @lcs = $alg->LCS(\@a,\@b);

  $cb = $alg->callback(@b); # closure
  @lcs = $cb->(\@a);        # same result as prior LCS() call

=head1 ABSTRACT

Algorithm::LCS::XS reimplements Algorithm::Diff's core loop in XS,
and provides a simple OO interface to it.

Extract from the Algorithm::Diff v1.15 manpage:

  The algorithm is that described in
  I<A Fast Algorithm for Computing Longest Common Subsequences>,
  CACM, vol.20, no.5, pp.350-353, May 1977, with a few
  minor improvements to improve the speed.


=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4

=item line_map(@lines)

Send @lines to a hashref containing elements of the form

       value => [(increasing) list of matching indices]

=item callback(@lines)

Generates a closure capturing the object and line_map hash for @lines.
Most useful when computing multiple LCSs against a single file.

=item LCS(\@a,\@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments.  In scalar context the return value is the length of the
subsequence.  In list context it yields a list of corresponding
indices, which are represented by 2-element array refs.  See the
L<Algorithm::Diff> manpage for more details.

=back

=head2 EXPORT

None by design.

=head1 SEE ALSO

Algorithm::Diff

=head1 AUTHOR

Joe Schaefer, E<lt>joe+cpan@sunstarsys.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joe Schaefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
