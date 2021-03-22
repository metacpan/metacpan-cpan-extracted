package Business::Barcode::EAN13;

=head1 NAME

Business::Barcode::EAN13 - Perform simple validation of an EAN-13 barcode

=head1 SYNOPSIS

  use Business::Barcode::EAN13 qw/valid_barcode check_digit issuer_ccode best_barcode/;

  my $is_valid     = valid_barcode("5023965006028");
  my $check_digit  = check_digit("502396500602"); 
  my $country_code = issuer_ccode("5023965006028");
  my $best_code    = best_barcode(\@barcodes, \@prefs);

=head1 DESCRIPTION

These subroutines will tell you whether or not an EAN-13 barcode is
self-consistent: i.e. whether or not it checksums correctly. 
If provided with the 12 digit stem of a barcode it will also return the
correct check digit.

We can also return the country in which the manufacturer's identifcation
code was registered, and a method for picking a "most preferred" barcode
from a list, given a preferred country list.

=cut

use strict;
use base 'Exporter';

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT      = qw//;
@EXPORT_OK   = qw/valid_barcode check_digit issuer_ccode best_barcode/;
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION     = "2.11";

# Private global HoL of country -> prefix lookup
my %prefix;

sub _build_prefix {
	while (<DATA>) {
		chomp;
		my ($ccode, $prefix) = split(/:/, $_, 2);

		# Allow the list to have .. and , modifiers to save typing!
		push @{ $prefix{$ccode} }, ($prefix =~ /\.\.|,/) ? eval $prefix : $prefix;
	}
}

=head1 FUNCTIONS

=head2 check_digit

my $check_digit = check_digit("502396500602");    # 8

Given the first 12 digits of a barcode, this will tell you what the last
digit should be. This will return undef if the barcode stem is not
properly formed.

=cut

sub check_digit {
	my $stem = shift;
	unless (_valid_stem($stem)) {
		require Carp;
		Carp::carp("Barcode stems should be 12 digits");
		return undef;
	}
	return undef unless _valid_stem($stem);
	return _check_digit($stem);
}

#-------------------------------------------------------------------------
# The specification for an EAN-13 barcode is described at
#  http://www.mecsw.com/specs/ean_13.html
# The check_digit is basically the number which, when added to 3 times the
# sum of the odd-position numbers plus the sum of the even-position
# numbers gives you 10! A better explanation is available at that URL.
#-------------------------------------------------------------------------

sub _check_digit {
	my $stem = shift;
	my $sum  = 0;
	while ($stem) {
		$sum += (chop $stem) * 3;
		$sum += chop $stem;
	}
	my $mod = 10 - ($sum % 10);
	return ($mod == 10) ? 0 : $mod;
}

=head2 valid_barcode

my $is_valid = valid_barcode("5023965006028");

Tell whether or not the given barcode is valid. This obviously does not
check if it a real barcode; only if it is of correct length, and has a
valid check-digit.

=cut

#--------------------------------------------------------------------------
# A barcode is deemed to be valid if the stem is 12 digits, and the 13th
# digit is the expected check digit
#--------------------------------------------------------------------------
sub valid_barcode {
	my $bcode       = shift;
	my $check_digit = chop($bcode);
	return 0 unless _valid_stem($bcode);
	return ($check_digit == _check_digit($bcode));
}

sub _valid_stem {
	my $stem = shift;
	return ($stem =~ /^\d{12}$/);
}

=head2 issuer_ccode

my $country_code = issuer_ccode("5023965006028"); # "uk"

Returns the ISO 2 digit country code (you could use Locale::Country,
or equivalent, to convert to the country name, if required) of the
barcode issuer. (Note: This is not necessarily the same as the country
of manufacture of the goods).

This does not test the validity of the barcode.

=cut

sub issuer_ccode {
	my $bcode = shift;

	# We should really build a hash lookup in the opposite direction here
	_build_prefix() unless %prefix;

	foreach (keys %prefix) {
		return $_ if (my @match = grep { $bcode =~ /^$_/ } @{ $prefix{$_} });
	}
	return "";
}

=head2 best_barcode

my $best_barcode = best_barcode(\@list_of_barcodes, \@optional_prefs);

Given an arrayref of barcodes, this will return the "most preferred"
barcode from the list.

If you don't pass any preferences, this will be the first valid barcode
in the list. With a list of "preferred prefixes", this will return the
best match from your list in order of preference of your prefix. A
prefix can either be a numeric barcode stem, or a 2 letter country code,
which will be expanded into the list of current barcode stems available
to that country.

e.g. if you have a list of 10 barcodes for the same product
internationally, and would prefer the UK barcode if it exists, otherwise
the Irish one, otherwise any valid barcode, you would call:

  my $best_barcode = best_barcode(\@barcodes, ["uk", "ie"]);

If there are no valid barcodes in your list this will return the first
barcode which would be valid if it was zero-padded, or null if none
meet this final criterion.

=cut

sub best_barcode {
	my $bref = shift;
	my $pref_ref = shift || [];
	_build_prefix() unless %prefix;
	my @prefs = map { @{ $prefix{$_} || [$_] } } @$pref_ref;

	my $best = "";
	my @invalids;
	BARCODE: foreach my $barcode (@$bref) {
		unless (valid_barcode($barcode)) {
			push @invalids => $barcode if (length $barcode < 13);
			next BARCODE;
		}

		# if we have no conditions, then any valid match wins ...
		return $barcode unless @prefs;
		PREF: foreach my $pref (0 .. @prefs - 1) {
			next PREF unless ($barcode =~ /^$prefs[$pref]/);
			return $barcode if ($pref == 0);
			$best = $barcode;
			splice @prefs, $pref;
			next BARCODE;
		}
		$best = $barcode;
	}

	# We have no valid matches, so check the invalids.
	# We should really check the preferences again here,
	# perhaps with something like:
	#  return $best if $best;
	#  return undef unless @invalids;
	#  my @padded = map { sprintf "%013s", $_ }, @invalids;
	#  return best_barcode(\@padded);

	unless ($best) {
		foreach my $barcode (@invalids) {
			$barcode = sprintf "%013s", $barcode;
			next unless valid_barcode($barcode);
			$best = $barcode;
			last;
		}
	}
	return $best || undef;
}

=head1 BUGS

When zero-filling the barcodes in "best_barcode" we should re-apply the
preferences again, rather than just taking the first valid barcode.

=head1 TODO

Allow other barcode families than EAN-13

=head1 AUTHOR

Colm Dougan, Tony Bowden and Jan Willamowius (https://www.ean-search.org)

=head1 LICENSE

This program may be distributed under the same license as Perl itself.

=cut

return q/
  i don't want the world i just want your half
/;

# Here lies the mapping data from country to barcode-prefix.
__DATA__
us:'00'..'19'
fr:30..37
bg:380
si:383
hr:385
ba:387
me:389
ks:390
de:400..440
jp:45,49
ru:460..469
kg:470
tw:471
ee:474
lv:475
az:476
lt:477
uz:478
lk:479
ph:480
by:481
ua:482
tm:483
md:484
am:485
ge:486
kz:487
hk:489
uk:50
gr:520,521
lb:528
cy:529
al:530
mk:531
mt:535
ie:539
be:54
lu:54
pt:560
is:569
dk:57
pl:590
ro:594
hu:599
za:600,601
gh:603
sn:604
ba:608
mu:609
ma:611
dz:613
ke:616
ng:615
ke:616
cm:617
ci:618
tn:619
tz:620
sy:621
eg:622
bn:623
ly:624
jo:625
ir:626
kw:627
sa:628
ae:629
qa:630
fi:64
cn:69
no:70
il:729
se:73
gt:740
sv:741
hn:742
ni:743
cr:744
pa:745
do:746
mx:750
ca:754,755
ve:759
ch:76
co:770,771
uy:773
pe:775
bo:777
ar:778,779
cl:780
py:784
ec:786
br:789,790
it:80..83
es:84
cu:850
sk:858
cz:859
yu:860
mn:865
kp:867
tr:868,869
nl:87
kr:880
mm:883
kh:884
th:885
sg:888
in:890
vn:893
pk:896
id:899
at:90,91
au:93
nz:94
my:955
mo:958
