use Test::More tests => 385;
use utf8;

BEGIN {
use_ok( 'Date::Holidays::PT' );
}

my $mh = Date::Holidays::PT->new();

is_deeply(
  $mh->holidays(2000),
  {
     1 => {
        1 => 'Ano Novo',
     },
     3 => {
        7 => 'Entrudo',
     },
     4 => {
       21 => 'Sexta-feira Santa',
       23 => 'Páscoa',
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador',
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
       22 => 'Corpo de Deus',
     },
     8 => {
       15 => 'Assunção de Nossa Senhora',
     },
    10 => {
        5 => 'Dia da Implantação da República',
     },
    11 => {
        1 => 'Dia de Todos-os-Santos',
     },
    12 => {
        1 => 'Dia da Restauração da Independência',
        8 => 'Imaculada Conceição',
       25 => 'Natal',
     },
  }
);

ok($mh->is_holiday( 2000,  1,  1));
ok($mh->is_holiday( 2000,  3,  7));
ok($mh->is_holiday( 2000,  4, 21));
ok($mh->is_holiday( 2000,  4, 23));
ok($mh->is_holiday( 2000,  4, 25));
ok($mh->is_holiday( 2000,  5,  1));
ok($mh->is_holiday( 2000,  6, 10));
ok($mh->is_holiday( 2000,  6, 22));
ok($mh->is_holiday( 2000,  8, 15));
ok($mh->is_holiday( 2000, 10,  5));
ok($mh->is_holiday( 2000, 11,  1));
ok($mh->is_holiday( 2000, 12,  1));
ok($mh->is_holiday( 2000, 12,  8));
ok($mh->is_holiday( 2000, 12, 25));

is($mh->is_pt_holiday( 2000,  1,  1), 'Ano Novo');
is($mh->is_pt_holiday( 2000,  1,  2), undef);
is($mh->is_pt_holiday( 2000,  1,  3), undef);
is($mh->is_pt_holiday( 2000,  1,  4), undef);
is($mh->is_pt_holiday( 2000,  1,  5), undef);
is($mh->is_pt_holiday( 2000,  1,  6), undef);
is($mh->is_pt_holiday( 2000,  1,  7), undef);
is($mh->is_pt_holiday( 2000,  1,  8), undef);
is($mh->is_pt_holiday( 2000,  1,  9), undef);
is($mh->is_pt_holiday( 2000,  1, 10), undef);
is($mh->is_pt_holiday( 2000,  1, 11), undef);
is($mh->is_pt_holiday( 2000,  1, 12), undef);
is($mh->is_pt_holiday( 2000,  1, 13), undef);
is($mh->is_pt_holiday( 2000,  1, 14), undef);
is($mh->is_pt_holiday( 2000,  1, 15), undef);
is($mh->is_pt_holiday( 2000,  1, 16), undef);
is($mh->is_pt_holiday( 2000,  1, 17), undef);
is($mh->is_pt_holiday( 2000,  1, 18), undef);
is($mh->is_pt_holiday( 2000,  1, 19), undef);
is($mh->is_pt_holiday( 2000,  1, 20), undef);
is($mh->is_pt_holiday( 2000,  1, 21), undef);
is($mh->is_pt_holiday( 2000,  1, 22), undef);
is($mh->is_pt_holiday( 2000,  1, 23), undef);
is($mh->is_pt_holiday( 2000,  1, 24), undef);
is($mh->is_pt_holiday( 2000,  1, 25), undef);
is($mh->is_pt_holiday( 2000,  1, 26), undef);
is($mh->is_pt_holiday( 2000,  1, 27), undef);
is($mh->is_pt_holiday( 2000,  1, 28), undef);
is($mh->is_pt_holiday( 2000,  1, 29), undef);
is($mh->is_pt_holiday( 2000,  1, 30), undef);
is($mh->is_pt_holiday( 2000,  1, 31), undef);

is($mh->is_pt_holiday( 2000,  2,  1), undef);
is($mh->is_pt_holiday( 2000,  2,  2), undef);
is($mh->is_pt_holiday( 2000,  2,  3), undef);
is($mh->is_pt_holiday( 2000,  2,  4), undef);
is($mh->is_pt_holiday( 2000,  2,  5), undef);
is($mh->is_pt_holiday( 2000,  2,  6), undef);
is($mh->is_pt_holiday( 2000,  2,  7), undef);
is($mh->is_pt_holiday( 2000,  2,  8), undef);
is($mh->is_pt_holiday( 2000,  2,  9), undef);
is($mh->is_pt_holiday( 2000,  2, 10), undef);
is($mh->is_pt_holiday( 2000,  2, 11), undef);
is($mh->is_pt_holiday( 2000,  2, 12), undef);
is($mh->is_pt_holiday( 2000,  2, 13), undef);
is($mh->is_pt_holiday( 2000,  2, 14), undef);
is($mh->is_pt_holiday( 2000,  2, 15), undef);
is($mh->is_pt_holiday( 2000,  2, 16), undef);
is($mh->is_pt_holiday( 2000,  2, 17), undef);
is($mh->is_pt_holiday( 2000,  2, 18), undef);
is($mh->is_pt_holiday( 2000,  2, 19), undef);
is($mh->is_pt_holiday( 2000,  2, 20), undef);
is($mh->is_pt_holiday( 2000,  2, 21), undef);
is($mh->is_pt_holiday( 2000,  2, 22), undef);
is($mh->is_pt_holiday( 2000,  2, 23), undef);
is($mh->is_pt_holiday( 2000,  2, 24), undef);
is($mh->is_pt_holiday( 2000,  2, 25), undef);
is($mh->is_pt_holiday( 2000,  2, 26), undef);
is($mh->is_pt_holiday( 2000,  2, 27), undef);
is($mh->is_pt_holiday( 2000,  2, 28), undef);

is($mh->is_pt_holiday( 2000,  3,  1), undef);
is($mh->is_pt_holiday( 2000,  3,  2), undef);
is($mh->is_pt_holiday( 2000,  3,  3), undef);
is($mh->is_pt_holiday( 2000,  3,  4), undef);
is($mh->is_pt_holiday( 2000,  3,  5), undef);
is($mh->is_pt_holiday( 2000,  3,  6), undef);
is($mh->is_pt_holiday( 2000,  3,  7), 'Entrudo');
is($mh->is_pt_holiday( 2000,  3,  8), undef);
is($mh->is_pt_holiday( 2000,  3,  9), undef);
is($mh->is_pt_holiday( 2000,  3, 10), undef);
is($mh->is_pt_holiday( 2000,  3, 11), undef);
is($mh->is_pt_holiday( 2000,  3, 12), undef);
is($mh->is_pt_holiday( 2000,  3, 13), undef);
is($mh->is_pt_holiday( 2000,  3, 14), undef);
is($mh->is_pt_holiday( 2000,  3, 15), undef);
is($mh->is_pt_holiday( 2000,  3, 16), undef);
is($mh->is_pt_holiday( 2000,  3, 17), undef);
is($mh->is_pt_holiday( 2000,  3, 18), undef);
is($mh->is_pt_holiday( 2000,  3, 19), undef);
is($mh->is_pt_holiday( 2000,  3, 20), undef);
is($mh->is_pt_holiday( 2000,  3, 21), undef);
is($mh->is_pt_holiday( 2000,  3, 22), undef);
is($mh->is_pt_holiday( 2000,  3, 23), undef);
is($mh->is_pt_holiday( 2000,  3, 24), undef);
is($mh->is_pt_holiday( 2000,  3, 25), undef);
is($mh->is_pt_holiday( 2000,  3, 26), undef);
is($mh->is_pt_holiday( 2000,  3, 27), undef);
is($mh->is_pt_holiday( 2000,  3, 28), undef);
is($mh->is_pt_holiday( 2000,  3, 29), undef);
is($mh->is_pt_holiday( 2000,  3, 30), undef);
is($mh->is_pt_holiday( 2000,  3, 31), undef);

is($mh->is_pt_holiday( 2000,  4,  1), undef);
is($mh->is_pt_holiday( 2000,  4,  2), undef);
is($mh->is_pt_holiday( 2000,  4,  3), undef);
is($mh->is_pt_holiday( 2000,  4,  4), undef);
is($mh->is_pt_holiday( 2000,  4,  5), undef);
is($mh->is_pt_holiday( 2000,  4,  6), undef);
is($mh->is_pt_holiday( 2000,  4,  7), undef);
is($mh->is_pt_holiday( 2000,  4,  8), undef);
is($mh->is_pt_holiday( 2000,  4,  9), undef);
is($mh->is_pt_holiday( 2000,  4, 10), undef);
is($mh->is_pt_holiday( 2000,  4, 11), undef);
is($mh->is_pt_holiday( 2000,  4, 12), undef);
is($mh->is_pt_holiday( 2000,  4, 13), undef);
is($mh->is_pt_holiday( 2000,  4, 14), undef);
is($mh->is_pt_holiday( 2000,  4, 15), undef);
is($mh->is_pt_holiday( 2000,  4, 16), undef);
is($mh->is_pt_holiday( 2000,  4, 17), undef);
is($mh->is_pt_holiday( 2000,  4, 18), undef);
is($mh->is_pt_holiday( 2000,  4, 19), undef);
is($mh->is_pt_holiday( 2000,  4, 20), undef);
is($mh->is_pt_holiday( 2000,  4, 21), 'Sexta-feira Santa');
is($mh->is_pt_holiday( 2000,  4, 22), undef);
is($mh->is_pt_holiday( 2000,  4, 23), 'Páscoa');
is($mh->is_pt_holiday( 2000,  4, 24), undef);
is($mh->is_pt_holiday( 2000,  4, 25), 'Dia da Liberdade');
is($mh->is_pt_holiday( 2000,  4, 26), undef);
is($mh->is_pt_holiday( 2000,  4, 27), undef);
is($mh->is_pt_holiday( 2000,  4, 28), undef);
is($mh->is_pt_holiday( 2000,  4, 29), undef);
is($mh->is_pt_holiday( 2000,  4, 30), undef);

is($mh->is_pt_holiday( 2000,  5,  1), 'Dia do Trabalhador');
is($mh->is_pt_holiday( 2000,  5,  2), undef);
is($mh->is_pt_holiday( 2000,  5,  3), undef);
is($mh->is_pt_holiday( 2000,  5,  4), undef);
is($mh->is_pt_holiday( 2000,  5,  5), undef);
is($mh->is_pt_holiday( 2000,  5,  6), undef);
is($mh->is_pt_holiday( 2000,  5,  7), undef);
is($mh->is_pt_holiday( 2000,  5,  8), undef);
is($mh->is_pt_holiday( 2000,  5,  9), undef);
is($mh->is_pt_holiday( 2000,  5, 10), undef);
is($mh->is_pt_holiday( 2000,  5, 11), undef);
is($mh->is_pt_holiday( 2000,  5, 12), undef);
is($mh->is_pt_holiday( 2000,  5, 13), undef);
is($mh->is_pt_holiday( 2000,  5, 14), undef);
is($mh->is_pt_holiday( 2000,  5, 15), undef);
is($mh->is_pt_holiday( 2000,  5, 16), undef);
is($mh->is_pt_holiday( 2000,  5, 17), undef);
is($mh->is_pt_holiday( 2000,  5, 18), undef);
is($mh->is_pt_holiday( 2000,  5, 19), undef);
is($mh->is_pt_holiday( 2000,  5, 20), undef);
is($mh->is_pt_holiday( 2000,  5, 21), undef);
is($mh->is_pt_holiday( 2000,  5, 22), undef);
is($mh->is_pt_holiday( 2000,  5, 23), undef);
is($mh->is_pt_holiday( 2000,  5, 24), undef);
is($mh->is_pt_holiday( 2000,  5, 25), undef);
is($mh->is_pt_holiday( 2000,  5, 26), undef);
is($mh->is_pt_holiday( 2000,  5, 27), undef);
is($mh->is_pt_holiday( 2000,  5, 28), undef);
is($mh->is_pt_holiday( 2000,  5, 29), undef);
is($mh->is_pt_holiday( 2000,  5, 30), undef);
is($mh->is_pt_holiday( 2000,  5, 31), undef);

is($mh->is_pt_holiday( 2000,  6,  1), undef);
is($mh->is_pt_holiday( 2000,  6,  2), undef);
is($mh->is_pt_holiday( 2000,  6,  3), undef);
is($mh->is_pt_holiday( 2000,  6,  4), undef);
is($mh->is_pt_holiday( 2000,  6,  5), undef);
is($mh->is_pt_holiday( 2000,  6,  6), undef);
is($mh->is_pt_holiday( 2000,  6,  7), undef);
is($mh->is_pt_holiday( 2000,  6,  8), undef);
is($mh->is_pt_holiday( 2000,  6,  9), undef);
is($mh->is_pt_holiday( 2000,  6, 10), 'Dia de Portugal, de Camões e das Comunidades');
is($mh->is_pt_holiday( 2000,  6, 11), undef);
is($mh->is_pt_holiday( 2000,  6, 12), undef);
is($mh->is_pt_holiday( 2000,  6, 13), undef);
is($mh->is_pt_holiday( 2000,  6, 14), undef);
is($mh->is_pt_holiday( 2000,  6, 15), undef);
is($mh->is_pt_holiday( 2000,  6, 16), undef);
is($mh->is_pt_holiday( 2000,  6, 17), undef);
is($mh->is_pt_holiday( 2000,  6, 18), undef);
is($mh->is_pt_holiday( 2000,  6, 19), undef);
is($mh->is_pt_holiday( 2000,  6, 20), undef);
is($mh->is_pt_holiday( 2000,  6, 21), undef);
is($mh->is_pt_holiday( 2000,  6, 22), 'Corpo de Deus');
is($mh->is_pt_holiday( 2000,  6, 23), undef);
is($mh->is_pt_holiday( 2000,  6, 24), undef);
is($mh->is_pt_holiday( 2000,  6, 25), undef);
is($mh->is_pt_holiday( 2000,  6, 26), undef);
is($mh->is_pt_holiday( 2000,  6, 27), undef);
is($mh->is_pt_holiday( 2000,  6, 28), undef);
is($mh->is_pt_holiday( 2000,  6, 29), undef);
is($mh->is_pt_holiday( 2000,  6, 30), undef);

is($mh->is_pt_holiday( 2000,  7,  1), undef);
is($mh->is_pt_holiday( 2000,  7,  2), undef);
is($mh->is_pt_holiday( 2000,  7,  3), undef);
is($mh->is_pt_holiday( 2000,  7,  4), undef);
is($mh->is_pt_holiday( 2000,  7,  5), undef);
is($mh->is_pt_holiday( 2000,  7,  6), undef);
is($mh->is_pt_holiday( 2000,  7,  7), undef);
is($mh->is_pt_holiday( 2000,  7,  8), undef);
is($mh->is_pt_holiday( 2000,  7,  9), undef);
is($mh->is_pt_holiday( 2000,  7, 10), undef);
is($mh->is_pt_holiday( 2000,  7, 11), undef);
is($mh->is_pt_holiday( 2000,  7, 12), undef);
is($mh->is_pt_holiday( 2000,  7, 13), undef);
is($mh->is_pt_holiday( 2000,  7, 14), undef);
is($mh->is_pt_holiday( 2000,  7, 15), undef);
is($mh->is_pt_holiday( 2000,  7, 16), undef);
is($mh->is_pt_holiday( 2000,  7, 17), undef);
is($mh->is_pt_holiday( 2000,  7, 18), undef);
is($mh->is_pt_holiday( 2000,  7, 19), undef);
is($mh->is_pt_holiday( 2000,  7, 20), undef);
is($mh->is_pt_holiday( 2000,  7, 21), undef);
is($mh->is_pt_holiday( 2000,  7, 22), undef);
is($mh->is_pt_holiday( 2000,  7, 23), undef);
is($mh->is_pt_holiday( 2000,  7, 24), undef);
is($mh->is_pt_holiday( 2000,  7, 25), undef);
is($mh->is_pt_holiday( 2000,  7, 26), undef);
is($mh->is_pt_holiday( 2000,  7, 27), undef);
is($mh->is_pt_holiday( 2000,  7, 28), undef);
is($mh->is_pt_holiday( 2000,  7, 29), undef);
is($mh->is_pt_holiday( 2000,  7, 30), undef);
is($mh->is_pt_holiday( 2000,  7, 31), undef);

is($mh->is_pt_holiday( 2000,  8,  1), undef);
is($mh->is_pt_holiday( 2000,  8,  2), undef);
is($mh->is_pt_holiday( 2000,  8,  3), undef);
is($mh->is_pt_holiday( 2000,  8,  4), undef);
is($mh->is_pt_holiday( 2000,  8,  5), undef);
is($mh->is_pt_holiday( 2000,  8,  6), undef);
is($mh->is_pt_holiday( 2000,  8,  7), undef);
is($mh->is_pt_holiday( 2000,  8,  8), undef);
is($mh->is_pt_holiday( 2000,  8,  9), undef);
is($mh->is_pt_holiday( 2000,  8, 10), undef);
is($mh->is_pt_holiday( 2000,  8, 11), undef);
is($mh->is_pt_holiday( 2000,  8, 12), undef);
is($mh->is_pt_holiday( 2000,  8, 13), undef);
is($mh->is_pt_holiday( 2000,  8, 14), undef);
is($mh->is_pt_holiday( 2000,  8, 15), 'Assunção de Nossa Senhora');
is($mh->is_pt_holiday( 2000,  8, 16), undef);
is($mh->is_pt_holiday( 2000,  8, 17), undef);
is($mh->is_pt_holiday( 2000,  8, 18), undef);
is($mh->is_pt_holiday( 2000,  8, 19), undef);
is($mh->is_pt_holiday( 2000,  8, 20), undef);
is($mh->is_pt_holiday( 2000,  8, 21), undef);
is($mh->is_pt_holiday( 2000,  8, 22), undef);
is($mh->is_pt_holiday( 2000,  8, 23), undef);
is($mh->is_pt_holiday( 2000,  8, 24), undef);
is($mh->is_pt_holiday( 2000,  8, 25), undef);
is($mh->is_pt_holiday( 2000,  8, 26), undef);
is($mh->is_pt_holiday( 2000,  8, 27), undef);
is($mh->is_pt_holiday( 2000,  8, 28), undef);
is($mh->is_pt_holiday( 2000,  8, 29), undef);
is($mh->is_pt_holiday( 2000,  8, 30), undef);
is($mh->is_pt_holiday( 2000,  8, 31), undef);

is($mh->is_pt_holiday( 2000,  9,  1), undef);
is($mh->is_pt_holiday( 2000,  9,  2), undef);
is($mh->is_pt_holiday( 2000,  9,  3), undef);
is($mh->is_pt_holiday( 2000,  9,  4), undef);
is($mh->is_pt_holiday( 2000,  9,  5), undef);
is($mh->is_pt_holiday( 2000,  9,  6), undef);
is($mh->is_pt_holiday( 2000,  9,  7), undef);
is($mh->is_pt_holiday( 2000,  9,  8), undef);
is($mh->is_pt_holiday( 2000,  9,  9), undef);
is($mh->is_pt_holiday( 2000,  9, 10), undef);
is($mh->is_pt_holiday( 2000,  9, 11), undef);
is($mh->is_pt_holiday( 2000,  9, 12), undef);
is($mh->is_pt_holiday( 2000,  9, 13), undef);
is($mh->is_pt_holiday( 2000,  9, 14), undef);
is($mh->is_pt_holiday( 2000,  9, 15), undef);
is($mh->is_pt_holiday( 2000,  9, 16), undef);
is($mh->is_pt_holiday( 2000,  9, 17), undef);
is($mh->is_pt_holiday( 2000,  9, 18), undef);
is($mh->is_pt_holiday( 2000,  9, 19), undef);
is($mh->is_pt_holiday( 2000,  9, 20), undef);
is($mh->is_pt_holiday( 2000,  9, 21), undef);
is($mh->is_pt_holiday( 2000,  9, 22), undef);
is($mh->is_pt_holiday( 2000,  9, 23), undef);
is($mh->is_pt_holiday( 2000,  9, 24), undef);
is($mh->is_pt_holiday( 2000,  9, 25), undef);
is($mh->is_pt_holiday( 2000,  9, 26), undef);
is($mh->is_pt_holiday( 2000,  9, 27), undef);
is($mh->is_pt_holiday( 2000,  9, 28), undef);
is($mh->is_pt_holiday( 2000,  9, 29), undef);
is($mh->is_pt_holiday( 2000,  9, 30), undef);

is($mh->is_pt_holiday( 2000, 10,  1), undef);
is($mh->is_pt_holiday( 2000, 10,  2), undef);
is($mh->is_pt_holiday( 2000, 10,  3), undef);
is($mh->is_pt_holiday( 2000, 10,  4), undef);
is($mh->is_pt_holiday( 2000, 10,  5), 'Dia da Implantação da República');
is($mh->is_pt_holiday( 2000, 10,  6), undef);
is($mh->is_pt_holiday( 2000, 10,  7), undef);
is($mh->is_pt_holiday( 2000, 10,  8), undef);
is($mh->is_pt_holiday( 2000, 10,  9), undef);
is($mh->is_pt_holiday( 2000, 10, 10), undef);
is($mh->is_pt_holiday( 2000, 10, 11), undef);
is($mh->is_pt_holiday( 2000, 10, 12), undef);
is($mh->is_pt_holiday( 2000, 10, 13), undef);
is($mh->is_pt_holiday( 2000, 10, 14), undef);
is($mh->is_pt_holiday( 2000, 10, 15), undef);
is($mh->is_pt_holiday( 2000, 10, 16), undef);
is($mh->is_pt_holiday( 2000, 10, 17), undef);
is($mh->is_pt_holiday( 2000, 10, 18), undef);
is($mh->is_pt_holiday( 2000, 10, 19), undef);
is($mh->is_pt_holiday( 2000, 10, 20), undef);
is($mh->is_pt_holiday( 2000, 10, 21), undef);
is($mh->is_pt_holiday( 2000, 10, 22), undef);
is($mh->is_pt_holiday( 2000, 10, 23), undef);
is($mh->is_pt_holiday( 2000, 10, 24), undef);
is($mh->is_pt_holiday( 2000, 10, 25), undef);
is($mh->is_pt_holiday( 2000, 10, 26), undef);
is($mh->is_pt_holiday( 2000, 10, 27), undef);
is($mh->is_pt_holiday( 2000, 10, 28), undef);
is($mh->is_pt_holiday( 2000, 10, 29), undef);
is($mh->is_pt_holiday( 2000, 10, 30), undef);
is($mh->is_pt_holiday( 2000, 10, 31), undef);

is($mh->is_pt_holiday( 2000, 11,  1), 'Dia de Todos-os-Santos');
is($mh->is_pt_holiday( 2000, 11,  2), undef);
is($mh->is_pt_holiday( 2000, 11,  3), undef);
is($mh->is_pt_holiday( 2000, 11,  4), undef);
is($mh->is_pt_holiday( 2000, 11,  5), undef);
is($mh->is_pt_holiday( 2000, 11,  6), undef);
is($mh->is_pt_holiday( 2000, 11,  7), undef);
is($mh->is_pt_holiday( 2000, 11,  8), undef);
is($mh->is_pt_holiday( 2000, 11,  9), undef);
is($mh->is_pt_holiday( 2000, 11, 10), undef);
is($mh->is_pt_holiday( 2000, 11, 11), undef);
is($mh->is_pt_holiday( 2000, 11, 12), undef);
is($mh->is_pt_holiday( 2000, 11, 13), undef);
is($mh->is_pt_holiday( 2000, 11, 14), undef);
is($mh->is_pt_holiday( 2000, 11, 15), undef);
is($mh->is_pt_holiday( 2000, 11, 16), undef);
is($mh->is_pt_holiday( 2000, 11, 17), undef);
is($mh->is_pt_holiday( 2000, 11, 18), undef);
is($mh->is_pt_holiday( 2000, 11, 19), undef);
is($mh->is_pt_holiday( 2000, 11, 20), undef);
is($mh->is_pt_holiday( 2000, 11, 21), undef);
is($mh->is_pt_holiday( 2000, 11, 22), undef);
is($mh->is_pt_holiday( 2000, 11, 23), undef);
is($mh->is_pt_holiday( 2000, 11, 24), undef);
is($mh->is_pt_holiday( 2000, 11, 25), undef);
is($mh->is_pt_holiday( 2000, 11, 26), undef);
is($mh->is_pt_holiday( 2000, 11, 27), undef);
is($mh->is_pt_holiday( 2000, 11, 28), undef);
is($mh->is_pt_holiday( 2000, 11, 29), undef);
is($mh->is_pt_holiday( 2000, 11, 30), undef);

is($mh->is_pt_holiday( 2000, 12,  1), 'Dia da Restauração da Independência');
is($mh->is_pt_holiday( 2000, 12,  2), undef);
is($mh->is_pt_holiday( 2000, 12,  3), undef);
is($mh->is_pt_holiday( 2000, 12,  4), undef);
is($mh->is_pt_holiday( 2000, 12,  5), undef);
is($mh->is_pt_holiday( 2000, 12,  6), undef);
is($mh->is_pt_holiday( 2000, 12,  7), undef);
is($mh->is_pt_holiday( 2000, 12,  8), 'Imaculada Conceição');
is($mh->is_pt_holiday( 2000, 12,  9), undef);
is($mh->is_pt_holiday( 2000, 12, 10), undef);
is($mh->is_pt_holiday( 2000, 12, 11), undef);
is($mh->is_pt_holiday( 2000, 12, 12), undef);
is($mh->is_pt_holiday( 2000, 12, 13), undef);
is($mh->is_pt_holiday( 2000, 12, 14), undef);
is($mh->is_pt_holiday( 2000, 12, 15), undef);
is($mh->is_pt_holiday( 2000, 12, 16), undef);
is($mh->is_pt_holiday( 2000, 12, 17), undef);
is($mh->is_pt_holiday( 2000, 12, 18), undef);
is($mh->is_pt_holiday( 2000, 12, 19), undef);
is($mh->is_pt_holiday( 2000, 12, 20), undef);
is($mh->is_pt_holiday( 2000, 12, 21), undef);
is($mh->is_pt_holiday( 2000, 12, 22), undef);
is($mh->is_pt_holiday( 2000, 12, 23), undef);
is($mh->is_pt_holiday( 2000, 12, 24), undef);
is($mh->is_pt_holiday( 2000, 12, 25), 'Natal');
is($mh->is_pt_holiday( 2000, 12, 26), undef);
is($mh->is_pt_holiday( 2000, 12, 27), undef);
is($mh->is_pt_holiday( 2000, 12, 28), undef);
is($mh->is_pt_holiday( 2000, 12, 29), undef);
is($mh->is_pt_holiday( 2000, 12, 30), undef);
is($mh->is_pt_holiday( 2000, 12, 31), undef);

is($mh->is_pt_holiday( 2000, 12    ), undef);
is($mh->is_pt_holiday( 2000        ), undef);
is($mh->is_pt_holiday(             ), undef);

is_deeply(
  $mh->holidays(2000),
  {
     1 => {
        1 => 'Ano Novo',
     },
     3 => {
        7 => 'Entrudo',
     },
     4 => {
       21 => 'Sexta-feira Santa',
       23 => 'Páscoa',
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador',
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
       22 => 'Corpo de Deus',
     },
     8 => {
       15 => 'Assunção de Nossa Senhora',
     },
    10 => {
        5 => 'Dia da Implantação da República',
     },
    11 => {
        1 => 'Dia de Todos-os-Santos',
     },
    12 => {
        1 => 'Dia da Restauração da Independência',
        8 => 'Imaculada Conceição',
       25 => 'Natal',
     },
  }
);
