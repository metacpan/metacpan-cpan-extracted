=head1 NAME

Bio::Util::AA - Basic Amino Acid utilities

=head1 SYNOPSES

 use Bio::Util::AA qw(:all)

=head1 DESCRIPTION

Provides a set of functions and predefined variables which
are handy when working with Amino Acids.

=cut

package Bio::Util::AA;

use strict;
use warnings;

use version; our $VERSION = qv('0.1.6');

use Exporter 'import';

our @EXPORT_OK = qw(
  %ambiguous_forward
  %ambiguous_map
  %aa_abbrev

  $aas
  $aa_match
  $aa_fail
  $strict_aas
  $strict_match
  $strict_fail
  $ambigs
  $ambig_match
  $ambig_fail
);

our %EXPORT_TAGS = (
    all   => \@EXPORT_OK,
    funcs => [qw()]
);

=head1 VARIABLES

=cut

=head2 AMBIGUOUS MAPPINGS

Two ambiguous mapping hashes. One maps from the amino acid
forward to the possible ambiguous amino acid, and one is a
map of what each ambiguous amino acid means.

=cut

our %ambiguous_forward = (
    A => 'B',
    B => 'B',
    D => 'B',
    I => 'J',
    J => 'J',
    L => 'J',
    E => 'Z',
    Q => 'Z',
    Z => 'Z'
);

our %ambiguous_map = (
    B => [ 'A', 'D' ],
    J => [ 'I', 'L' ],
    Z => [ 'E', 'Q' ]
);

=head2 %aa_abbrev

Hash from one letter code for amino acids to the three
letter abbreviations. Includes ambiguous amino acids as well
as selenocysteine and pyrrolysine.

=cut

our %aa_abbrev = (
    A => 'Ala',
    B => 'Asx',
    C => 'Cys',
    D => 'Asp',
    E => 'Glu',
    F => 'Phe',
    G => 'Gly',
    H => 'His',
    I => 'Ile',
    J => 'Xle',
    K => 'Lys',
    L => 'Leu',
    M => 'Met',
    N => 'Asn',
    O => 'Pyl',
    P => 'Pro',
    Q => 'Gln',
    R => 'Arg',
    S => 'Ser',
    T => 'Thr',
    U => 'Sec',
    V => 'Val',
    W => 'Trp',
    X => 'Xaa',
    Y => 'Tyr',
    Z => 'Glx'
);

=head2 BASIC VARIABLES

Basic useful amino acid variables. A list of valid
characters for amino acids, a stricter list containing just
the 20 common ones and *, and another list containing the
ambiguous amino acids. Also associated precompiled
regular expressions.

=cut

our $aas     = '*ABCDEFGHIJKLMNOPQRSTUVWXYZ';
our $aa_match = qr/[$aas]/i;
our $aa_fail  = qr/[^$aas]/i;

our $strict_aas   = '*ACDEFGHIKLMNPQRSTVWXY';
our $strict_match = qr/[$strict_aas]/i;
our $strict_fail  = qr/[^$strict_aas]/i;

our $ambigs     = 'BJZ';
our $ambig_match = qr/[$ambigs]/i;
our $ambig_fail  = qr/[^$ambigs]/i;

1;

=head1 AUTHOR

Kevin Galinsky, <first initial last name plus cpan at gmail dot com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011, Broad Institute.

Copyright (c) 2008-2009, J. Craig Venter Institute.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
