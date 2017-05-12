# Algorithm::Diff::Any
#  An interface that automagically selects the XS or Pure Perl port of
#  the diff algorithm (Algorithm::Diff or Algorithm::Diff::XS)
#
# $Id: Any.pm 10595 2009-12-23 00:29:52Z FREQUENCY@cpan.org $

package Algorithm::Diff::Any;

use strict;
use warnings;
use Carp ();

use Exporter 'import';
our @EXPORT_OK = qw(
  prepare
  LCS
  LCSidx
  LCS_length
  diff
  sdiff
  compact_diff
  traverse_sequences
  traverse_balanced
);

=head1 NAME

Algorithm::Diff::Any - Perl module to find differences between files

=head1 VERSION

Version 1.001 ($Id: Any.pm 10595 2009-12-23 00:29:52Z FREQUENCY@cpan.org $)

=cut

our $VERSION = '1.001';
$VERSION = eval $VERSION;

our $DRIVER = 'PP';

# Try to load the XS version first
eval {
  require Algorithm::Diff::XS;
  $DRIVER = 'XS';

  # Import external subroutines here
  no strict 'refs';
  for my $func (@EXPORT_OK) {
    *{$func} = \&{'Algorithm::Diff::XS::' . $func};
  }
};

# Fall back on the Perl version
if ($@) {
  require Algorithm::Diff;

  # Import external subroutines here
  no strict 'refs';
  for my $func (@EXPORT_OK) {
    *{$func} = \&{'Algorithm::Diff::' . $func};
  }
}

=head1 DESCRIPTION

This is a simple module to select the best available implementation of the
standard C<diff> algorithm, which works by effectively trying to solve the
Longest Common Subsequence (LCS) problem. This algorithm is described in:
I<A Fast Algorithm for Computing Longest Common Subsequences>, CACM, vol.20,
no.5, pp.350-353, May 1977.

However, it is algorithmically rather complicated to solve the LCS problem;
for arbitrary sequences, it is an NP-hard problem. Simply comparing two
strings together of lengths I<n> and I<m> is B<O(n x m)>. Consequently, this
means the algorithm necessarily has some tight loops, which, for a dynamic
language like Perl, can be slow.

In order to speed up processing, a fast (C/XS-based) implementation of the
algorithm's core loop was implemented. It can confer a noticable performance
advantage (benchmarks show a 54x speedup for the C<compact_diff> routine).

=head1 SYNOPSIS

  use Algorithm::Diff::Any;

  my $diff = Algorithm::Diff::Any->new(\@seq1, \@seq2);

For complete usage details, see the Object-Oriented interface description
for the L<Algorithm::Diff> module.

=head1 PURPOSE

The intent of this module is to provide single simple interface to the two
(presumably) compatible implementations of this module, namely,
L<Algorithm::Diff> and L<Algorithm::Diff::XS>.

If, for some reason, you need to determine what version of the module is
actually being included by C<Algorithm::Diff::Any>, then:

  print 'Backend type: ', $Algorithm::Diff::Any::DRIVER, "\n";

In order to force use of one or the other, simply load the appropriate module:

  use Algorithm::Diff::XS;
  my $diff = Algorithm::Diff::XS->new();
  # or
  use Algorithm::Diff;
  my $diff = Algorithm::Diff->new();

=head1 COMPATIBILITY

This module was tested under Perl 5.10.1, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 EXPORTABLE FUNCTIONS

The following functions are available for import into your namespace:

=over

=item * prepare

=item * LCS

=item * LCSidx

=item * LCS_length

=item * diff

=item * sdiff

=item * compact_diff

=item * traverse_sequences

=item * traverse_balanced

=back

For full documentation, see the relevant functional descriptions in the Pure
Perl implementation, L<Algorithm::Diff>.

=cut

=head1 METHODS

=head2 new

  Algorithm::Diff::Any->new( \@seq1, \@seq2, \%opts );

Creates a C<Algorithm::Diff::Any> object, based upon either the optimized
C/XS version of the algorithm, L<Algorithm::Diff::XS>, or falls back to
the Pure Perl implementation, L<Algorithm::Diff>.

Example code:

  my $diff = Algorithm::Diff::Any->new( \@seq1, \@seq2 );
  # or with options
  my $diff = Algorithm::Diff::Any->new( \@seq1, \@seq2, \%opts );

This method will return an appropriate B<Algorithm::Diff::Any> object or
throw an exception on error.

=cut

# Wrappers around the actual methods
sub new {
  my ($class, $seq1, $seq2, $opts) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  Carp::croak('You must provide two sequences to compare as array refs')
    unless (ref($seq1) eq 'ARRAY' && ref($seq2) eq 'ARRAY');

  my $self = {
  };

  if ($DRIVER eq 'XS') {
    $self->{backend} = Algorithm::Diff::XS->new($seq1, $seq2, $opts);
  }
  else {
    $self->{backend} = Algorithm::Diff->new($seq1, $seq2, $opts);
  }

  bless($self, $class);
  return $self;
}

=head2 Next

  $diff->Next( $count )

See L<Algorithm::Diff> for method documentation.

=cut

sub Next {
  shift->{backend}->Next(@_);
}

=head2 Prev

  $diff->Prev( $count )

See L<Algorithm::Diff> for method documentation.

=cut

sub Prev {
  shift->{backend}->Prev(@_);
}

=head2 Reset

  $diff->Reset( $pos )

See L<Algorithm::Diff> for method documentation.

=cut

sub Reset {
  my $self = shift;
  $self->{backend}->Reset(@_);
  return $self;
}

=head2 Copy

  $diff->Copy( $pos, $newBase )

See L<Algorithm::Diff> for method documentation.

=cut

sub Copy {
  shift->{backend}->Copy(@_);
}

=head2 Base

  $diff->Base( $newBase )

See L<Algorithm::Diff> for method documentation.

=cut

sub Base {
  shift->{backend}->Base(@_);
}

=head2 Diff

  $diff->Diff( )

See L<Algorithm::Diff> for method documentation.

=cut

sub Diff {
  shift->{backend}->Diff(@_);
}

=head2 Same

See L<Algorithm::Diff> for method documentation.

Code example:

  $diff->Same( )

=cut

sub Same {
  shift->{backend}->Same(@_);
}

=head2 Items

  $diff->Items( $seqNum )

See L<Algorithm::Diff> for method documentation.

=cut

sub Items {
  shift->{backend}->Items(@_);
}

=head2 Range

  $diff->Range( $seqNum, $base )

See L<Algorithm::Diff> for method documentation.

=cut

sub Range {
  shift->{backend}->Range(@_);
}

=head2 Min

  $diff->Min( $seqNum, $base )

See L<Algorithm::Diff> for method documentation.

=cut

sub Min {
  shift->{backend}->Min(@_);
}

=head2 Max

  $diff->Max( $seqNum, $base )

See L<Algorithm::Diff> for method documentation.

=cut

sub Max {
  shift->{backend}->Max(@_);
}

=head2 Get

  $diff->Get( @names )

See L<Algorithm::Diff> for method documentation.

=cut

sub Get {
  shift->{backend}->Get(@_);
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Many thanks go to the primary authors and maintainers of the Pure Perl
implementation of this algorithm, notably:

=over

=item * Mark-Jason Dominus <mjd-perl-diff@plover.com>

=item * Ned Konz <perl@bike-nomad.com>

=item * Tye McQueen <tyemq@cpan.org>

=back

=item *

Thanks to Audrey Tang <cpan@audreyt.org>, author of L<Algorithm::Diff::XS>,
for recognizing the value of Joe Schaefer's <apreq-dev@httpd.apache.org>
work on L<Algorithm::LCS>

=item *

Neither the Pure Perl nor C/XS-based implementations of this module would
have been possible without the work of James W. Hunt (Stanford University)
and Thomas G. Szymanski (Princeton University), authors of the often-cited
paper for computing longest common subsequences.

In their abstract, they claim that a running time of B<O(n log n)> can be
expected, with a worst-case time of B<O(n^2 log n)> for two subsequences of
length I<n>.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Diff::Any

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-Diff-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-Diff-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-Diff-Any>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Diff-Any>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/Algorithm-Diff-Any>

=item * CPAN Testers Platform Compatibility Matrix

L<http://www.cpantesters.org/show/Algorithm-Diff-Any.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/Algorithm-Diff-Any>

If you are a CPAN developer and would like to make modifications to the code
base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the repository
administrator. I only ask that you contact me first to discuss the changes you
wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your bug
report in the form of failing unit tests, you are B<strongly> encouraged to do
so.

=head1 SEE ALSO

L<Algorithm::Diff>, the classic reference implementation for finding the
differences between two chunks of text in Perl. It is based on the algorithm
described in I<A Fast Algorithm for Computing Longest Common Subsequences>,
CACM, vol.20, no.5, pp.350-353, May 1977.

L<Algorithm::Diff::XS>, the C/XS optimized version of Algorithm::Diff, which
will be used automatically if available.

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

It is not currently known whether L<Algorithm::Diff> (Pure Perl version)
and L<Algorithm::Diff::XS> (C/XS implementation) produce the same output.
The algorithms may not be equivalent (source code-wise) so they may produce
different output under some as-yet-undiscovered conditions.

=item *

Any potential performance gains will be limited by those features implemented
by L<Algorithm::Diff::XS>. As of time of writing, this is limited to the
C<cdiff> subroutine.

=back

=head1 QUALITY ASSURANCE METRICS

=head2 TEST COVERAGE

  -------------------------- ------ ------ ------ ------ ------ ------
  File                        stmt   bran   cond   sub    pod   total
  -------------------------- ------ ------ ------ ------ ------ ------
  lib/Algorithm/Diff/Any.pm  100.0  100.0  100.0  100.0  100.0  100.0
  Total                      100.0  100.0  100.0  100.0  100.0  100.0

=head1 LICENSE

Copyright (C) 2009 by Jonathan Yu <jawnsy@cpan.org>

This package is distributed under the same terms as Perl itself. Please
see the F<LICENSE> file included in this distribution for full details of
these terms.

=head1 DISCLAIMER OF WARRANTY

This software is provided by the copyright holders and contributors
"AS IS" and ANY EXPRESS OR IMPLIED WARRANTIES, including, but not
limited to, the IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.

In no event shall the copyright owner or contributors be liable for
any direct, indirect, incidental, special, exemplary or consequential
damages (including, but not limited to, procurement of substitute
goods or services; loss of use, data or profits; or business
interruption) however caused and on any theory of liability, whether
in contract, strict liability or tort (including negligence or
otherwise) arising in any way out of the use of this software, even if
advised of the possibility of such damage.

=cut

1;
