package Date::Converter;

use strict;
use POSIX;

use vars qw($VERSION);
$VERSION = 1.1;

sub new {
    my ($class, $from, $to) = @_;
    
    my $this = {};

    $from = ucfirst lc $from;
    $to   = ucfirst lc $to;
    
    eval <<EVAL;
        use Date::Converter::$from;
        use Date::Converter::$to;
        \$this->{to_jed  } = \\&Date::Converter::${from}::ymdf_to_jed;
        \$this->{from_jed} = \\&Date::Converter::${to  }::jed_to_ymdf;        
EVAL

    bless $this, $class;
    
    return $this;
}

sub convert {
    my ($this, $year, $month, $day) = @_;

    return $this->{from_jed}($this->{to_jed}($year, $month, $day));
}

sub y_common_to_astronomical {
    my $y = shift;
    
    if ($y < 0) {
        return $y + 1;
    }
    elsif (!$y) {
        return -INT_MAX();
    }
    else {
        return $y;
    }
}

sub y_astronomical_to_common {
    my $y = shift;

    return $y <= 0  ? $y - 1 : $y;
}

sub i_modp {
    my ($i, $j) = @_;
    
    my $ret = $i % $j;
    $ret += abs ($j) if $ret < 0;

    return $ret;
}

sub i_wrap {
    my ($ival, $ilo, $ihi) = @_;

    my $wide = $ihi + 1 - $ilo;

    if ($wide == 0) {
        return $ilo;  
    }
    else {
      return $ilo + i_modp($ival - $ilo, $wide);
    }
}

1;

__END__

=head1 NAME

Date::Converter - Convert dates between calendar systems

=head1 SYNOPSIS

 use Date::Converter;
 my $converter = new Date::Converter('julian', 'gregorian');
 my ($year, $month, $day) = $converter->convert(2009, 2, 23);

=head1 ABSTRACT

Date::Converter provides a method for converting the date between calendars of
different types. Current version includes converters for Alexandrian, Armenian,
Bahai, Coptic, Ethiopian, Gregorian, Hebrew, Islamic, Julian, Macedonian,
Persian, Roman, Republican, Saka, Syrian, Tamil and Zoroastrian calendars in any
combination.

=head1 DESCRIPTION

Module converts groups of three values (year, month, day) into another group of
three values belonging to different calendar. To execute the conversion, first
create an instance of a converter for the desired pair of calendars:

 my $converter = new Date::Converter('armenian', 'hebrew');
 
Then use this instance and pass three values to it:

 my ($year, $month, $day) = $converter->convert(1450, 6, 9);
 
Result is an array of corresponding values in the target calendar.

Names of the source and the destinations are case insensitive and include these:

 alexandrian
 armenian
 bahai
 coptic
 ethiopian
 gregorian
 hebrew
 islamic
 julian
 macedonian
 persian
 republican
 roman
 saka
 syrian
 tamil
 zoroastrian
 
Some calendars are known under synonymical names in literature. Such as Tamil
which is also reffered as Hindu Solar.

Any conversation is performed via so called Julian Ephemeris Date (JED),
which is the fixed date somewhere far in the past. JED value is not available
via module's interface though.

Code of the converters themself is located in respective submodule, for example
Date::Converter::Syrian. Modules are loaded on demand, thus you will not
silencely load calendars that you are not going to use.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 ALGORITHM SOURCE

Algorithms which are implemented in submodules are re-written from Fortran
library CALPAC made by John Burkardt. The library was issued under GNU LGPL
(L<http://people.sc.fsu.edu/~burkardt/txt/gnu_lgpl.txt>) licence.

=head1 COPYRIGHT AND LICENSE

Date::Converter and Date::Converter::* modules are free software. 
You may redistribute and (or) modify it under the same terms as Perl.

Note to follow GNU LGPL licence which was applicabale to initial Fortran library
and part of test data which are located now in t/reper.t test file.

=cut
