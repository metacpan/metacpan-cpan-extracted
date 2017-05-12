package Date::MonthSet;

use strict;

=head1 NAME

Date::MonthSet - simple interface to a collection of months

=head1 SYNOPSIS

 my $set = new Date::MonthSet;

 # accessors: capitalized and lowercase forms.  long and short forms.

 $set->january(1);
 $set->february(1);
 $set->March(1);
 $set->September(1);
 $set->Nov(1);
 $set->dec(1);

 my $s = "$set"; # JFM-----S-ND

 $set->add('June');
 $set->mark('July');

 my $s = "$set"; # JFM--JJ-S-ND

 # configurable placeholder

 $set->placeholder('*');

 my $s = "$set"; # JFM**JJ*S*ND

 $set->remove(qw(jun jul november December));
 $set->clear('march', 'sep');

 my $s = "$set"; # JFM*********

 # testing for members
 
 $set->contains(qw(jan feb));    # true
 $set->contains(2, 3);           # true
 $set->contains(1, 2, 3, 'dec'); # false

 # extracting data
 
 $set->months; # (January February March);
 $set->months_numeric; # (1, 2, 3);

 # numerification (january is the least significant bit)

 my $i = $set + 0; # 7

 $set->march(0);
 my $i = $set + 0; # 3

 $set->february(0);
 my $i = $set + 0; # 1

 $set->jan(0);
 my $i = $set + 0; # 0

---
 
 my $a;
 my $b;
 my $c;
 my $d;

 # initialization of Date::MonthSet objects

 $a = new Date::MonthSet integer => 4;    # march
 $a = new Date::MonthSet integer => 5;    # january and march
 $a = new Date::MonthSet integer => 4095; # twelve set bits: all months

 $b = new Date::MonthSet string => 'JFM---JAS---';
 $b = new Date::MonthSet string => '000111000111';                     # inversed
 $b = new Date::MonthSet string => '###AMJ###OND', placeholder => '#'; # the same

 $c = new Date::MonthSet set => [ 1 .. 12 ];       # all months
 $c = new Date::MonthSet set => [ qw(April sep) ]; # april and september
 $c = new Date::MonthSet set => [ 'jan', 2 .. 3 ]; # the first quarter

 # comparison between Date::MonthSet objects

 $d = new Date::MonthSet set => [ qw(apr may jun oct nov dec)  ];
 $d == $a; # false (six months vs twelve)
 $d == $b; # true (same six months)
 $a == $c; # false (six months vs three)

 $d < $a; # true (six months vs twelve)
 $d < $b; # false (equal)
 $d < $c; # false (six months vs three)

 $d = new Date::MonthSet set => [ qw(oct nov dec) ];
 $d == $a; # false (three months vs twelve)
 $d == $b; # false (three months vs six)
 $d == $c; # false (not the same three months)

 $d < $a; # true (three months vs twelve)
 $d < $b; # true (three months vs six)
 $d < $c; # false ($d is later in the year than $c)

 # addition and subtraction return new Date::MonthSet objects

 $a - $d; # JFMAMJJAS---
 $a - $b; # JFM---JAS---

 $b + $c;      # JFMAMJ---OND
 $b + $c - $d; # JFMAMJ------

=head1 DESCRIPTION

=cut

our $VERSION = 0.2;

use POSIX qw(isdigit isprint);

use overload '""'	=> \&stringify;
use overload '0+'	=> \&numerify;
use overload '=='	=> \&equal;
use overload '!='	=> sub { not equal @_ };
use overload '<=>'	=> \&compare;
use overload '+'	=> \&addition;
use overload '-'	=> \&subtraction;

use constant COMPLEMENT		=> -1;
use constant CONJUNCTION	=> -2;
use constant JANUARY		=> 0;
use constant FEBRUARY		=> 1;
use constant MARCH			=> 2;
use constant APRIL			=> 3;
use constant MAY			=> 4;
use constant JUNE			=> 5;
use constant JULY			=> 6;
use constant AUGUST			=> 7;
use constant SEPTEMBER		=> 8;
use constant OCTOBER		=> 9;
use constant NOVEMEBER		=> 10;
use constant DECEMBER		=> 11;

my @months = qw(January February March April May June July
				August September October November December);

# create four accessors for each month.  for example,
# January will have all four of the following accessors:
#
#   - January
#   - january
#   - Jan
#   - jan

for (my $i = 0; $i < scalar @months; $i++) {
	my $j	= $i;
	my $sub	= sub { scalar @_ > 1 ? $_[0]->[$j] = ($_[1]) ? 1 : 0 : $_[0]->[$j] };

	no strict 'refs';

	*{__PACKAGE__ . '::' . $_} = $sub
		foreach map { $_, substr($_, 0, 3) } $months[$i], lc $months[$i];

	use strict 'refs';
}

=head1 METHODS

=head2 new

=over 2

instantiate a new Date::MonthSet object.  if no arguments
are supplied, an empty Date::MonthSet object will be created
with the placeholder set to a dash '-'.

a Date::MonthSet object can be initialized in several ways.
the constructor accepts the following options, passed as a
hash:

=over 2

=over 2

=item placeholder

defines the placeholder value to be used during the parsing
of string values and the generation of flattened strings.
the default placeholder is a single dash ('-', 0x2d).

=item integer

initialize the Date::MonthSet object according to a single
12-bit integer value describing the months in the collection.
the least significant bit represents January while the most
significant bit represents December.

=item string

initializes the Date::MonthSet object according to a string
value describing the months in the collection.  two formats
are accepted.

the first format is a simple twelve character sequence of
zeroes and ones.  the first byte in the sequence represents
January while the twelfth byte represents December.  if more
that twelve bytes are specified, the constructor will die.

the second format is identifical to the format produced by
stringification of a Date::MonthSet object.  the value of
the placeholder is taken into account.  if the month values
deviate from the standard JFMAMJJASOND, the constructor will
die.  if more values are parsed out of the string than there
should be, the constructor will die.

=item set

initializes the Date::MonthSet object according to an array
of long month names, short month names, and/or numerical
indices.  all three forms may be combined.  duplicates are
ignored.

=back

=back

=back

=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $aref = [ ((0) x 12), '%M', '-' ];

	my %opts = @_;

	warn 'placeholder option is deprecated' if exists $opts{placeholder};

	my $fmt_complement	= $opts{format_complement} || $opts{placeholder} || '-';
	my $fmt_conjunction	= $opts{format_conjunction} || '%M';

	$aref->[COMPLEMENT]		= $fmt_complement;
	$aref->[CONJUNCTION]	= $fmt_conjunction;

	if (my $val = $opts{integer}) {
		die	'integer attribute specified to constructor, ' .
			'but no integer value was specified!' if not isdigit $val;

		do { $aref->[$_] = (($val >> $_) % 2 == 1) ? 1 : $aref->[$_] } for 0 .. 11;
	}

	if (my $val = $opts{string}) {
		die 'string attribute specified to constructor, but no string value ' .
			'was specified!' if not isprint $val;

		my @a;

		if ($val =~ /^[01]{12}$/) {
			@a = split //, $val;
		} else {
			my @conjunctions	= ();
			my @complements		= ();
			my $re				= '';

			foreach my $m (split //, 'JFMAMJJASOND') {
				my $re_conj = $aref->[CONJUNCTION];
				my $re_comp = $aref->[COMPLEMENT];

				$re_conj =~ s/%M/$m/g;
				$re_comp =~ s/%M/$m/g;

				push @conjunctions,	$re_conj;
				push @complements,	$re_comp;

				$re .= "(\Q$re_conj\E|\Q$re_comp\E)";
			}

			@a = map { $_ eq shift @complements ? 0 : 1 } ($val =~ /^$re$/i);
		}

		die 'unable to parse string attribute' if not scalar @a == 12;

		splice @$aref, 0, 11, @a;
	}

	if (my $val = $opts{set}) {
		die 'set attribute specified to constructor, but no set was ' .
			'specified!' if not ref($val) eq 'ARRAY';

		my @numbers	= grep { isdigit $_ } @$val;
		my @terms	= map { lc } grep { not isdigit $_ } @$val;

		do { die "month number $_ is out of range" if $_ < 1 || $_ > 12 }
			foreach @numbers;

		$aref->[$_-1] = 1 foreach @numbers;

		foreach my $term (@terms) {
			for (my $i = 0; $i < scalar @months; $i++) {
				my $month = lc $months[$i];
				$aref->[$i] = 1 if $term eq $month || $term eq substr $month, 0, 3;
			}
		}
	}

	if (my $val = $opts{list}) {
		die 'list attribute specified to constructor, but no list was ' .
			'specified' if not ref($val) eq 'ARRAY';
		die 'a list must have exactly twelve values!'
			if 12 != scalar @$val;

		for (my $i = 0; $i < 11; $i++) {
			$aref->[$i] = $val->[$i] ? 1 : 0;
		}
	}

	return bless $aref, $class;
}

=head2 months

=cut

sub months
{
	my $self	= shift;
	my $i		= -1;

	return map { $i++; $_ == 1 ? ($months[$i]) : () } @$self[0..11];
}

=head2 months_numeric

=cut

sub months_numeric
{
	my $self	= shift;
	my $i		= -1;

	return map { $i++; $_ == 1 ? $i+1 : () } @$self[0..11];
}

=head2 mark/add

=cut

sub mark
{
	my $self = shift;

	return $self->$_(1) foreach @_;
}

sub add { return shift->mark(@_) }

=head2 clear/remove

=cut

sub clear
{
	my $self = shift;

	return $self->$_(0) foreach @_;
}

sub remove { return shift->clear(@_) }

=head2 contains

=cut

sub contains
{
	my $self = shift;

	my @numbers	= grep { isdigit $_ } @_;
	my @terms	= map { lc } grep { not isdigit $_ } @_;
	my $i		= 0;

	do { die "month number $_ is out of range" if $_ < 1 || $_ > 12 }
		foreach @numbers;

#	XXX: die if we are passed a term we don't recognize?
#
#	do {
#		my $term = $_;
#		die "term $t does not describe a month"
#			if not grep { $term eq lc($_) || $term eq substr(lc($_), 0, 3) };
#	} foreach @terms;

	foreach my $term (@terms) {
		$i += scalar grep { ($term eq lc($_)) || ($term eq substr(lc($_), 0, 3)) }
			@months[map { $_ -1 } $self->months_numeric];
	}

	$i += $self->[$_-1] foreach @numbers;

	return $i == scalar(@_) ? 1 : 0;
}

=head2 placeholder

=cut

sub placeholder
{
	my $self = shift;

	warn 'Date::MonthSet->placeholder is deprecated';

	return ($self->format(undef, @_))[1];
}

=head2 format

gets/sets the format used in stringification.  when setting
the format, the first argument defines the format to be used
when the month is contained within the set while the second
argument defines the format to be used when the month is not
contained within the set.  if undef is specified for either
of them, the current setting is unchanged.

=cut

sub format
{
	my $self			= shift;
	my $fmt_conjunction	= shift;
	my $fmt_complement	= shift;

	$self->[CONJUNCTION]	= $fmt_conjunction	if defined $fmt_conjunction;
	$self->[COMPLEMENT]		= $fmt_complement	if defined $fmt_complement;

	return @$self[CONJUNCTION,COMPLEMENT];
}

=head2 stringify

=cut

sub stringify
{
	my $self = shift;

	return join '', map {
		my $s = $self->[$_] ? $self->[CONJUNCTION] : $self->[COMPLEMENT];
		$s =~ s/%M/substr($months[$_], 0, 1)/eg;
		$s;
	} JANUARY .. DECEMBER;
}

=head2 numerify

=cut

sub numerify
{
	my $self	= shift;
	my $val		= 0;
	my $i		= 0;

	$val += $_ << $i++ foreach @$self[0..11];

	return $val;
}

=head2 equal

=cut

sub equal
{
	my $a = shift;
	my $b = shift;

	die "can only test equality on another Date::MonthSet object"
		if !UNIVERSAL::isa($a, 'Date::MonthSet')
		|| !UNIVERSAL::isa($b, 'Date::MonthSet');
	
	do { return 0 if $a->[$_] != $b->[$_] } for 0 .. 11;

	return 1;
}

=head2 compare

=cut

sub compare
{
	my $a = shift;
	my $b = shift;

	die "can only compare to another Date::MonthSet object"
		if !UNIVERSAL::isa($a, 'Date::MonthSet')
		|| !UNIVERSAL::isa($b, 'Date::MonthSet');

	my $amonths = scalar grep { $_ == 1 } @$a[0..11];
	my $bmonths = scalar grep { $_ == 1 } @$a[0..11];

	return $amonths <=> $bmonths if $amonths != $bmonths;
	return $a->numerify <=> $b->numerify;
}

=head2 addition

=cut

sub addition
{
	my $a = shift;
	my $b = shift;

	die "can only add another Date::MonthSet object"
		if !UNIVERSAL::isa($a, 'Date::MonthSet')
		|| !UNIVERSAL::isa($b, 'Date::MonthSet');

	return new Date::MonthSet integer => $a->numerify | $b->numerify;
}

=head2 subtraction

=cut

sub subtraction
{
	my $a = shift;
	my $b = shift;

	die "can only subtract another Date::MonthSet object"
		if !UNIVERSAL::isa($a, 'Date::MonthSet')
		|| !UNIVERSAL::isa($b, 'Date::MonthSet');

	return new Date::MonthSet integer => $a->numerify ^ ($a->numerify & $b->numerify);
}

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

this library is free software.  you may distribute it
and/or modify it under the same terms as perl itself.

=cut

1;
