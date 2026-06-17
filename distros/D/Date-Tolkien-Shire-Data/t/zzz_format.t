package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __format __on_date __on_date_accented
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 207;

my $normal = {
    year	=> 1419,
    month	=> 3,
    day		=> 25,
};
my $holiday	= {
    year	=> 1419,
    month	=> 0,
    day		=> 2,
};
my $special	= {
    year	=> 1419,
    month	=> 0,
    day		=> 3,
    hour	=> 1,
    minute	=> 2,
    second	=> 3,
    epoch	=> 1234,
    zone_offset	=> 0,
    zone_name	=> 'UTC',
};

is( __format( $normal,  '%{__fmt_shire_year}' ), '1419',
    q<%{__fmt_shire_year} on 25 Rethe 1419> );
is( __format( $holiday, '%{__fmt_shire_year}' ), '1419',
    q<%{__fmt_shire_year} on 1 Lithe 1419> );
is( __format( $special, '%{__fmt_shire_year}' ), '1419',
    q<%{__fmt_shire_year} on Midyear_number's day 1419> );

is( __format( $normal,  '%A' ), 'Sunday', q<%A on 25 Rethe 1419> );
is( __format( $holiday, '%A' ), 'Highday', q<%A on 1 Lithe 1419> );
is( __format( $special, '%A' ), '', q<%A on Midyear's day 1419> );

is( __format( $normal,  '%^A' ), 'SUNDAY', q<%^A on 25 Rethe 1419> );
is( __format( $holiday, '%^A' ), 'HIGHDAY', q<%^A on 1 Lithe 1419> );
is( __format( $special, '%^A' ), '', q<%^A on Midyear's day 1419> );

is( __format( $normal,  '%a' ), 'Sun', q<%a on 25 Rethe 1419> );
is( __format( $holiday, '%a' ), 'Hig', q<%a on 1 Lithe 1419> );
is( __format( $special, '%a' ), '', q<%a on Midyear's day 1419> );

is( __format( $normal,  '%B' ), 'Rethe', q<%B on 25 Rethe 1419> );
is( __format( $holiday, '%B' ), '', q<%B on 1 Lithe 1419> );
is( __format( $special, '%B' ), '', q<%B on Midyear's day 1419> );

is( __format( $normal,  '%b' ), 'Ret', q<%b on 25 Rethe 1419> );
is( __format( $holiday, '%b' ), '', q<%b on 1 Lithe 1419> );
is( __format( $special, '%b' ), '', q<%b on Midyear's day 1419> );

is( __format( $normal,  '%C' ), '14', q<%C on 25 Rethe 1419> );
is( __format( $holiday, '%C' ), '14', q<%C on 1 Lithe 1419> );
is( __format( $special, '%C' ), '14', q<%C on Midyear's day 1419> );

# %c is deferred until all component formats have been tested.

# %D is deferred until all component formats have been tested.

is( __format( $normal,  '%d' ), '25', q<%d on 25 Rethe 1419> );
is( __format( $holiday, '%d' ), '02', q<%d on 1 Lithe 1419> );
is( __format( $special, '%d' ), '03', q<%d on Midyear's day 1419> );

is( __format( $normal,  '%Ea' ), 'Su', q<%Ea on 25 Rethe 1419> );
is( __format( $holiday, '%Ea' ), 'Hi', q<%Ea on 1 Lithe 1419> );
is( __format( $special, '%Ea' ), '', q<%Ea on Midyear's day 1419> );

is( __format( $normal,  '%EL' ), 'Rethe 25', q<%EL on 25 Rethe 1419> );
is( __format( $holiday, '%EL' ), '1 Lithe', q<%EL on 1 Lithe 1419> );
is( __format( $special, '%EL' ), q<Midyear's day>,
    q<%EL on Midyear's day 1419> );

is( __format( $normal,  '%El' ), 'Ret 25', q<%El on 25 Rethe 1419> );
is( __format( $holiday, '%El' ), '1Li', q<%El on 1 Lithe 1419> );
is( __format( $special, '%El' ), 'Myd', q<%El on Midyear's day 1419> );

# Brought forward because it effects %Ed
is( __format( $normal,  '%En' ), '', q<%En on 25 Rethe 1419> );
is( __format( $holiday, '%En' ), '', q<%En on 1 Lithe 1419> );
is( __format( $special, '%En' ), '', q<%En on Midyear's day 1419> );

is( __format( $normal,  '%Ed' ), __on_date( 3, 25 ),
    q<%Ed on 25 Rethe 1419> );
is( __format( $holiday, '%Ed' ), __on_date( 0, 2 ) || '',
    q<%Ed on 1 Lithe 1419> );
is( __format( $special, '%Ed' ), __on_date( 0, 3 ),
    q<%Ed on Midyear's day 1419> );

is( __format( $normal,  '%En%Ed' ), "\n" . __on_date( 3, 25 ),
    q<%En%Ed on 25 Rethe 1419> );
is( __format( $holiday, '%En%Ed' ), '',
    q<%En%Ed on 1 Lithe 1419> );
is( __format( $special, '%En%Ed' ), "\n" . __on_date( 0, 3 ),
    q<%En%Ed on Midyear's day 1419> );

# The purpose of the following three tests is to demonstrate that %En
# gets cleared after %Ed
is( __format( $normal,  '%En%Ed%Ed' ),
    "\n" . __on_date( 3, 25 ) . __on_date( 3, 25 ),
    q<%En%Ed%Ed on 25 Rethe 1419> );
is( __format( $holiday, '%En%Ed%Ed' ), '',
    q<%En%Ed%Ed on 1 Lithe 1419> );
is( __format( $special, '%En%Ed%Ed' ),
    "\n" . __on_date( 0, 3 ) . __on_date( 0, 3 ),
    q<%En%Ed%Ed on Midyear's day 1419> );

is( __format( $normal,  '%EE' ), '', q<%EE on 25 Rethe 1419> );
is( __format( $holiday, '%EE' ), '1 Lithe', q<%EE on 1 Lithe 1419> );
is( __format( $special, '%EE' ), q<Midyear's day>,
    q<%EE on Midyear's day 1419> );

is( __format( $normal,  '%Ee' ), '', q<%Ee on 25 Rethe 1419> );
is( __format( $holiday, '%Ee' ), '1Li', q<%Ee on 1 Lithe 1419> );
is( __format( $special, '%Ee' ), 'Myd', q<%Ee on Midyear's day 1419> );

is( __format( $normal,  '%Eo' ), '', q<%Eo on 25 Rethe 1419> );
is( __format( $holiday, '%Eo' ), '1L', q<%Eo on 1 Lithe 1419> );
is( __format( $special, '%Eo' ), 'My', q<%Eo on Midyear's day 1419> );

# %Ex is deferred until all component formats have been tested.

is( __format( $normal,  '%e' ), '25', q<%e on 25 Rethe 1419> );
is( __format( $holiday, '%e' ), ' 2', q<%e on 1 Lithe 1419> );
is( __format( $special, '%e' ), ' 3', q<%e on Midyear's day 1419> );

# %F is deferred until all component formats have been tested.

is( __format( $normal,  '%G' ), '1419', q<%G on 25 Rethe 1419> );
is( __format( $holiday, '%G' ), '1419', q<%G on 1 Lithe 1419> );
is( __format( $special, '%G' ), '1419', q<%G on Midyear's day 1419> );

is( __format( $normal,  '%H' ), '00', q<%H on 25 Rethe 1419> );
is( __format( $holiday, '%H' ), '00', q<%H on 1 Lithe 1419> );
is( __format( $special, '%H' ), '01', q<%H on Midyear's day 1419> );

is( __format( $normal,  '%h' ), 'Ret', q<%h on 25 Rethe 1419> );
is( __format( $holiday, '%h' ), '', q<%h on 1 Lithe 1419> );
is( __format( $special, '%h' ), '', q<%h on Midyear's day 1419> );

is( __format( $normal,  '%I' ), '12', q<%I on 25 Rethe 1419> );
is( __format( $holiday, '%I' ), '12', q<%I on 1 Lithe 1419> );
is( __format( $special, '%I' ), '01', q<%I on Midyear's day 1419> );

is( __format( $normal,  '%j' ), '086', q<%j on 25 Rethe 1419> );
is( __format( $holiday, '%j' ), '182', q<%j on 1 Lithe 1419> );
is( __format( $special, '%j' ), '183', q<%j on Midyear's day 1419> );

is( __format( $normal,  '%k' ), ' 0', q<%k on 25 Rethe 1419> );
is( __format( $holiday, '%k' ), ' 0', q<%k on 1 Lithe 1419> );
is( __format( $special, '%k' ), ' 1', q<%k on Midyear's day 1419> );

is( __format( $normal,  '%l' ), '12', q<%l on 25 Rethe 1419> );
is( __format( $holiday, '%l' ), '12', q<%l on 1 Lithe 1419> );
is( __format( $special, '%l' ), ' 1', q<%l on Midyear's day 1419> );

is( __format( $normal,  '%M' ), '00', q<%M on 25 Rethe 1419> );
is( __format( $holiday, '%M' ), '00', q<%M on 1 Lithe 1419> );
is( __format( $special, '%M' ), '02', q<%M on Midyear's day 1419> );

is( __format( $normal,  '%m' ), '03', q<%m on 25 Rethe 1419> );
is( __format( $holiday, '%m' ), '00', q<%m on 1 Lithe 1419> );
is( __format( $special, '%m' ), '00', q<%m on Midyear's day 1419> );

is( __format( $normal,  '%-m' ), '3', q<%-m on 25 Rethe 1419> );
is( __format( $normal,  '%_m' ), ' 3', q<%_m on 25 Rethe 1419> );
is( __format( $normal,  '%0m' ), '03', q<%0m on 25 Rethe 1419> );

is( __format( $normal,  '%-4m' ), '   3', q<%-4m on 25 Rethe 1419> );
is( __format( $normal,  '%_4m' ), '   3', q<%_4m on 25 Rethe 1419> );
is( __format( $normal,  '%4m' ), '0003', q<%4m on 25 Rethe 1419> );

# The purpose of the following three tests is to ensure that the Glibc
# flags are cleared after use.
is( __format( $normal,  '%-m%m' ), '303', q<%-m%m on 25 Rethe 1419> );
is( __format( $normal,  '%_m%m' ), ' 303', q<%-m%m on 25 Rethe 1419> );
is( __format( $normal,  '%0m%m' ), '0303', q<%-m on 25 Rethe 1419> );

is( __format( $normal,  '%n' ), "\n", q<%n on 25 Rethe 1419> );
is( __format( $holiday, '%n' ), "\n", q<%n on 1 Lithe 1419> );
is( __format( $special, '%n' ), "\n", q<%n on Midyear's day 1419> );

is( __format( $normal,  '%N' ), '000000000', q<%N on 25 Rethe 1419> );
is( __format( $normal,  '%3N' ), '000', q<%3N on 25 Rethe 1419> );
is( __format( $normal,  '%0N' ), '000000000', q<%0N on 25 Rethe 1419> );

is( __format( $normal,  '%P' ), 'am', q<%P on 25 Rethe 1419> );
is( __format( $holiday, '%P' ), 'am', q<%P on 1 Lithe 1419> );
is( __format( $special, '%P' ), 'am', q<%P on Midyear's day 1419> );

is( __format( $normal,  '%p' ), 'AM', q<%p on 25 Rethe 1419> );
is( __format( $holiday, '%p' ), 'AM', q<%p on 1 Lithe 1419> );
is( __format( $special, '%p' ), 'AM', q<%p on Midyear's day 1419> );

is( __format( $normal,  '%#p' ), 'am', q<%#p on 25 Rethe 1419> );
is( __format( $holiday, '%#p' ), 'am', q<%#p on 1 Lithe 1419> );
is( __format( $special, '%#p' ), 'am', q<%#p on Midyear's day 1419> );

# The point of the following is that '#' trumps '^', even if '^' is to
# the right of '#'.
is( __format( $normal,  '%#^p' ), 'am', q<%#^p on 25 Rethe 1419> );
is( __format( $holiday, '%#^p' ), 'am', q<%#^p on 1 Lithe 1419> );
is( __format( $special, '%#^p' ), 'am', q<%#^p on Midyear's day 1419> );

is( __format( $normal,  '%R' ), '00:00', q<%R on 25 Rethe 1419> );
is( __format( $holiday, '%R' ), '00:00', q<%R on 1 Lithe 1419> );
is( __format( $special, '%R' ), '01:02', q<%R on Midyear's day 1419> );

# %r is deferred until all component formats have been tested.

is( __format( $normal,  '%S' ), '00', q<%S on 25 Rethe 1419> );
is( __format( $holiday, '%S' ), '00', q<%S on 1 Lithe 1419> );
is( __format( $special, '%S' ), '03', q<%S on Midyear's day 1419> );

is( __format( $normal,  '%s' ), '0', q<%s on 25 Rethe 1419> );
is( __format( $holiday, '%s' ), '0', q<%s on 1 Lithe 1419> );
is( __format( $special, '%s' ), '1234', q<%s on Midyear's day 1419> );

is( __format( $normal,  '%T' ), '00:00:00', q<%T on 25 Rethe 1419> );
is( __format( $holiday, '%T' ), '00:00:00', q<%T on 1 Lithe 1419> );
is( __format( $special, '%T' ), '01:02:03', q<%T on Midyear's day 1419> );

is( __format( $normal,  '%t' ), "\t", q<%t on 25 Rethe 1419> );
is( __format( $holiday, '%t' ), "\t", q<%t on 1 Lithe 1419> );
is( __format( $special, '%t' ), "\t", q<%t on Midyear's day 1419> );

is( __format( $normal,  '%U' ), '13', q<%U on 25 Rethe 1419> );
is( __format( $holiday, '%U' ), '26', q<%U on 1 Lithe 1419> );
is( __format( $special, '%U' ), '00', q<%U on Midyear's day 1419> );

is( __format( $normal,  '%u' ), '2', q<%u on 25 Rethe 1419> );
is( __format( $holiday, '%u' ), '7', q<%u on 1 Lithe 1419> );
is( __format( $special, '%u' ), '0', q<%u on Midyear's day 1419> );

is( __format( $normal,  '%V' ), '13', q<%V on 25 Rethe 1419> );
is( __format( $holiday, '%V' ), '26', q<%V on 1 Lithe 1419> );
is( __format( $special, '%V' ), '00', q<%V on Midyear's day 1419> );

is( __format( $normal,  '%v' ), '25-Ret-1419', q<%v on 25 Rethe 1419> );
is( __format( $holiday, '%v' ), '1Li-1419', q<%v on 1 Lithe 1419> );
is( __format( $special, '%v' ), 'Myd-1419', q<%v on Midyear's day 1419> );

is( __format( $normal,  '%W' ), '13', q<%W on 25 Rethe 1419> );
is( __format( $holiday, '%W' ), '26', q<%W on 1 Lithe 1419> );
is( __format( $special, '%W' ), '00', q<%W on Midyear's day 1419> );

is( __format( $normal,  '%w' ), '2', q<%w on 25 Rethe 1419> );
is( __format( $holiday, '%w' ), '7', q<%w on 1 Lithe 1419> );
is( __format( $special, '%w' ), '0', q<%w on Midyear's day 1419> );

# %X is deferred until all component formats have been tested.

# %x is deferred until all component formats have been tested.

is( __format( $normal,  '%Y' ), '1419', q<%Y on 25 Rethe 1419> );
is( __format( $holiday, '%Y' ), '1419', q<%Y on 1 Lithe 1419> );
is( __format( $special, '%Y' ), '1419', q<%Y on Midyear's day 1419> );

is( __format( $normal,  '%y' ), '19', q<%y on 25 Rethe 1419> );
is( __format( $holiday, '%y' ), '19', q<%y on 1 Lithe 1419> );
is( __format( $special, '%y' ), '19', q<%y on Midyear's day 1419> );

is( __format( $normal,  '%Z' ), '', q<%Z on 25 Rethe 1419> );
is( __format( $holiday, '%Z' ), '', q<%Z on 1 Lithe 1419> );
is( __format( $special, '%Z' ), 'UTC', q<%Z on Midyear's day 1419> );

is( __format( $normal,  '%z' ), '', q<%z on 25 Rethe 1419> );
is( __format( $holiday, '%z' ), '', q<%z on 1 Lithe 1419> );
is( __format( $special, '%z' ), '+0000', q<%z on Midyear's day 1419> );

is( __format( $normal,  '%%' ), '%', q<%% on 25 Rethe 1419> );
is( __format( $holiday, '%%' ), '%', q<%% on 1 Lithe 1419> );
is( __format( $special, '%%' ), '%', q<%% on Midyear's day 1419> );

# Deferred

is( __format( $normal,  '%D' ), '03/25/19', q<%D on 25 Rethe 1419> );
is( __format( $holiday, '%D' ), '1Li/19', q<%D on 1 Lithe 1419> );
is( __format( $special, '%D' ), 'Myd/19', q<%D on Midyear's day 1419> );

is( __format( $normal,  '%F' ), '1419-03-25', q<%F on 25 Rethe 1419> );
is( __format( $holiday, '%F' ), '1419-1Li', q<%F on 1 Lithe 1419> );
is( __format( $special, '%F' ), '1419-Myd', q<%F on Midyear's day 1419> );

is( __format( $normal,  '%r' ), '12:00:00 AM', q<%r on 25 Rethe 1419> );
is( __format( $holiday, '%r' ), '12:00:00 AM', q<%r on 1 Lithe 1419> );
is( __format( $special, '%r' ), '01:02:03 AM', q<%r on Midyear's day 1419> );

is( __format( $normal,  '%X' ), '12:00:00 AM', q<%X on 25 Rethe 1419> );
is( __format( $holiday, '%X' ), '12:00:00 AM', q<%X on 1 Lithe 1419> );
is( __format( $special, '%X' ), '01:02:03 AM', q<%X on Midyear's day 1419> );

is( __format( $normal,  '%x' ), '25 Ret 1419', q<%x on 25 Rethe 1419> );
is( __format( $holiday, '%x' ), '1Li 1419', q<%x on 1 Lithe 1419> );
is( __format( $special, '%x' ), 'Myd 1419', q<%x on Midyear's day 1419> );

is( __format( $normal,  '%Ex' ), 'Sunday 25 Rethe 1419',
    q<%Ex on 25 Rethe 1419> );
is( __format( $holiday, '%Ex' ), 'Highday 1 Lithe 1419',
    q<%Ex on 1 Lithe 1419> );
is( __format( $special, '%Ex' ), q<Midyear's day 1419>,
    q<%Ex on Midyear's day 1419> );

# The below should be the same as '%Z', since %EZ has no definition.
is( __format( $normal,  '%EZ' ), '', q<%EZ on 25 Rethe 1419> );
is( __format( $holiday, '%EZ' ), '', q<%EZ on 1 Lithe 1419> );
is( __format( $special, '%EZ' ), 'UTC', q<%EZ on Midyear's day 1419> );

# Deferred even harder, since it uses stuff from the deferred list.

is( __format( $normal,  '%c' ), 'Sun 25 Ret 1419 12:00:00 AM',
    q<%c on 25 Rethe 1419> );
is( __format( $holiday, '%c' ), 'Hig 1Li 1419 12:00:00 AM',
    q<%c on 1 Lithe 1419> );
is( __format( $special, '%c' ), 'Myd 1419 01:02:03 AM',
    q<%c on Midyear's day 1419> );

{
    $normal->{accented} = $holiday->{accented} = $special->{accented} = 1;
    $normal->{traditional} = $holiday->{traditional} =
	$special->{traditional} = 1;

    is( __format( $normal,  '%A' ), 'Sunnendei',
	q<Traditional %A on 25 Rethe 1419> );
    is( __format( $holiday, '%A' ), 'Highdei',
	q<Traditional %A on 1 Lithe 1419> );
    is( __format( $special, '%A' ), '',
	q<Traditional %A on Midyear's day 1419> );

    is( __format( $normal,  '%^A' ), 'SUNNENDEI',
	q<Traditional %^A on 25 Rethe 1419> );
    is( __format( $holiday, '%^A' ), 'HIGHDEI',
	q<Traditional %^A on 1 Lithe 1419> );
    is( __format( $special, '%^A' ), '',
	q<Traditional %^A on Midyear's day 1419> );

    is( __format( $normal,  '%a' ), 'Sun',
	q<Traditional %a on 25 Rethe 1419> );
    is( __format( $holiday, '%a' ), 'Hig',
	q<Traditional %a on 1 Lithe 1419> );
    is( __format( $special, '%a' ), '',
	q<Traditional %a on Midyear's day 1419> );

    is( __format( $normal,  '%Ea' ), 'Su',
	q<Traditional %Ea on 25 Rethe 1419> );
    is( __format( $holiday, '%Ea' ), 'Hi',
	q<Traditional %Ea on 1 Lithe 1419> );
    is( __format( $special, '%Ea' ), '',
	q<Traditional %Ea on Midyear's day 1419> );

    # These three tests are to try to demonstrate that the locale gets
    # propagated all through the __format() subsystem.
    is( __format( $normal, '%Ex' ), 'Sunnendei 25 Rethe 1419',
	q<Traditional %Ex on 25 Rethe 1419>,
    );
    is( __format( $holiday, '%Ex' ), 'Highdei 1 Lithe 1419',
	q<Traditional %Ex on 1 Lithe 1419>,
    );
    is( __format( $special, '%Ex' ), q<Midyear's day 1419>,
	q<Traditional %Ex on Midyear's day 1419>,
    );

    is( __format( $normal,  '%Ed' ), __on_date_accented( 3, 25 ),
	q<Accented %Ed on 25 Rethe 1419> );
    is( __format( $holiday, '%Ed' ), __on_date_accented( 0, 2 ) || '',
	q<Accented %Ed on 1 Lithe 1419> );
    is( __format( $special, '%Ed' ), __on_date_accented( 0, 3 ),
	q<Accented %Ed on Midyear's day 1419> );

    is( __format( $normal,  '%En%Ed' ),
	"\n" . __on_date_accented( 3, 25 ),
	q<Accented %En%Ed on 25 Rethe 1419> );
    is( __format( $holiday, '%En%Ed' ), '',
	q<Accented %En%Ed on 1 Lithe 1419> );
    is( __format( $special, '%En%Ed' ),
	"\n" . __on_date_accented( 0, 3 ),
	q<Accented %En%Ed on Midyear's day 1419> );

    # The purpose of the following three tests is to demonstrate that
    # %En gets cleared after %Ed
    is( __format( $normal,  '%En%Ed%Ed' ),
	"\n" . __on_date_accented( 3, 25 ) .
	    __on_date_accented( 3, 25 ),
	q<Accented %En%Ed%Ed on 25 Rethe 1419> );
    is( __format( $holiday, '%En%Ed%Ed' ), '',
	q<Accented %En%Ed%Ed on 1 Lithe 1419> );
    is( __format( $special, '%En%Ed%Ed' ),
	"\n" . __on_date_accented( 0, 3 ) .
	    __on_date_accented( 0, 3 ),
	q<Accented %En%Ed%Ed on Midyear's day 1419> );
}

1;

# ex: set textwidth=72 :
