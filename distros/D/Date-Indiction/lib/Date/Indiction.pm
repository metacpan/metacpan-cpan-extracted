package Date::Indiction;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(indiction);

our $VERSION = '0.01';
our $SUB;
our $DEFAULT_SUB = 'byzantine';

sub import {
	$SUB = $_[1] ? \&{lc $_[1]} : \&$DEFAULT_SUB;
	goto &Exporter::import;
}

# Returns the indiction of the year using either &byzantine or
# &christian
sub indiction {
	return $SUB->(@_);
}

sub set_aera {
	$SUB = \&{$_[0]};
}

sub byzantine {
	my ($year, $month) = @_;
	$year +=1 if $month && ($month >= 9 || $month < 3);
	$year % 15 || 15;
}

sub christian {
	my ($year, $month) = @_;
	$year +=1 if $month && $month >= 9;
	($year+3) % 15 || 15;
}

*AM = \&byzantine;
*AD = \&christian;

1;
__END__

=head1 NAME

Date::Indiction - Compute a year's indiction as used in old Russian chronicles

=head1 SYNOPSIS

  use Date::Indiction 'Byzantine'; # or 'AM' or 'byzantine' (default)
  use Date::Indiction;             # the same
  use Date::Indiction qw();        # the same, do not import 'indiction'
  use Date::Indiction 'Christian'; # or 'AD' or 'christian'

  $indict = indiction($year, $month);
  $indict = indiction($year);

  Date::Indiction::set_aera('christian');
  $indict = indiction(2016, 12); # December 2016 AD

=head1 DESCRIPTION

Indiction (called I<indict> in Russian chronicles) is the number of
the year in a 15-year cycle, starting from September 1, 312 AD. It can
be calculated for either Byzantine year (Anno Mundi, AM, old Russian
style with the epoch on March 1, 5508 BCE) or Christian year (Anno
Domini, AD). The formulae are, respectively,

    I = AM % 15

    I = (AD + 3) % 15

adding 1 for dates after the 1st of September since indictions change
on this date. (Other counting bases did exist in Western Europe,
however not covered by this module.) See Klimishin I.A. "Calendar and
Chronology". Moscow, Nauka, 1985, pp. 82-85.

The module uses byzantine aera by default. Christian aera can be
requested explicitly on module load or set using C<set_aera> function.

Setting 'christian' is equal to 'AD' and 'byzantine' to 'AM'. Keywords
'christian' and 'byzantine' are case-insensitive.

Month from January to December are numbered from 1 to 12 respectively
for both aerae, although in the Byzantine aera March is the month
number 1, etc. This can be changed in future in favour of more
human-friendly strings like "Jan" or "January".

=head1 CAVEATS

This module does not check the correctness of year and month numbers!
(This can be added in future releases though.)

Module's functions aren't intended to be used as class methods, so you
cannot call them like C<Date::Indiction-E<gt>set_aera(...)>. Obviously
OO interface is not supported either.

=head1 EXPORT

B<indiction> is exported by default. This is done only to provide a
simpler syntax of module loading and common usage cases:

    use Date::Indiction 'Byzantine';

instead of

    use Date::Indiction qw(Byzantine indiction);

or

    use Date::Indiction qw(indiction);
    Date::Indiction::set_aera('Byzantine');

However this can be changed in future. Try

    use Date::Indiction qw();

to avoid polluting your namespace with C<indiction>.

=head1 SEE ALSO

L<Date::GoldenNumber> - another West European medieval dating system

L<Date::Vruceleto> - another old Russian dating system

=head1 AUTHOR

Roman Pavlov E<lt>rp@freeshell.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 Roman Pavlov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
