use Test::More qw( no_plan );
use Data::Pwgen qw(pwgen pwstrength);

foreach my $i ( 1 .. 100 ) {
    my $pw = pwgen($i);
    is( length($pw), $i, 'PW length is ' . $i );
    my $strength = pwstrength($pw);
    my $ts       = $i - 8;
    ok($strength == Data::Pwgen::strength($pw), "strength() and pwstrength() should agree");
    cmp_ok( $strength, '>=', $ts, 'Strength is ok' );
}

my $pw = pwgen( 16, 'nums' );
ok( $pw =~ m/^\d{16}$/, 'PW (' . $pw . ') contains only numbers' );
$pw = pwgen( 16, 'lower' );
ok( $pw =~ m/^[a-z]{16}$/, 'PW (' . $pw . ') contains only lower-case chars' );
