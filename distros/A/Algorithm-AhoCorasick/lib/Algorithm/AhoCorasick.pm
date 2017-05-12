package Algorithm::AhoCorasick;

use warnings;
use strict;

use Algorithm::AhoCorasick::SearchMachine;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
				   find_first
				   find_all
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.03';

sub find_first {
    my $text = shift;

    my $m = Algorithm::AhoCorasick::SearchMachine->new(@_);
    my $rv = $m->feed($text, sub { [ @_ ]; });
    if (wantarray) {
	return $rv ? @$rv : ();
    } else {
	return $rv ? $rv : undef;
    }
}

sub find_all {
    my $text = shift;

    my $m = Algorithm::AhoCorasick::SearchMachine->new(@_);

    my %total;
    my $handle_all = sub {
	my ($pos, $keyword) = @_;

	if (!exists($total{$pos})) {
	    $total{$pos} = [ ];
	}

	push @{$total{$pos}}, $keyword;

	undef;
    };

    $m->feed($text, $handle_all);

    return keys(%total) ? \%total : undef;
}

1;

__END__

=head1 NAME

Algorithm::AhoCorasick - efficient search for multiple strings

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 use Algorithm::AhoCorasick qw(find_all);

 $found = find_all($text, @keywords);
 if (!$found) {
     print "no keywords found\n";
 } else {
     foreach $pos (sort keys %$found) {
         $keywords = join ', ', @{$found->{$pos}};
         print "$pos: $keywords\n";
     }
 }

=head1 DESCRIPTION

Aho-Corasick is a classic (1975) algorithm for locating elements of a
finite set of strings within an input text. It constructs a finite
state machine from a list of keywords, then uses the machine to locate
all occurrences of the keywords. Construction of the machine takes
time proportional to the sum of the lengths of the keywords and the
machine processes the input string in a single pass - that is, the
algorithm may be considerably more efficient than searching for each
keyword separately.

=head1 PROCEDURAL INTERFACE

The module exports 2 functions for the common use cases: C<find_all>
for finding all matches, and C<find_first> for finding whether a match
exists at all. Note that both functions must be explicitly imported
(i.e. with C<use Algorithm::AhoCorasick qw(find_all find_first);>)
before they can be called. Both functions take the same arguments: the
first argument is the text to be searched, the following are the
keywords to search for (there must be at least one, and the functions
die rather than search for empty strings).

=head2 find_all

When no keyword is found in the input text, C<find_all> returns
undef; when some keywords are found, the return value is a hash
reference mapping positions to keywords (in an array reference,
ordered by length) found at those positions.

=head2 find_first

When no keyword is found in the input text, C<find_first> returns
undef in scalar context and an empty array in list context; when a
keyword is found, the return value is a pair of its position in the
input text and the found keyword (as a list if the function has been
called in list context, as an array reference otherwise).

=head1 OBJECT-ORIENTED INTERFACE

C<find_all> and C<find_first> are just thin wrappers around the state
machine class Algorithm::AhoCorasick::SearchMachine, which can also be
used directly for a more customizable search scenarios (i.e. when the
input text isn't available all at once) - see the
Algorithm::AhoCorasick::SearchMachine POD for details.

=head1 AUTHOR

Vaclav Barta, C<< <vbar@comp.cz> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-ahocorasick at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-AhoCorasick>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Vaclav Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Adapted from implementation by Tomas Petricek, available at
L<http://www.codeproject.com/cs/algorithms/ahocorasick.asp> .

The algorithm is from Alfred V. Aho and Margaret J. Corasick,
Efficient string matching: an aid to bibliographic search, CACM,
18(6):333-340, June 1975.

=cut

