use Test::More tests => 367;

BEGIN {
use_ok( 'Date::Holidays::BR' );
}

my $mh = Date::Holidays::BR->new();

is_deeply(
  $mh->holidays(2009),
  {
     1 => {
        1 => 'Confraternização Universal'
     },
     4 => {
       10 => 'Sexta-feira da Paixão',
       21 => 'Tiradentes'
     },
     5 => {
        1 => 'Dia do Trabalho'
     },
     9 => {
        7 => 'Independência do Brasil',
     },
    10 => {
       12 => 'Nossa Senhora Aparecida',
     },
    11 => {
        2 => 'Dia de Finados',
       15 => 'Proclamação da República'
     },
    12 => {
       25 => 'Natal',
     },
  }
);

is($mh->is_br_holiday( 2009,  1,  1), 'Confraternização Universal');
is($mh->is_br_holiday( 2009,  1,  2), undef);
is($mh->is_br_holiday( 2009,  1,  3), undef);
is($mh->is_br_holiday( 2009,  1,  4), undef);
is($mh->is_br_holiday( 2009,  1,  5), undef);
is($mh->is_br_holiday( 2009,  1,  6), undef);
is($mh->is_br_holiday( 2009,  1,  7), undef);
is($mh->is_br_holiday( 2009,  1,  8), undef);
is($mh->is_br_holiday( 2009,  1,  9), undef);
is($mh->is_br_holiday( 2009,  1, 10), undef);
is($mh->is_br_holiday( 2009,  1, 11), undef);
is($mh->is_br_holiday( 2009,  1, 12), undef);
is($mh->is_br_holiday( 2009,  1, 13), undef);
is($mh->is_br_holiday( 2009,  1, 14), undef);
is($mh->is_br_holiday( 2009,  1, 15), undef);
is($mh->is_br_holiday( 2009,  1, 16), undef);
is($mh->is_br_holiday( 2009,  1, 17), undef);
is($mh->is_br_holiday( 2009,  1, 18), undef);
is($mh->is_br_holiday( 2009,  1, 19), undef);
is($mh->is_br_holiday( 2009,  1, 20), undef);
is($mh->is_br_holiday( 2009,  1, 21), undef);
is($mh->is_br_holiday( 2009,  1, 22), undef);
is($mh->is_br_holiday( 2009,  1, 23), undef);
is($mh->is_br_holiday( 2009,  1, 24), undef);
is($mh->is_br_holiday( 2009,  1, 25), undef);
is($mh->is_br_holiday( 2009,  1, 26), undef);
is($mh->is_br_holiday( 2009,  1, 27), undef);
is($mh->is_br_holiday( 2009,  1, 28), undef);
is($mh->is_br_holiday( 2009,  1, 29), undef);
is($mh->is_br_holiday( 2009,  1, 30), undef);
is($mh->is_br_holiday( 2009,  1, 31), undef);

is($mh->is_br_holiday( 2009,  2,  1), undef);
is($mh->is_br_holiday( 2009,  2,  2), undef);
is($mh->is_br_holiday( 2009,  2,  3), undef);
is($mh->is_br_holiday( 2009,  2,  4), undef);
is($mh->is_br_holiday( 2009,  2,  5), undef);
is($mh->is_br_holiday( 2009,  2,  6), undef);
is($mh->is_br_holiday( 2009,  2,  7), undef);
is($mh->is_br_holiday( 2009,  2,  8), undef);
is($mh->is_br_holiday( 2009,  2,  9), undef);
is($mh->is_br_holiday( 2009,  2, 10), undef);
is($mh->is_br_holiday( 2009,  2, 11), undef);
is($mh->is_br_holiday( 2009,  2, 12), undef);
is($mh->is_br_holiday( 2009,  2, 13), undef);
is($mh->is_br_holiday( 2009,  2, 14), undef);
is($mh->is_br_holiday( 2009,  2, 15), undef);
is($mh->is_br_holiday( 2009,  2, 16), undef);
is($mh->is_br_holiday( 2009,  2, 17), undef);
is($mh->is_br_holiday( 2009,  2, 18), undef);
is($mh->is_br_holiday( 2009,  2, 19), undef);
is($mh->is_br_holiday( 2009,  2, 20), undef);
is($mh->is_br_holiday( 2009,  2, 21), undef);
is($mh->is_br_holiday( 2009,  2, 22), undef);
is($mh->is_br_holiday( 2009,  2, 23), undef);
is($mh->is_br_holiday( 2009,  2, 24), undef);
is($mh->is_br_holiday( 2009,  2, 25), undef);
is($mh->is_br_holiday( 2009,  2, 26), undef);
is($mh->is_br_holiday( 2009,  2, 27), undef);
is($mh->is_br_holiday( 2009,  2, 28), undef);

is($mh->is_br_holiday( 2009,  3,  1), undef);
is($mh->is_br_holiday( 2009,  3,  2), undef);
is($mh->is_br_holiday( 2009,  3,  3), undef);
is($mh->is_br_holiday( 2009,  3,  4), undef);
is($mh->is_br_holiday( 2009,  3,  5), undef);
is($mh->is_br_holiday( 2009,  3,  6), undef);
is($mh->is_br_holiday( 2009,  3,  7), undef);
is($mh->is_br_holiday( 2009,  3,  8), undef);
is($mh->is_br_holiday( 2009,  3,  9), undef);
is($mh->is_br_holiday( 2009,  3, 10), undef);
is($mh->is_br_holiday( 2009,  3, 11), undef);
is($mh->is_br_holiday( 2009,  3, 12), undef);
is($mh->is_br_holiday( 2009,  3, 13), undef);
is($mh->is_br_holiday( 2009,  3, 14), undef);
is($mh->is_br_holiday( 2009,  3, 15), undef);
is($mh->is_br_holiday( 2009,  3, 16), undef);
is($mh->is_br_holiday( 2009,  3, 17), undef);
is($mh->is_br_holiday( 2009,  3, 18), undef);
is($mh->is_br_holiday( 2009,  3, 19), undef);
is($mh->is_br_holiday( 2009,  3, 20), undef);
is($mh->is_br_holiday( 2009,  3, 21), undef);
is($mh->is_br_holiday( 2009,  3, 22), undef);
is($mh->is_br_holiday( 2009,  3, 23), undef);
is($mh->is_br_holiday( 2009,  3, 24), undef);
is($mh->is_br_holiday( 2009,  3, 25), undef);
is($mh->is_br_holiday( 2009,  3, 26), undef);
is($mh->is_br_holiday( 2009,  3, 27), undef);
is($mh->is_br_holiday( 2009,  3, 28), undef);
is($mh->is_br_holiday( 2009,  3, 29), undef);
is($mh->is_br_holiday( 2009,  3, 30), undef);
is($mh->is_br_holiday( 2009,  3, 31), undef);

is($mh->is_br_holiday( 2009,  4,  1), undef);
is($mh->is_br_holiday( 2009,  4,  2), undef);
is($mh->is_br_holiday( 2009,  4,  3), undef);
is($mh->is_br_holiday( 2009,  4,  4), undef);
is($mh->is_br_holiday( 2009,  4,  5), undef);
is($mh->is_br_holiday( 2009,  4,  6), undef);
is($mh->is_br_holiday( 2009,  4,  7), undef);
is($mh->is_br_holiday( 2009,  4,  8), undef);
is($mh->is_br_holiday( 2009,  4,  9), undef);
is($mh->is_br_holiday( 2009,  4, 10), 'Sexta-feira da Paixão');
is($mh->is_br_holiday( 2009,  4, 11), undef);
is($mh->is_br_holiday( 2009,  4, 12), undef);
is($mh->is_br_holiday( 2009,  4, 13), undef);
is($mh->is_br_holiday( 2009,  4, 14), undef);
is($mh->is_br_holiday( 2009,  4, 15), undef);
is($mh->is_br_holiday( 2009,  4, 16), undef);
is($mh->is_br_holiday( 2009,  4, 17), undef);
is($mh->is_br_holiday( 2009,  4, 18), undef);
is($mh->is_br_holiday( 2009,  4, 19), undef);
is($mh->is_br_holiday( 2009,  4, 20), undef);
is($mh->is_br_holiday( 2009,  4, 21), 'Tiradentes');
is($mh->is_br_holiday( 2009,  4, 22), undef);
is($mh->is_br_holiday( 2009,  4, 23), undef);
is($mh->is_br_holiday( 2009,  4, 24), undef);
is($mh->is_br_holiday( 2009,  4, 25), undef);
is($mh->is_br_holiday( 2009,  4, 26), undef);
is($mh->is_br_holiday( 2009,  4, 27), undef);
is($mh->is_br_holiday( 2009,  4, 28), undef);
is($mh->is_br_holiday( 2009,  4, 29), undef);
is($mh->is_br_holiday( 2009,  4, 30), undef);

is($mh->is_br_holiday( 2009,  5,  1), 'Dia do Trabalho');
is($mh->is_br_holiday( 2009,  5,  2), undef);
is($mh->is_br_holiday( 2009,  5,  3), undef);
is($mh->is_br_holiday( 2009,  5,  4), undef);
is($mh->is_br_holiday( 2009,  5,  5), undef);
is($mh->is_br_holiday( 2009,  5,  6), undef);
is($mh->is_br_holiday( 2009,  5,  7), undef);
is($mh->is_br_holiday( 2009,  5,  8), undef);
is($mh->is_br_holiday( 2009,  5,  9), undef);
is($mh->is_br_holiday( 2009,  5, 10), undef);
is($mh->is_br_holiday( 2009,  5, 11), undef);
is($mh->is_br_holiday( 2009,  5, 12), undef);
is($mh->is_br_holiday( 2009,  5, 13), undef);
is($mh->is_br_holiday( 2009,  5, 14), undef);
is($mh->is_br_holiday( 2009,  5, 15), undef);
is($mh->is_br_holiday( 2009,  5, 16), undef);
is($mh->is_br_holiday( 2009,  5, 17), undef);
is($mh->is_br_holiday( 2009,  5, 18), undef);
is($mh->is_br_holiday( 2009,  5, 19), undef);
is($mh->is_br_holiday( 2009,  5, 20), undef);
is($mh->is_br_holiday( 2009,  5, 21), undef);
is($mh->is_br_holiday( 2009,  5, 22), undef);
is($mh->is_br_holiday( 2009,  5, 23), undef);
is($mh->is_br_holiday( 2009,  5, 24), undef);
is($mh->is_br_holiday( 2009,  5, 25), undef);
is($mh->is_br_holiday( 2009,  5, 26), undef);
is($mh->is_br_holiday( 2009,  5, 27), undef);
is($mh->is_br_holiday( 2009,  5, 28), undef);
is($mh->is_br_holiday( 2009,  5, 29), undef);
is($mh->is_br_holiday( 2009,  5, 30), undef);
is($mh->is_br_holiday( 2009,  5, 31), undef);

is($mh->is_br_holiday( 2009,  6,  1), undef);
is($mh->is_br_holiday( 2009,  6,  2), undef);
is($mh->is_br_holiday( 2009,  6,  3), undef);
is($mh->is_br_holiday( 2009,  6,  4), undef);
is($mh->is_br_holiday( 2009,  6,  5), undef);
is($mh->is_br_holiday( 2009,  6,  6), undef);
is($mh->is_br_holiday( 2009,  6,  7), undef);
is($mh->is_br_holiday( 2009,  6,  8), undef);
is($mh->is_br_holiday( 2009,  6,  9), undef);
is($mh->is_br_holiday( 2009,  6, 10), undef);
is($mh->is_br_holiday( 2009,  6, 11), undef);
is($mh->is_br_holiday( 2009,  6, 12), undef);
is($mh->is_br_holiday( 2009,  6, 13), undef);
is($mh->is_br_holiday( 2009,  6, 14), undef);
is($mh->is_br_holiday( 2009,  6, 15), undef);
is($mh->is_br_holiday( 2009,  6, 16), undef);
is($mh->is_br_holiday( 2009,  6, 17), undef);
is($mh->is_br_holiday( 2009,  6, 18), undef);
is($mh->is_br_holiday( 2009,  6, 19), undef);
is($mh->is_br_holiday( 2009,  6, 20), undef);
is($mh->is_br_holiday( 2009,  6, 21), undef);
is($mh->is_br_holiday( 2009,  6, 22), undef);
is($mh->is_br_holiday( 2009,  6, 23), undef);
is($mh->is_br_holiday( 2009,  6, 24), undef);
is($mh->is_br_holiday( 2009,  6, 25), undef);
is($mh->is_br_holiday( 2009,  6, 26), undef);
is($mh->is_br_holiday( 2009,  6, 27), undef);
is($mh->is_br_holiday( 2009,  6, 28), undef);
is($mh->is_br_holiday( 2009,  6, 29), undef);
is($mh->is_br_holiday( 2009,  6, 30), undef);

is($mh->is_br_holiday( 2009,  7,  1), undef);
is($mh->is_br_holiday( 2009,  7,  2), undef);
is($mh->is_br_holiday( 2009,  7,  3), undef);
is($mh->is_br_holiday( 2009,  7,  4), undef);
is($mh->is_br_holiday( 2009,  7,  5), undef);
is($mh->is_br_holiday( 2009,  7,  6), undef);
is($mh->is_br_holiday( 2009,  7,  7), undef);
is($mh->is_br_holiday( 2009,  7,  8), undef);
is($mh->is_br_holiday( 2009,  7,  9), undef);
is($mh->is_br_holiday( 2009,  7, 10), undef);
is($mh->is_br_holiday( 2009,  7, 11), undef);
is($mh->is_br_holiday( 2009,  7, 12), undef);
is($mh->is_br_holiday( 2009,  7, 13), undef);
is($mh->is_br_holiday( 2009,  7, 14), undef);
is($mh->is_br_holiday( 2009,  7, 15), undef);
is($mh->is_br_holiday( 2009,  7, 16), undef);
is($mh->is_br_holiday( 2009,  7, 17), undef);
is($mh->is_br_holiday( 2009,  7, 18), undef);
is($mh->is_br_holiday( 2009,  7, 19), undef);
is($mh->is_br_holiday( 2009,  7, 20), undef);
is($mh->is_br_holiday( 2009,  7, 21), undef);
is($mh->is_br_holiday( 2009,  7, 22), undef);
is($mh->is_br_holiday( 2009,  7, 23), undef);
is($mh->is_br_holiday( 2009,  7, 24), undef);
is($mh->is_br_holiday( 2009,  7, 25), undef);
is($mh->is_br_holiday( 2009,  7, 26), undef);
is($mh->is_br_holiday( 2009,  7, 27), undef);
is($mh->is_br_holiday( 2009,  7, 28), undef);
is($mh->is_br_holiday( 2009,  7, 29), undef);
is($mh->is_br_holiday( 2009,  7, 30), undef);
is($mh->is_br_holiday( 2009,  7, 31), undef);

is($mh->is_br_holiday( 2009,  8,  1), undef);
is($mh->is_br_holiday( 2009,  8,  2), undef);
is($mh->is_br_holiday( 2009,  8,  3), undef);
is($mh->is_br_holiday( 2009,  8,  4), undef);
is($mh->is_br_holiday( 2009,  8,  5), undef);
is($mh->is_br_holiday( 2009,  8,  6), undef);
is($mh->is_br_holiday( 2009,  8,  7), undef);
is($mh->is_br_holiday( 2009,  8,  8), undef);
is($mh->is_br_holiday( 2009,  8,  9), undef);
is($mh->is_br_holiday( 2009,  8, 10), undef);
is($mh->is_br_holiday( 2009,  8, 11), undef);
is($mh->is_br_holiday( 2009,  8, 12), undef);
is($mh->is_br_holiday( 2009,  8, 13), undef);
is($mh->is_br_holiday( 2009,  8, 14), undef);
is($mh->is_br_holiday( 2009,  8, 15), undef);
is($mh->is_br_holiday( 2009,  8, 16), undef);
is($mh->is_br_holiday( 2009,  8, 17), undef);
is($mh->is_br_holiday( 2009,  8, 18), undef);
is($mh->is_br_holiday( 2009,  8, 19), undef);
is($mh->is_br_holiday( 2009,  8, 20), undef);
is($mh->is_br_holiday( 2009,  8, 21), undef);
is($mh->is_br_holiday( 2009,  8, 22), undef);
is($mh->is_br_holiday( 2009,  8, 23), undef);
is($mh->is_br_holiday( 2009,  8, 24), undef);
is($mh->is_br_holiday( 2009,  8, 25), undef);
is($mh->is_br_holiday( 2009,  8, 26), undef);
is($mh->is_br_holiday( 2009,  8, 27), undef);
is($mh->is_br_holiday( 2009,  8, 28), undef);
is($mh->is_br_holiday( 2009,  8, 29), undef);
is($mh->is_br_holiday( 2009,  8, 30), undef);
is($mh->is_br_holiday( 2009,  8, 31), undef);

is($mh->is_br_holiday( 2009,  9,  1), undef);
is($mh->is_br_holiday( 2009,  9,  2), undef);
is($mh->is_br_holiday( 2009,  9,  3), undef);
is($mh->is_br_holiday( 2009,  9,  4), undef);
is($mh->is_br_holiday( 2009,  9,  5), undef);
is($mh->is_br_holiday( 2009,  9,  6), undef);
is($mh->is_br_holiday( 2009,  9,  7), 'Independência do Brasil');
is($mh->is_br_holiday( 2009,  9,  8), undef);
is($mh->is_br_holiday( 2009,  9,  9), undef);
is($mh->is_br_holiday( 2009,  9, 10), undef);
is($mh->is_br_holiday( 2009,  9, 11), undef);
is($mh->is_br_holiday( 2009,  9, 12), undef);
is($mh->is_br_holiday( 2009,  9, 13), undef);
is($mh->is_br_holiday( 2009,  9, 14), undef);
is($mh->is_br_holiday( 2009,  9, 15), undef);
is($mh->is_br_holiday( 2009,  9, 16), undef);
is($mh->is_br_holiday( 2009,  9, 17), undef);
is($mh->is_br_holiday( 2009,  9, 18), undef);
is($mh->is_br_holiday( 2009,  9, 19), undef);
is($mh->is_br_holiday( 2009,  9, 20), undef);
is($mh->is_br_holiday( 2009,  9, 21), undef);
is($mh->is_br_holiday( 2009,  9, 22), undef);
is($mh->is_br_holiday( 2009,  9, 23), undef);
is($mh->is_br_holiday( 2009,  9, 24), undef);
is($mh->is_br_holiday( 2009,  9, 25), undef);
is($mh->is_br_holiday( 2009,  9, 26), undef);
is($mh->is_br_holiday( 2009,  9, 27), undef);
is($mh->is_br_holiday( 2009,  9, 28), undef);
is($mh->is_br_holiday( 2009,  9, 29), undef);
is($mh->is_br_holiday( 2009,  9, 30), undef);

is($mh->is_br_holiday( 2009, 10,  1), undef);
is($mh->is_br_holiday( 2009, 10,  2), undef);
is($mh->is_br_holiday( 2009, 10,  3), undef);
is($mh->is_br_holiday( 2009, 10,  4), undef);
is($mh->is_br_holiday( 2009, 10,  5), undef);
is($mh->is_br_holiday( 2009, 10,  6), undef);
is($mh->is_br_holiday( 2009, 10,  7), undef);
is($mh->is_br_holiday( 2009, 10,  8), undef);
is($mh->is_br_holiday( 2009, 10,  9), undef);
is($mh->is_br_holiday( 2009, 10, 10), undef);
is($mh->is_br_holiday( 2009, 10, 11), undef);
is($mh->is_br_holiday( 2009, 10, 12), 'Nossa Senhora Aparecida');
is($mh->is_br_holiday( 2009, 10, 13), undef);
is($mh->is_br_holiday( 2009, 10, 14), undef);
is($mh->is_br_holiday( 2009, 10, 15), undef);
is($mh->is_br_holiday( 2009, 10, 16), undef);
is($mh->is_br_holiday( 2009, 10, 17), undef);
is($mh->is_br_holiday( 2009, 10, 18), undef);
is($mh->is_br_holiday( 2009, 10, 19), undef);
is($mh->is_br_holiday( 2009, 10, 20), undef);
is($mh->is_br_holiday( 2009, 10, 21), undef);
is($mh->is_br_holiday( 2009, 10, 22), undef);
is($mh->is_br_holiday( 2009, 10, 23), undef);
is($mh->is_br_holiday( 2009, 10, 24), undef);
is($mh->is_br_holiday( 2009, 10, 25), undef);
is($mh->is_br_holiday( 2009, 10, 26), undef);
is($mh->is_br_holiday( 2009, 10, 27), undef);
is($mh->is_br_holiday( 2009, 10, 28), undef);
is($mh->is_br_holiday( 2009, 10, 29), undef);
is($mh->is_br_holiday( 2009, 10, 30), undef);
is($mh->is_br_holiday( 2009, 10, 31), undef);

is($mh->is_br_holiday( 2009, 11,  1), undef);
is($mh->is_br_holiday( 2009, 11,  2), 'Dia de Finados');
is($mh->is_br_holiday( 2009, 11,  3), undef);
is($mh->is_br_holiday( 2009, 11,  4), undef);
is($mh->is_br_holiday( 2009, 11,  5), undef);
is($mh->is_br_holiday( 2009, 11,  6), undef);
is($mh->is_br_holiday( 2009, 11,  7), undef);
is($mh->is_br_holiday( 2009, 11,  8), undef);
is($mh->is_br_holiday( 2009, 11,  9), undef);
is($mh->is_br_holiday( 2009, 11, 10), undef);
is($mh->is_br_holiday( 2009, 11, 11), undef);
is($mh->is_br_holiday( 2009, 11, 12), undef);
is($mh->is_br_holiday( 2009, 11, 13), undef);
is($mh->is_br_holiday( 2009, 11, 14), undef);
is($mh->is_br_holiday( 2009, 11, 15), 'Proclamação da República');
is($mh->is_br_holiday( 2009, 11, 16), undef);
is($mh->is_br_holiday( 2009, 11, 17), undef);
is($mh->is_br_holiday( 2009, 11, 18), undef);
is($mh->is_br_holiday( 2009, 11, 19), undef);
is($mh->is_br_holiday( 2009, 11, 20), undef);
is($mh->is_br_holiday( 2009, 11, 21), undef);
is($mh->is_br_holiday( 2009, 11, 22), undef);
is($mh->is_br_holiday( 2009, 11, 23), undef);
is($mh->is_br_holiday( 2009, 11, 24), undef);
is($mh->is_br_holiday( 2009, 11, 25), undef);
is($mh->is_br_holiday( 2009, 11, 26), undef);
is($mh->is_br_holiday( 2009, 11, 27), undef);
is($mh->is_br_holiday( 2009, 11, 28), undef);
is($mh->is_br_holiday( 2009, 11, 29), undef);
is($mh->is_br_holiday( 2009, 11, 30), undef);

is($mh->is_br_holiday( 2009, 12,  1), undef);
is($mh->is_br_holiday( 2009, 12,  2), undef);
is($mh->is_br_holiday( 2009, 12,  3), undef);
is($mh->is_br_holiday( 2009, 12,  4), undef);
is($mh->is_br_holiday( 2009, 12,  5), undef);
is($mh->is_br_holiday( 2009, 12,  6), undef);
is($mh->is_br_holiday( 2009, 12,  7), undef);
is($mh->is_br_holiday( 2009, 12,  8), undef);
is($mh->is_br_holiday( 2009, 12,  9), undef);
is($mh->is_br_holiday( 2009, 12, 10), undef);
is($mh->is_br_holiday( 2009, 12, 11), undef);
is($mh->is_br_holiday( 2009, 12, 12), undef);
is($mh->is_br_holiday( 2009, 12, 13), undef);
is($mh->is_br_holiday( 2009, 12, 14), undef);
is($mh->is_br_holiday( 2009, 12, 15), undef);
is($mh->is_br_holiday( 2009, 12, 16), undef);
is($mh->is_br_holiday( 2009, 12, 17), undef);
is($mh->is_br_holiday( 2009, 12, 18), undef);
is($mh->is_br_holiday( 2009, 12, 19), undef);
is($mh->is_br_holiday( 2009, 12, 20), undef);
is($mh->is_br_holiday( 2009, 12, 21), undef);
is($mh->is_br_holiday( 2009, 12, 22), undef);
is($mh->is_br_holiday( 2009, 12, 23), undef);
is($mh->is_br_holiday( 2009, 12, 24), undef);
is($mh->is_br_holiday( 2009, 12, 25), 'Natal');
is($mh->is_br_holiday( 2009, 12, 26), undef);
is($mh->is_br_holiday( 2009, 12, 27), undef);
is($mh->is_br_holiday( 2009, 12, 28), undef);
is($mh->is_br_holiday( 2009, 12, 29), undef);
is($mh->is_br_holiday( 2009, 12, 30), undef);
is($mh->is_br_holiday( 2009, 12, 31), undef);
