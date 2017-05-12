package Biblio::LCC;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.09';

# Normalize a class (e.g., "PN1997.5") or an actual call number
# (e.g., "PN1997.5 .B3 B5 1977")
sub normalize {
    my ($cls, $lcc) = @_;
    my ($alpha, $int, $frac, $rmdr) = $cls->parse($lcc);
    my $norm;
    if ($frac eq '') {
        if ($int eq '') {
            $norm = sprintf "%-3s", $alpha;
        }
        else {
            $norm = sprintf "%-3s%4d %s", $alpha, $int, $rmdr;
        }
    }
    else {
        $norm = sprintf "%-3s%4d.%d %s", $alpha, $int, $frac, $rmdr;
    }
    $norm =~ s/ +$//;
    return $norm;
}

# Normalize a classification range
# NOTE: A range can be specified using a hyphen (e.g., 'Z105-106'), which
#       is the usual way, or a less-than sign (e.g., 'Z105<107'), which
#       lets you do specify that a call number must be strictly less than
#       the end of the range.  If you just specify one classification (e.g.,
#       "AS137"), the second classification is the same as the first and a
#       hyphen is assumed.
sub normalize_range {
    my ($cls, $str) = @_;
    my ($begin, $end, $rel);
    $str =~ s/ +A\s*-\s*Z$//;  # Strip " A-Z" at end -- common (but meaningless) idiom
    $str =~ s/(.+)\.([^-<.]+)\s*(<|--?)\s*\.(.+)/$1.$2$3$1.$4/;  # foo.bar-.baz ==> foo.bar-foo.baz
    if ($str =~ /^([^-<]+)\s*(<|--?)\s*(.+)/) {
        # Examples:
        #   PN1997-1999
        #   PN 1997-PN 1999
        #   PN1997<2000
        ($begin, $rel, $end) = ($1, substr($2, 0, 1), $3);
    }
    elsif ($str =~ /^([^-<]+)$/) {
        # Examples:
        #   KNW
        #   RA 401.3
        #   HD1308.A5
        ($begin, $rel, $end) = ($1, '-', $1);
    }
    else {
        return;  # XXX
    }
    if ($end =~ /^\d+/) {
        $begin =~ /^([A-Z]+)/ and $end = "$1$end";
    }
    ($begin, $end) = map { $cls->normalize($_) } ($begin, $end);
    if ($rel eq '-') {
        $end .= '~';
    }
    return ($begin, $end);
}

# Parse a classification or call number
sub parse {
    my ($cls, $lcc) = @_;
    my ($alpha, $int, $frac, $rmdr) = ('', '', '', '');
    $lcc =~ s/^([A-Z]{1,3}) *// or die "Invalid LCC: $lcc";
    $alpha = $1;
    if ($lcc =~ s/^(\d+)//) {
        $int = $1;
        if ($lcc =~ s/^\.(\d+)//) {
            $frac = $1;
        }
        $rmdr = $lcc;
        $rmdr =~ s/^ *\.?(?=[A-Z])/./;
    }
    $rmdr =~ s/\.(?=[A-Z])//g;
    $rmdr =~ s/(?<=\d)(?=[A-Z])/ /g;
    return ($alpha, $int, $frac, $rmdr);
}

# Add an offset (e.g, '116.5') to a classification (e.g., 'HD6290')
sub add {
    my ($cls, $lcc, $offset) = @_;
    my ($alpha, $int, $frac, $rmdr) = $cls->parse($lcc);
    die "Can't add to a classification with a fractional part" if $frac ne '';
    die "Can't add to a classification with a remainder"       if $rmdr ne '';
    $int += int($offset);
    if ($offset =~ /\./) {
        $frac = $offset - $int;
        return "$alpha$int.$frac"
    }
    else {
        return "$alpha$int";
    }
}

=head1 NAME

Biblio::LCC - parse and normalize LC-style call numbers

=head1 SYNOPSIS

    use Biblio::LCC;
    $normalized = Biblio::LCC->normalize('PS3573.A472242 A88 1998');
    ($begin, $limit) = Biblio::LCC->normalize_range('E184.5-E185');
    @parts = Biblio::LCC->parse($call_number);
    $call_number = Biblio::LCC->add($class, $offset);

=head1 DESCRIPTION

B<Biblio::LCC> parses Library of Congress classification ranges and call numbers
and normalizes them into a form suitable for a straight ASCII sort.

=head1 PUBLIC METHODS

=over 4

=item B<normalize>(I<$call_number>)

    $normalized = Biblio::LCC->normalize('PS3573.A472242 A88 1998');

Convert an LC-style class (e.g., 'PS' or 'E184.5') or call number (e.g.,
'PS3573.A472242 A88 1998') into a string that may be compared to other
normalized call numbers (see B<normalize_range> below).

=item B<normalize_range>(I<$call_number_range>)

    ($begin, $limit) = Biblio::LCC->normalize_range('E184.5-E185');

Parse a call number range, producing a pair of strings I<B> and I<L> such
that a call number falls within the range if and only if its normalized
form, in a straight lexicographic ASCII comparison, is greater than or equal
to I<B> and strictly less than I<L>.

The range may be specified in one of three ways:

=over 4

=item I<call number> B<-> I<call number>

A pair of call numbers; the range includes the beginning call number, the
ending call number, and any call numbers that have the ending call number as
a prefix.

For example, the (unnormalized) range C<AS131-AS142> encompasses any class
or call number from C<AS131> up to B<but not including> C<AS143>

In this form, the alphabetic string that begins the second call number may
be omitted, so (for example) C<E184.5-185> is equivalent to C<E184.5-E185>.

Space is optional around the hyphen.

=item I<call number>

A single class or call number, in unnormalized form.  This is equivalent to
a pair in which each call number is the same.  For example, the unnormalized
range C<QA141.5.A1> encompasses call numbers from C<QA141.5.A1> up to but
not including C<QA141.5.A2>.

=item I<call number> E<lt> I<call number>

A pair of call numbers; the range includes the first call number and any
call number up and not including the ending call number.

For example, the unnormalized range C<< DT6.7E<lt>DT7 >> includes everything
greater than C<DT6.7> and less than C<DT7>.

In this form, the alphabetic string that begins the second call number may
be omitted, as in the form of range that uses a hyphen to separate the parts.

Space is optional around the less-than sign (E<lt>).

=back

=item B<parse>(I<$call_number>)

    ($alpha, $int, $frac, $rmdr) = Biblio::LCC->parse($call_number);

Split an LC call number into alphabetic, integer, decimal fraction, and
remainder (i.e., everything else).

=item B<add>(I<$class>, I<$offset>)

    $call_number = Biblio::LCC->add($class, $offset);

Add an offset (e.g., '180.3') to a base LC class (e.g., 'GN1600') to produce
another LC class (e.g., 'GN1780.3').

The base class may have only alphabetic and integer parts; an exception will be
thrown if it has a fractional part (e.g., as in 'GN1600.1') or a remainder (e.g.,
as in 'GN1600 R5').

=back

=head1 HOW IT WORKS

Call numbers are first analyzed into four parts.  For example, take the call number
B<GB1001.72.M32 E73 1988>.

=over 4

=item B<alpha>

    GB

The one to three alphabetic characters that begin the call number.

=item B<integer>

    1001

An integer from 1 to 9999 that follows.

=item B<fraction>

    72

Digits that follow a decimal point after the integer part.

=item B<remainder>

    M32 E73 1988

Everything that follows.

=back

The LC Classification allows for a wide range of possible call numbers that do
not fall into the simple (alpha, integer, fraction, remainder) model that this
module implements.  For example, the following are
all valid call numbers:

=over 4

=item B<E514.5 17th .S76 1986>
=item B<G3804.N4:3B7 K142t>
=item B<G3824.Y6C5 s50 .W5>

=back

It may be that in some cases further analysis, and fully correct sorting, are
not possible without hardcoded knowledge of the LC classification.  In many
cases, however, a more sophisticated parsing model, while more complex, would
result in better normalization.

=head1 BUGS

There are no known bugs.  Please report bugs on this module's RT page:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Biblio-LCC>.

=head1 TO DO

Implement a C<new> method and rewrite other methods so they may be used as
class B<or> instance methods.

Special handling of "special" call numbers (e.g., in the Gs).

Allow caller to specify prefixes to strip (e.g., "Folio").

Parse straight from the 050 or 090 field of a MARC record.

Better error reporting.

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 COPYRIGHT

Copyright 2007-2008 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.
