# -*- perl -*-

# t/004_podcoverage.t - check function

use Test::More tests => 52;
use DateTime;
use DateTime::Event::Zodiac qw(zodiac_date_name zodiac_date_symbol zodiac_astro_name zodiac_astro_symbol);

my @data = (
    [10 , 10, 2000, 'libra', 'libra'],
    [31 , 12, 2000, 'capricornus', 'capricornus'],
    [1 , 1, 2000, 'capricornus', 'capricornus'],
    [19 , 1, 2000, 'capricornus', 'capricornus'],
    [20 , 1, 2000, 'aquarius', 'capricornus'],
    [4 , 6, 2000, 'gemini', 'gemini'],
    [11 , 10, 1977, 'libra', 'libra'],
    [30 , 6, 1978, 'cancer', 'cancer'],
    [26 , 2, 1976, 'pisces', 'pisces'],
    [27 , 03, 1979, 'aries', 'aries'],
    # http://www.themamundi.de/aws/tabellen/ingress.htm
    [22 , 8, 2004, 'leo', 'leo',18], 
    [22 , 8, 2004, 'leo', 'virgo',21],
    [21 , 5, 2003, 'gemini', 'taurus',10], 
    
    [21 , 5, 2003, 'gemini', 'gemini',12],
);

foreach (@data) {
    my $dt = DateTime->new( 
        year   => $_->[2],
        month  => $_->[1],
        day    => $_->[0],
        hour   => ($_->[5] || 12),
        minute => 0,
    );
    
    is(zodiac_date_name($dt),$_->[3],$dt->dmy.' '.$_->[3]);
    is(zodiac_astro_name($dt),$_->[4],$dt->dmy.' '.$_->[4]);
}

my @symbols = (
    "\x{2651}",
    "\x{2652}",
    "\x{2653}",
    "\x{2648}",
    "\x{2649}",
    "\x{264a}",
    "\x{264b}",
    "\x{264c}",
    "\x{264d}",
    "\x{264e}",
    "\x{264f}",
    "\x{2650}"
);

my $dt = DateTime->new( 
    year   => 2008,
    month  => 1,
    day    => 1,
);
for (1..12) {
   $dt->set(month => $_); 
   is(zodiac_astro_symbol($dt),$symbols[$_ -1],$dt->dmy.' symbol astro');
   is(zodiac_date_symbol($dt),$symbols[$_ -1],$dt->dmy.' symbol date');
}