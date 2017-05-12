use Test::More tests => 385;
use utf8;

BEGIN {
use_ok( 'Date::Holidays::PT' );
}

my $mh = Date::Holidays::PT->new();

is_deeply(
  $mh->holidays(2002),
  {
     1 => {
        1 => 'Ano Novo',
     },
     2 => {
       12 => 'Entrudo',
     },
     3 => {
       29 => 'Sexta-feira Santa',
       31 => 'Páscoa',
     },
     4 => {
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador',
       30 => 'Corpo de Deus',
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
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

ok($mh->is_holiday( 2002,  1,  1));
ok($mh->is_holiday( 2002,  2, 12));
ok($mh->is_holiday( 2002,  3, 29));
ok($mh->is_holiday( 2002,  3, 31));
ok($mh->is_holiday( 2002,  4, 25));
ok($mh->is_holiday( 2002,  5,  1));
ok($mh->is_holiday( 2002,  5, 30));
ok($mh->is_holiday( 2002,  6, 10));
ok($mh->is_holiday( 2002,  8, 15));
ok($mh->is_holiday( 2002, 10,  5));
ok($mh->is_holiday( 2002, 11,  1));
ok($mh->is_holiday( 2002, 12,  1));
ok($mh->is_holiday( 2002, 12,  8));
ok($mh->is_holiday( 2002, 12, 25));

is($mh->is_pt_holiday( 2002,  1,  1), 'Ano Novo');
is($mh->is_pt_holiday( 2002,  1,  2), undef);
is($mh->is_pt_holiday( 2002,  1,  3), undef);
is($mh->is_pt_holiday( 2002,  1,  4), undef);
is($mh->is_pt_holiday( 2002,  1,  5), undef);
is($mh->is_pt_holiday( 2002,  1,  6), undef);
is($mh->is_pt_holiday( 2002,  1,  7), undef);
is($mh->is_pt_holiday( 2002,  1,  8), undef);
is($mh->is_pt_holiday( 2002,  1,  9), undef);
is($mh->is_pt_holiday( 2002,  1, 10), undef);
is($mh->is_pt_holiday( 2002,  1, 11), undef);
is($mh->is_pt_holiday( 2002,  1, 12), undef);
is($mh->is_pt_holiday( 2002,  1, 13), undef);
is($mh->is_pt_holiday( 2002,  1, 14), undef);
is($mh->is_pt_holiday( 2002,  1, 15), undef);
is($mh->is_pt_holiday( 2002,  1, 16), undef);
is($mh->is_pt_holiday( 2002,  1, 17), undef);
is($mh->is_pt_holiday( 2002,  1, 18), undef);
is($mh->is_pt_holiday( 2002,  1, 19), undef);
is($mh->is_pt_holiday( 2002,  1, 20), undef);
is($mh->is_pt_holiday( 2002,  1, 21), undef);
is($mh->is_pt_holiday( 2002,  1, 22), undef);
is($mh->is_pt_holiday( 2002,  1, 23), undef);
is($mh->is_pt_holiday( 2002,  1, 24), undef);
is($mh->is_pt_holiday( 2002,  1, 25), undef);
is($mh->is_pt_holiday( 2002,  1, 26), undef);
is($mh->is_pt_holiday( 2002,  1, 27), undef);
is($mh->is_pt_holiday( 2002,  1, 28), undef);
is($mh->is_pt_holiday( 2002,  1, 29), undef);
is($mh->is_pt_holiday( 2002,  1, 30), undef);
is($mh->is_pt_holiday( 2002,  1, 31), undef);

is($mh->is_pt_holiday( 2002,  2,  1), undef);
is($mh->is_pt_holiday( 2002,  2,  2), undef);
is($mh->is_pt_holiday( 2002,  2,  3), undef);
is($mh->is_pt_holiday( 2002,  2,  4), undef);
is($mh->is_pt_holiday( 2002,  2,  5), undef);
is($mh->is_pt_holiday( 2002,  2,  6), undef);
is($mh->is_pt_holiday( 2002,  2,  7), undef);
is($mh->is_pt_holiday( 2002,  2,  8), undef);
is($mh->is_pt_holiday( 2002,  2,  9), undef);
is($mh->is_pt_holiday( 2002,  2, 10), undef);
is($mh->is_pt_holiday( 2002,  2, 11), undef);
is($mh->is_pt_holiday( 2002,  2, 12), 'Entrudo');
is($mh->is_pt_holiday( 2002,  2, 13), undef);
is($mh->is_pt_holiday( 2002,  2, 14), undef);
is($mh->is_pt_holiday( 2002,  2, 15), undef);
is($mh->is_pt_holiday( 2002,  2, 16), undef);
is($mh->is_pt_holiday( 2002,  2, 17), undef);
is($mh->is_pt_holiday( 2002,  2, 18), undef);
is($mh->is_pt_holiday( 2002,  2, 19), undef);
is($mh->is_pt_holiday( 2002,  2, 20), undef);
is($mh->is_pt_holiday( 2002,  2, 21), undef);
is($mh->is_pt_holiday( 2002,  2, 22), undef);
is($mh->is_pt_holiday( 2002,  2, 23), undef);
is($mh->is_pt_holiday( 2002,  2, 24), undef);
is($mh->is_pt_holiday( 2002,  2, 25), undef);
is($mh->is_pt_holiday( 2002,  2, 26), undef);
is($mh->is_pt_holiday( 2002,  2, 27), undef);
is($mh->is_pt_holiday( 2002,  2, 28), undef);

is($mh->is_pt_holiday( 2002,  3,  1), undef);
is($mh->is_pt_holiday( 2002,  3,  2), undef);
is($mh->is_pt_holiday( 2002,  3,  3), undef);
is($mh->is_pt_holiday( 2002,  3,  4), undef);
is($mh->is_pt_holiday( 2002,  3,  5), undef);
is($mh->is_pt_holiday( 2002,  3,  6), undef);
is($mh->is_pt_holiday( 2002,  3,  7), undef);
is($mh->is_pt_holiday( 2002,  3,  8), undef);
is($mh->is_pt_holiday( 2002,  3,  9), undef);
is($mh->is_pt_holiday( 2002,  3, 10), undef);
is($mh->is_pt_holiday( 2002,  3, 11), undef);
is($mh->is_pt_holiday( 2002,  3, 12), undef);
is($mh->is_pt_holiday( 2002,  3, 13), undef);
is($mh->is_pt_holiday( 2002,  3, 14), undef);
is($mh->is_pt_holiday( 2002,  3, 15), undef);
is($mh->is_pt_holiday( 2002,  3, 16), undef);
is($mh->is_pt_holiday( 2002,  3, 17), undef);
is($mh->is_pt_holiday( 2002,  3, 18), undef);
is($mh->is_pt_holiday( 2002,  3, 19), undef);
is($mh->is_pt_holiday( 2002,  3, 20), undef);
is($mh->is_pt_holiday( 2002,  3, 21), undef);
is($mh->is_pt_holiday( 2002,  3, 22), undef);
is($mh->is_pt_holiday( 2002,  3, 23), undef);
is($mh->is_pt_holiday( 2002,  3, 24), undef);
is($mh->is_pt_holiday( 2002,  3, 25), undef);
is($mh->is_pt_holiday( 2002,  3, 26), undef);
is($mh->is_pt_holiday( 2002,  3, 27), undef);
is($mh->is_pt_holiday( 2002,  3, 28), undef);
is($mh->is_pt_holiday( 2002,  3, 29), 'Sexta-feira Santa');
is($mh->is_pt_holiday( 2002,  3, 30), undef);
is($mh->is_pt_holiday( 2002,  3, 31), 'Páscoa');

is($mh->is_pt_holiday( 2002,  4,  1), undef);
is($mh->is_pt_holiday( 2002,  4,  2), undef);
is($mh->is_pt_holiday( 2002,  4,  3), undef);
is($mh->is_pt_holiday( 2002,  4,  4), undef);
is($mh->is_pt_holiday( 2002,  4,  5), undef);
is($mh->is_pt_holiday( 2002,  4,  6), undef);
is($mh->is_pt_holiday( 2002,  4,  7), undef);
is($mh->is_pt_holiday( 2002,  4,  8), undef);
is($mh->is_pt_holiday( 2002,  4,  9), undef);
is($mh->is_pt_holiday( 2002,  4, 10), undef);
is($mh->is_pt_holiday( 2002,  4, 11), undef);
is($mh->is_pt_holiday( 2002,  4, 12), undef);
is($mh->is_pt_holiday( 2002,  4, 13), undef);
is($mh->is_pt_holiday( 2002,  4, 14), undef);
is($mh->is_pt_holiday( 2002,  4, 15), undef);
is($mh->is_pt_holiday( 2002,  4, 16), undef);
is($mh->is_pt_holiday( 2002,  4, 17), undef);
is($mh->is_pt_holiday( 2002,  4, 18), undef);
is($mh->is_pt_holiday( 2002,  4, 19), undef);
is($mh->is_pt_holiday( 2002,  4, 20), undef);
is($mh->is_pt_holiday( 2002,  4, 21), undef);
is($mh->is_pt_holiday( 2002,  4, 22), undef);
is($mh->is_pt_holiday( 2002,  4, 23), undef);
is($mh->is_pt_holiday( 2002,  4, 24), undef);
is($mh->is_pt_holiday( 2002,  4, 25), 'Dia da Liberdade');
is($mh->is_pt_holiday( 2002,  4, 26), undef);
is($mh->is_pt_holiday( 2002,  4, 27), undef);
is($mh->is_pt_holiday( 2002,  4, 28), undef);
is($mh->is_pt_holiday( 2002,  4, 29), undef);
is($mh->is_pt_holiday( 2002,  4, 30), undef);

is($mh->is_pt_holiday( 2002,  5,  1), 'Dia do Trabalhador');
is($mh->is_pt_holiday( 2002,  5,  2), undef);
is($mh->is_pt_holiday( 2002,  5,  3), undef);
is($mh->is_pt_holiday( 2002,  5,  4), undef);
is($mh->is_pt_holiday( 2002,  5,  5), undef);
is($mh->is_pt_holiday( 2002,  5,  6), undef);
is($mh->is_pt_holiday( 2002,  5,  7), undef);
is($mh->is_pt_holiday( 2002,  5,  8), undef);
is($mh->is_pt_holiday( 2002,  5,  9), undef);
is($mh->is_pt_holiday( 2002,  5, 10), undef);
is($mh->is_pt_holiday( 2002,  5, 11), undef);
is($mh->is_pt_holiday( 2002,  5, 12), undef);
is($mh->is_pt_holiday( 2002,  5, 13), undef);
is($mh->is_pt_holiday( 2002,  5, 14), undef);
is($mh->is_pt_holiday( 2002,  5, 15), undef);
is($mh->is_pt_holiday( 2002,  5, 16), undef);
is($mh->is_pt_holiday( 2002,  5, 17), undef);
is($mh->is_pt_holiday( 2002,  5, 18), undef);
is($mh->is_pt_holiday( 2002,  5, 19), undef);
is($mh->is_pt_holiday( 2002,  5, 20), undef);
is($mh->is_pt_holiday( 2002,  5, 21), undef);
is($mh->is_pt_holiday( 2002,  5, 22), undef);
is($mh->is_pt_holiday( 2002,  5, 23), undef);
is($mh->is_pt_holiday( 2002,  5, 24), undef);
is($mh->is_pt_holiday( 2002,  5, 25), undef);
is($mh->is_pt_holiday( 2002,  5, 26), undef);
is($mh->is_pt_holiday( 2002,  5, 27), undef);
is($mh->is_pt_holiday( 2002,  5, 28), undef);
is($mh->is_pt_holiday( 2002,  5, 29), undef);
is($mh->is_pt_holiday( 2002,  5, 30), 'Corpo de Deus');
is($mh->is_pt_holiday( 2002,  5, 31), undef);

is($mh->is_pt_holiday( 2002,  6,  1), undef);
is($mh->is_pt_holiday( 2002,  6,  2), undef);
is($mh->is_pt_holiday( 2002,  6,  3), undef);
is($mh->is_pt_holiday( 2002,  6,  4), undef);
is($mh->is_pt_holiday( 2002,  6,  5), undef);
is($mh->is_pt_holiday( 2002,  6,  6), undef);
is($mh->is_pt_holiday( 2002,  6,  7), undef);
is($mh->is_pt_holiday( 2002,  6,  8), undef);
is($mh->is_pt_holiday( 2002,  6,  9), undef);
is($mh->is_pt_holiday( 2002,  6, 10), 'Dia de Portugal, de Camões e das Comunidades');
is($mh->is_pt_holiday( 2002,  6, 11), undef);
is($mh->is_pt_holiday( 2002,  6, 12), undef);
is($mh->is_pt_holiday( 2002,  6, 13), undef);
is($mh->is_pt_holiday( 2002,  6, 14), undef);
is($mh->is_pt_holiday( 2002,  6, 15), undef);
is($mh->is_pt_holiday( 2002,  6, 16), undef);
is($mh->is_pt_holiday( 2002,  6, 17), undef);
is($mh->is_pt_holiday( 2002,  6, 18), undef);
is($mh->is_pt_holiday( 2002,  6, 19), undef);
is($mh->is_pt_holiday( 2002,  6, 20), undef);
is($mh->is_pt_holiday( 2002,  6, 21), undef);
is($mh->is_pt_holiday( 2002,  6, 22), undef);
is($mh->is_pt_holiday( 2002,  6, 23), undef);
is($mh->is_pt_holiday( 2002,  6, 24), undef);
is($mh->is_pt_holiday( 2002,  6, 25), undef);
is($mh->is_pt_holiday( 2002,  6, 26), undef);
is($mh->is_pt_holiday( 2002,  6, 27), undef);
is($mh->is_pt_holiday( 2002,  6, 28), undef);
is($mh->is_pt_holiday( 2002,  6, 29), undef);
is($mh->is_pt_holiday( 2002,  6, 30), undef);

is($mh->is_pt_holiday( 2002,  7,  1), undef);
is($mh->is_pt_holiday( 2002,  7,  2), undef);
is($mh->is_pt_holiday( 2002,  7,  3), undef);
is($mh->is_pt_holiday( 2002,  7,  4), undef);
is($mh->is_pt_holiday( 2002,  7,  5), undef);
is($mh->is_pt_holiday( 2002,  7,  6), undef);
is($mh->is_pt_holiday( 2002,  7,  7), undef);
is($mh->is_pt_holiday( 2002,  7,  8), undef);
is($mh->is_pt_holiday( 2002,  7,  9), undef);
is($mh->is_pt_holiday( 2002,  7, 10), undef);
is($mh->is_pt_holiday( 2002,  7, 11), undef);
is($mh->is_pt_holiday( 2002,  7, 12), undef);
is($mh->is_pt_holiday( 2002,  7, 13), undef);
is($mh->is_pt_holiday( 2002,  7, 14), undef);
is($mh->is_pt_holiday( 2002,  7, 15), undef);
is($mh->is_pt_holiday( 2002,  7, 16), undef);
is($mh->is_pt_holiday( 2002,  7, 17), undef);
is($mh->is_pt_holiday( 2002,  7, 18), undef);
is($mh->is_pt_holiday( 2002,  7, 19), undef);
is($mh->is_pt_holiday( 2002,  7, 20), undef);
is($mh->is_pt_holiday( 2002,  7, 21), undef);
is($mh->is_pt_holiday( 2002,  7, 22), undef);
is($mh->is_pt_holiday( 2002,  7, 23), undef);
is($mh->is_pt_holiday( 2002,  7, 24), undef);
is($mh->is_pt_holiday( 2002,  7, 25), undef);
is($mh->is_pt_holiday( 2002,  7, 26), undef);
is($mh->is_pt_holiday( 2002,  7, 27), undef);
is($mh->is_pt_holiday( 2002,  7, 28), undef);
is($mh->is_pt_holiday( 2002,  7, 29), undef);
is($mh->is_pt_holiday( 2002,  7, 30), undef);
is($mh->is_pt_holiday( 2002,  7, 31), undef);

is($mh->is_pt_holiday( 2002,  8,  1), undef);
is($mh->is_pt_holiday( 2002,  8,  2), undef);
is($mh->is_pt_holiday( 2002,  8,  3), undef);
is($mh->is_pt_holiday( 2002,  8,  4), undef);
is($mh->is_pt_holiday( 2002,  8,  5), undef);
is($mh->is_pt_holiday( 2002,  8,  6), undef);
is($mh->is_pt_holiday( 2002,  8,  7), undef);
is($mh->is_pt_holiday( 2002,  8,  8), undef);
is($mh->is_pt_holiday( 2002,  8,  9), undef);
is($mh->is_pt_holiday( 2002,  8, 10), undef);
is($mh->is_pt_holiday( 2002,  8, 11), undef);
is($mh->is_pt_holiday( 2002,  8, 12), undef);
is($mh->is_pt_holiday( 2002,  8, 13), undef);
is($mh->is_pt_holiday( 2002,  8, 14), undef);
is($mh->is_pt_holiday( 2002,  8, 15), 'Assunção de Nossa Senhora');
is($mh->is_pt_holiday( 2002,  8, 16), undef);
is($mh->is_pt_holiday( 2002,  8, 17), undef);
is($mh->is_pt_holiday( 2002,  8, 18), undef);
is($mh->is_pt_holiday( 2002,  8, 19), undef);
is($mh->is_pt_holiday( 2002,  8, 20), undef);
is($mh->is_pt_holiday( 2002,  8, 21), undef);
is($mh->is_pt_holiday( 2002,  8, 22), undef);
is($mh->is_pt_holiday( 2002,  8, 23), undef);
is($mh->is_pt_holiday( 2002,  8, 24), undef);
is($mh->is_pt_holiday( 2002,  8, 25), undef);
is($mh->is_pt_holiday( 2002,  8, 26), undef);
is($mh->is_pt_holiday( 2002,  8, 27), undef);
is($mh->is_pt_holiday( 2002,  8, 28), undef);
is($mh->is_pt_holiday( 2002,  8, 29), undef);
is($mh->is_pt_holiday( 2002,  8, 30), undef);
is($mh->is_pt_holiday( 2002,  8, 31), undef);

is($mh->is_pt_holiday( 2002,  9,  1), undef);
is($mh->is_pt_holiday( 2002,  9,  2), undef);
is($mh->is_pt_holiday( 2002,  9,  3), undef);
is($mh->is_pt_holiday( 2002,  9,  4), undef);
is($mh->is_pt_holiday( 2002,  9,  5), undef);
is($mh->is_pt_holiday( 2002,  9,  6), undef);
is($mh->is_pt_holiday( 2002,  9,  7), undef);
is($mh->is_pt_holiday( 2002,  9,  8), undef);
is($mh->is_pt_holiday( 2002,  9,  9), undef);
is($mh->is_pt_holiday( 2002,  9, 10), undef);
is($mh->is_pt_holiday( 2002,  9, 11), undef);
is($mh->is_pt_holiday( 2002,  9, 12), undef);
is($mh->is_pt_holiday( 2002,  9, 13), undef);
is($mh->is_pt_holiday( 2002,  9, 14), undef);
is($mh->is_pt_holiday( 2002,  9, 15), undef);
is($mh->is_pt_holiday( 2002,  9, 16), undef);
is($mh->is_pt_holiday( 2002,  9, 17), undef);
is($mh->is_pt_holiday( 2002,  9, 18), undef);
is($mh->is_pt_holiday( 2002,  9, 19), undef);
is($mh->is_pt_holiday( 2002,  9, 20), undef);
is($mh->is_pt_holiday( 2002,  9, 21), undef);
is($mh->is_pt_holiday( 2002,  9, 22), undef);
is($mh->is_pt_holiday( 2002,  9, 23), undef);
is($mh->is_pt_holiday( 2002,  9, 24), undef);
is($mh->is_pt_holiday( 2002,  9, 25), undef);
is($mh->is_pt_holiday( 2002,  9, 26), undef);
is($mh->is_pt_holiday( 2002,  9, 27), undef);
is($mh->is_pt_holiday( 2002,  9, 28), undef);
is($mh->is_pt_holiday( 2002,  9, 29), undef);
is($mh->is_pt_holiday( 2002,  9, 30), undef);

is($mh->is_pt_holiday( 2002, 10,  1), undef);
is($mh->is_pt_holiday( 2002, 10,  2), undef);
is($mh->is_pt_holiday( 2002, 10,  3), undef);
is($mh->is_pt_holiday( 2002, 10,  4), undef);
is($mh->is_pt_holiday( 2002, 10,  5), 'Dia da Implantação da República');
is($mh->is_pt_holiday( 2002, 10,  6), undef);
is($mh->is_pt_holiday( 2002, 10,  7), undef);
is($mh->is_pt_holiday( 2002, 10,  8), undef);
is($mh->is_pt_holiday( 2002, 10,  9), undef);
is($mh->is_pt_holiday( 2002, 10, 10), undef);
is($mh->is_pt_holiday( 2002, 10, 11), undef);
is($mh->is_pt_holiday( 2002, 10, 12), undef);
is($mh->is_pt_holiday( 2002, 10, 13), undef);
is($mh->is_pt_holiday( 2002, 10, 14), undef);
is($mh->is_pt_holiday( 2002, 10, 15), undef);
is($mh->is_pt_holiday( 2002, 10, 16), undef);
is($mh->is_pt_holiday( 2002, 10, 17), undef);
is($mh->is_pt_holiday( 2002, 10, 18), undef);
is($mh->is_pt_holiday( 2002, 10, 19), undef);
is($mh->is_pt_holiday( 2002, 10, 20), undef);
is($mh->is_pt_holiday( 2002, 10, 21), undef);
is($mh->is_pt_holiday( 2002, 10, 22), undef);
is($mh->is_pt_holiday( 2002, 10, 23), undef);
is($mh->is_pt_holiday( 2002, 10, 24), undef);
is($mh->is_pt_holiday( 2002, 10, 25), undef);
is($mh->is_pt_holiday( 2002, 10, 26), undef);
is($mh->is_pt_holiday( 2002, 10, 27), undef);
is($mh->is_pt_holiday( 2002, 10, 28), undef);
is($mh->is_pt_holiday( 2002, 10, 29), undef);
is($mh->is_pt_holiday( 2002, 10, 30), undef);
is($mh->is_pt_holiday( 2002, 10, 31), undef);

is($mh->is_pt_holiday( 2002, 11,  1), 'Dia de Todos-os-Santos');
is($mh->is_pt_holiday( 2002, 11,  2), undef);
is($mh->is_pt_holiday( 2002, 11,  3), undef);
is($mh->is_pt_holiday( 2002, 11,  4), undef);
is($mh->is_pt_holiday( 2002, 11,  5), undef);
is($mh->is_pt_holiday( 2002, 11,  6), undef);
is($mh->is_pt_holiday( 2002, 11,  7), undef);
is($mh->is_pt_holiday( 2002, 11,  8), undef);
is($mh->is_pt_holiday( 2002, 11,  9), undef);
is($mh->is_pt_holiday( 2002, 11, 10), undef);
is($mh->is_pt_holiday( 2002, 11, 11), undef);
is($mh->is_pt_holiday( 2002, 11, 12), undef);
is($mh->is_pt_holiday( 2002, 11, 13), undef);
is($mh->is_pt_holiday( 2002, 11, 14), undef);
is($mh->is_pt_holiday( 2002, 11, 15), undef);
is($mh->is_pt_holiday( 2002, 11, 16), undef);
is($mh->is_pt_holiday( 2002, 11, 17), undef);
is($mh->is_pt_holiday( 2002, 11, 18), undef);
is($mh->is_pt_holiday( 2002, 11, 19), undef);
is($mh->is_pt_holiday( 2002, 11, 20), undef);
is($mh->is_pt_holiday( 2002, 11, 21), undef);
is($mh->is_pt_holiday( 2002, 11, 22), undef);
is($mh->is_pt_holiday( 2002, 11, 23), undef);
is($mh->is_pt_holiday( 2002, 11, 24), undef);
is($mh->is_pt_holiday( 2002, 11, 25), undef);
is($mh->is_pt_holiday( 2002, 11, 26), undef);
is($mh->is_pt_holiday( 2002, 11, 27), undef);
is($mh->is_pt_holiday( 2002, 11, 28), undef);
is($mh->is_pt_holiday( 2002, 11, 29), undef);
is($mh->is_pt_holiday( 2002, 11, 30), undef);

is($mh->is_pt_holiday( 2002, 12,  1), 'Dia da Restauração da Independência');
is($mh->is_pt_holiday( 2002, 12,  2), undef);
is($mh->is_pt_holiday( 2002, 12,  3), undef);
is($mh->is_pt_holiday( 2002, 12,  4), undef);
is($mh->is_pt_holiday( 2002, 12,  5), undef);
is($mh->is_pt_holiday( 2002, 12,  6), undef);
is($mh->is_pt_holiday( 2002, 12,  7), undef);
is($mh->is_pt_holiday( 2002, 12,  8), 'Imaculada Conceição');
is($mh->is_pt_holiday( 2002, 12,  9), undef);
is($mh->is_pt_holiday( 2002, 12, 10), undef);
is($mh->is_pt_holiday( 2002, 12, 11), undef);
is($mh->is_pt_holiday( 2002, 12, 12), undef);
is($mh->is_pt_holiday( 2002, 12, 13), undef);
is($mh->is_pt_holiday( 2002, 12, 14), undef);
is($mh->is_pt_holiday( 2002, 12, 15), undef);
is($mh->is_pt_holiday( 2002, 12, 16), undef);
is($mh->is_pt_holiday( 2002, 12, 17), undef);
is($mh->is_pt_holiday( 2002, 12, 18), undef);
is($mh->is_pt_holiday( 2002, 12, 19), undef);
is($mh->is_pt_holiday( 2002, 12, 20), undef);
is($mh->is_pt_holiday( 2002, 12, 21), undef);
is($mh->is_pt_holiday( 2002, 12, 22), undef);
is($mh->is_pt_holiday( 2002, 12, 23), undef);
is($mh->is_pt_holiday( 2002, 12, 24), undef);
is($mh->is_pt_holiday( 2002, 12, 25), 'Natal');
is($mh->is_pt_holiday( 2002, 12, 26), undef);
is($mh->is_pt_holiday( 2002, 12, 27), undef);
is($mh->is_pt_holiday( 2002, 12, 28), undef);
is($mh->is_pt_holiday( 2002, 12, 29), undef);
is($mh->is_pt_holiday( 2002, 12, 30), undef);
is($mh->is_pt_holiday( 2002, 12, 31), undef);

is($mh->is_pt_holiday( 2002, 12    ), undef);
is($mh->is_pt_holiday( 2002        ), undef);
is($mh->is_pt_holiday(             ), undef);

is_deeply(
  $mh->holidays(2002),
  {
     1 => {
        1 => 'Ano Novo',
     },
     2 => {
       12 => 'Entrudo',
     },
     3 => {
       29 => 'Sexta-feira Santa',
       31 => 'Páscoa',
     },
     4 => {
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador',
       30 => 'Corpo de Deus',
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
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
