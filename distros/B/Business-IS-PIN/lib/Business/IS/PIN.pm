package Business::IS::PIN;
our $VERSION = '0.06';
use strict;

use Exporter 'import';
use List::Util qw(sum);

our %EXPORT_TAGS = (
    all => [ qw<
       valid checksum
       person company
       year month day
    > ],
);

our @EXPORT_OK = @{ $EXPORT_TAGS{ all } };

=encoding utf8

=head1 NAME

Business::IS::PIN - Validate and process Icelandic PIN numbers (Icelandic: kennitE<ouml>lur)

=head1 SYNOPSIS

    # Functional interface
    use Business::IS::PIN qw(:all);

    my $kt = '0902862349'; # Yours truly

    if (valid $kt) {
        # Extract YYYY-MM-DD
        my $year  = year  $kt;
        my $month = month $kt
        my $day   = day   $kt;

        # ...
    }

    # OO interface that doesn't pollute your namespace
    use Business::IS::PIN;

    my $kt = Business::IS::PIN->new('0902862349');

    if ($kt->valid and $kt->person) {
        printf "You are a Real Boy(TM) born on %d-%d-%d\n",
            $kt->year, $kt->month, $kt->day;
    } elsif ($kt->valid and $kt->company) {
        warn "Begone, you spawn of capitalism!";
    } else {
        die "EEEK!";
    }

=head1 DESCRIPTION

This module provides an interface for validating the syntax of and
extracting information from Icelandic personal identification numbers
(Icelandic: I<kennitala>). These are unique 10-digit numbers assigned
to all Icelandic citizens, foreign citizens with permanent residence
and corporations (albeit with a slightly different format, L<see
below|/Format>).

=head1 LIMITATIONS

The National Statistical Institute of Iceland (Icelandic: I<Hagstofa>)
- a goverment organization - handles the assignment of these
numbers. This module will tell you whether the formatting of a given
number is valid, not whether it was actually assigned to someone. For
that you need to pay through the nose to the NSIoI, or cleverly leech
on someone who is:)

=cut

use overload '""' => sub { ${ +shift } };

=head1 EXPORT

None by default, every function in this package except for L</new> can
be exported individually, B<:all> exports them all.

=head1 METHODS & FUNCTIONS

=head2 new

Optional constructor which takes a valid kennitala or a fragment of
one as its argument. Returns an object that L<stringifies|overload> to
whatever string is provided.

If a fragment is provided functions in this package that need
information from the omitted part (such as L</year>) will not work.

=cut

sub new
{
    my ( $pkg, $kt ) = @_;

    bless \$kt => $pkg;
}

=head2 valid

Takes a 9-10 character kennitala and returns true if its checksum is
valid, false otherwise.

=cut

sub checksum; # pre-declare to duck error
sub valid
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];

    my $summed   = substr $kt, 0, 9;
    my $unsummed = substr $kt, 0, 8;
    my $sum = checksum $unsummed;

    $summed eq $unsummed . $sum;
}

=head2 checksum

Takes a the first 8 characters of a kennitala and returns the 9th
checksum digit.

=cut

sub checksum
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];
    my @num = split //, $kt;

    my $sum =
        sum
            # Day
            3 * $num[0],
            2 * $num[1],
            # Month
            7 * $num[2],
            6 * $num[3],
            # Year
            5 * $num[4],
            4 * $num[5],
            # Serial
            3 * $num[6],
            2 * $num[7];

    (11 - $sum % 11) % 11;
}

=head2 person

Returns true if the kennitala belongs to an individual, false
otherwise.

=cut

sub person
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];

    $kt =~ / ^ (?:[0-2]|3[01]) /x;
}

=head2 company

Returns true if the kennitala belongs to a company, false
otherwise.

=cut

sub company
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];

    $kt =~ / ^ (?:3[2-9]|[45]) /x
}

=head2 year

Return the four-digit year part of the kennitala. For this function to
work a complete 10-digit number must have been provided.

=cut

sub year
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];
    my $yy = substr $kt, 4, 2;
    my $c  = substr $kt, 9, 1;
    ($c == 0 ? 2000 : 1000) + ($c . $yy);
}

=head2 month

Return the two-digit month part of the kennitala.

=cut

sub month
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];

    substr $kt, 2, 2;
}

=head2 day

Return the two-digit day part of the kennitala.

=cut

sub day
{
    my $kt = ref $_[0] ? ${$_[0]} : $_[0];

    substr $kt, 0, 2;
}

=head1 Format

The format of an IPIN is relatively simple:

   DDMMYY-SSDC

Where B<DDMMYY> is a two-digit day, month and year, B<SS> is a
pseudo-random serial number, B<D> is the check digit computed from
preceding part and B<C> stands for the century and is not included
when calculating the checksum digit - 8 for 1800s, and 9 and 0 for the
1900s and 2000s respectively. It is customary to place a dash between
the first 6 and last 4 digits when formatting the number.

To compute the check digit from a given IPIN B<0902862349> the
following algorithm is used:

      0   9    0   2    8    6    2   3  4  9
    * 3   2    7   6    5    4    3   2
    = 0 + 18 + 0 + 12 + 40 + 24 + 6 + 6 = 106

    checkdigit = (11 - 106 % 11) % 11

I.e. each digit B<1..8> is multiplied by B<3..2>, B<7..2> respectively
and the result of each multiplication added together to get
B<106>. B<106> is then used as the divend in a modulo operation with
11 as the divisor to get B<7> which is then subtracted from B<11> to
get B<4> - in this case the check digit, if the result had been 11 a
second modulo operation 11 % 11 would have left us with B<0>.

=head1 CAVEATS

Only supports identity numbers assigned between the years
1800-2099. Please resurrect the author when this becomes an issue.

=head1 BUGS

Please report any bugs that aren't already listed at
L<http://rt.cpan.org/Dist/Display.html?Queue=Is-Kennitala> to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Is-Kennitala>

=head1 SEE ALSO

L<http://www.hagstofa.is/?PageID=1474>

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
