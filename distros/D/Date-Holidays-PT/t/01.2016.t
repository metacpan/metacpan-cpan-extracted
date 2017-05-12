use Test::More tests => 379;
use utf8;

BEGIN {
use_ok( 'Date::Holidays::PT' );
}

my $mh = Date::Holidays::PT->new();

is_deeply(
  $mh->holidays(2016),
  {
     1 => {
        1 => 'Ano Novo'
     },
     3 => {
       25 => 'Sexta-feira Santa',
       27 => 'Páscoa',
      },
     4 => {
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador'
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
     },
     8 => {
       15 => 'Assunção de Nossa Senhora',
     },
     10 => { },   # keep it here ,plz
     11 => { },   # keep it here ,plz
    12 => {
        8 => 'Imaculada Conceição',
       25 => 'Natal',
     },
  }
);


ok($mh->is_holiday( 2016,  3, 25));
ok($mh->is_holiday( 2016,  3, 27));


is($mh->is_pt_holiday( 2016,  1,  1), 'Ano Novo');
is($mh->is_pt_holiday( 2016,  1,  2), undef);
is($mh->is_pt_holiday( 2016,  1,  3), undef);
is($mh->is_pt_holiday( 2016,  1,  4), undef);
is($mh->is_pt_holiday( 2016,  1,  5), undef);
is($mh->is_pt_holiday( 2016,  1,  6), undef);
is($mh->is_pt_holiday( 2016,  1,  7), undef);
is($mh->is_pt_holiday( 2016,  1,  8), undef);
is($mh->is_pt_holiday( 2016,  1,  9), undef);
is($mh->is_pt_holiday( 2016,  1, 10), undef);
is($mh->is_pt_holiday( 2016,  1, 11), undef);
is($mh->is_pt_holiday( 2016,  1, 12), undef);
is($mh->is_pt_holiday( 2016,  1, 13), undef);
is($mh->is_pt_holiday( 2016,  1, 14), undef);
is($mh->is_pt_holiday( 2016,  1, 15), undef);
is($mh->is_pt_holiday( 2016,  1, 16), undef);
is($mh->is_pt_holiday( 2016,  1, 17), undef);
is($mh->is_pt_holiday( 2016,  1, 18), undef);
is($mh->is_pt_holiday( 2016,  1, 19), undef);
is($mh->is_pt_holiday( 2016,  1, 20), undef);
is($mh->is_pt_holiday( 2016,  1, 21), undef);
is($mh->is_pt_holiday( 2016,  1, 22), undef);
is($mh->is_pt_holiday( 2016,  1, 23), undef);
is($mh->is_pt_holiday( 2016,  1, 24), undef);
is($mh->is_pt_holiday( 2016,  1, 25), undef);
is($mh->is_pt_holiday( 2016,  1, 26), undef);
is($mh->is_pt_holiday( 2016,  1, 27), undef);
is($mh->is_pt_holiday( 2016,  1, 28), undef);
is($mh->is_pt_holiday( 2016,  1, 29), undef);
is($mh->is_pt_holiday( 2016,  1, 30), undef);
is($mh->is_pt_holiday( 2016,  1, 31), undef);

is($mh->is_pt_holiday( 2016,  2,  1), undef);
is($mh->is_pt_holiday( 2016,  2,  2), undef);
is($mh->is_pt_holiday( 2016,  2,  3), undef);
is($mh->is_pt_holiday( 2016,  2,  4), undef);
is($mh->is_pt_holiday( 2016,  2,  5), undef);
is($mh->is_pt_holiday( 2016,  2,  6), undef);
is($mh->is_pt_holiday( 2016,  2,  7), undef);
is($mh->is_pt_holiday( 2016,  2,  8), undef);
is($mh->is_pt_holiday( 2016,  2,  9), undef);
is($mh->is_pt_holiday( 2016,  2, 10), undef);
is($mh->is_pt_holiday( 2016,  2, 11), undef);
is($mh->is_pt_holiday( 2016,  2, 12), undef);
is($mh->is_pt_holiday( 2016,  2, 13), undef);
is($mh->is_pt_holiday( 2016,  2, 14), undef);
is($mh->is_pt_holiday( 2016,  2, 15), undef);
is($mh->is_pt_holiday( 2016,  2, 16), undef);
is($mh->is_pt_holiday( 2016,  2, 17), undef);
is($mh->is_pt_holiday( 2016,  2, 18), undef);
is($mh->is_pt_holiday( 2016,  2, 19), undef);
is($mh->is_pt_holiday( 2016,  2, 20), undef);
is($mh->is_pt_holiday( 2016,  2, 21), undef);
is($mh->is_pt_holiday( 2016,  2, 22), undef);
is($mh->is_pt_holiday( 2016,  2, 23), undef);
is($mh->is_pt_holiday( 2016,  2, 24), undef);
is($mh->is_pt_holiday( 2016,  2, 25), undef);
is($mh->is_pt_holiday( 2016,  2, 26), undef);
is($mh->is_pt_holiday( 2016,  2, 27), undef);
is($mh->is_pt_holiday( 2016,  2, 28), undef);

is($mh->is_pt_holiday( 2016,  3,  1), undef);
is($mh->is_pt_holiday( 2016,  3,  2), undef);
is($mh->is_pt_holiday( 2016,  3,  3), undef);
is($mh->is_pt_holiday( 2016,  3,  4), undef);
is($mh->is_pt_holiday( 2016,  3,  5), undef);
is($mh->is_pt_holiday( 2016,  3,  6), undef);
is($mh->is_pt_holiday( 2016,  3,  7), undef);
is($mh->is_pt_holiday( 2016,  3,  8), undef);
is($mh->is_pt_holiday( 2016,  3,  9), undef);
is($mh->is_pt_holiday( 2016,  3, 10), undef);
is($mh->is_pt_holiday( 2016,  3, 11), undef);
is($mh->is_pt_holiday( 2016,  3, 12), undef);
is($mh->is_pt_holiday( 2016,  3, 13), undef);
is($mh->is_pt_holiday( 2016,  3, 14), undef);
is($mh->is_pt_holiday( 2016,  3, 15), undef);
is($mh->is_pt_holiday( 2016,  3, 16), undef);
is($mh->is_pt_holiday( 2016,  3, 17), undef);
is($mh->is_pt_holiday( 2016,  3, 18), undef);
is($mh->is_pt_holiday( 2016,  3, 19), undef);
is($mh->is_pt_holiday( 2016,  3, 20), undef);
is($mh->is_pt_holiday( 2016,  3, 21), undef);
is($mh->is_pt_holiday( 2016,  3, 22), undef);
is($mh->is_pt_holiday( 2016,  3, 23), undef);
is($mh->is_pt_holiday( 2016,  3, 24), undef);
is($mh->is_pt_holiday( 2016,  3, 25), 'Sexta-feira Santa');
is($mh->is_pt_holiday( 2016,  3, 26), undef);
is($mh->is_pt_holiday( 2016,  3, 27), 'Páscoa');
is($mh->is_pt_holiday( 2016,  3, 28), undef);
is($mh->is_pt_holiday( 2016,  3, 29), undef);
is($mh->is_pt_holiday( 2016,  3, 30), undef);
is($mh->is_pt_holiday( 2016,  3, 31), undef);

is($mh->is_pt_holiday( 2016,  4,  1), undef);
is($mh->is_pt_holiday( 2016,  4,  2), undef);
is($mh->is_pt_holiday( 2016,  4,  3), undef);
is($mh->is_pt_holiday( 2016,  4,  4), undef);
is($mh->is_pt_holiday( 2016,  4,  5), undef);
is($mh->is_pt_holiday( 2016,  4,  6), undef);
is($mh->is_pt_holiday( 2016,  4,  7), undef);
is($mh->is_pt_holiday( 2016,  4,  8), undef);
is($mh->is_pt_holiday( 2016,  4,  9), undef);
is($mh->is_pt_holiday( 2016,  4, 10), undef);
is($mh->is_pt_holiday( 2016,  4, 11), undef);
is($mh->is_pt_holiday( 2016,  4, 12), undef);
is($mh->is_pt_holiday( 2016,  4, 13), undef);
is($mh->is_pt_holiday( 2016,  4, 14), undef);
is($mh->is_pt_holiday( 2016,  4, 15), undef);
is($mh->is_pt_holiday( 2016,  4, 16), undef);
is($mh->is_pt_holiday( 2016,  4, 17), undef);
is($mh->is_pt_holiday( 2016,  4, 18), undef);
is($mh->is_pt_holiday( 2016,  4, 19), undef);
is($mh->is_pt_holiday( 2016,  4, 20), undef);
is($mh->is_pt_holiday( 2016,  4, 21), undef);
is($mh->is_pt_holiday( 2016,  4, 22), undef);
is($mh->is_pt_holiday( 2016,  4, 23), undef);
is($mh->is_pt_holiday( 2016,  4, 24), undef);
is($mh->is_pt_holiday( 2016,  4, 25), 'Dia da Liberdade');
is($mh->is_pt_holiday( 2016,  4, 26), undef);
is($mh->is_pt_holiday( 2016,  4, 27), undef);
is($mh->is_pt_holiday( 2016,  4, 28), undef);
is($mh->is_pt_holiday( 2016,  4, 29), undef);
is($mh->is_pt_holiday( 2016,  4, 30), undef);

is($mh->is_pt_holiday( 2016,  5,  1), 'Dia do Trabalhador');
is($mh->is_pt_holiday( 2016,  5,  2), undef);
is($mh->is_pt_holiday( 2016,  5,  3), undef);
is($mh->is_pt_holiday( 2016,  5,  4), undef);
is($mh->is_pt_holiday( 2016,  5,  5), undef);
is($mh->is_pt_holiday( 2016,  5,  6), undef);
is($mh->is_pt_holiday( 2016,  5,  7), undef);
is($mh->is_pt_holiday( 2016,  5,  8), undef);
is($mh->is_pt_holiday( 2016,  5,  9), undef);
is($mh->is_pt_holiday( 2016,  5, 10), undef);
is($mh->is_pt_holiday( 2016,  5, 11), undef);
is($mh->is_pt_holiday( 2016,  5, 12), undef);
is($mh->is_pt_holiday( 2016,  5, 13), undef);
is($mh->is_pt_holiday( 2016,  5, 14), undef);
is($mh->is_pt_holiday( 2016,  5, 15), undef);
is($mh->is_pt_holiday( 2016,  5, 16), undef);
is($mh->is_pt_holiday( 2016,  5, 17), undef);
is($mh->is_pt_holiday( 2016,  5, 18), undef);
is($mh->is_pt_holiday( 2016,  5, 19), undef);
is($mh->is_pt_holiday( 2016,  5, 20), undef);
is($mh->is_pt_holiday( 2016,  5, 21), undef);
is($mh->is_pt_holiday( 2016,  5, 22), undef);
is($mh->is_pt_holiday( 2016,  5, 23), undef);
is($mh->is_pt_holiday( 2016,  5, 24), undef);
is($mh->is_pt_holiday( 2016,  5, 25), undef);
is($mh->is_pt_holiday( 2016,  5, 26), undef);
is($mh->is_pt_holiday( 2016,  5, 27), undef);
is($mh->is_pt_holiday( 2016,  5, 28), undef);
is($mh->is_pt_holiday( 2016,  5, 29), undef);
is($mh->is_pt_holiday( 2016,  5, 30), undef);
is($mh->is_pt_holiday( 2016,  5, 31), undef);

is($mh->is_pt_holiday( 2016,  6,  1), undef);
is($mh->is_pt_holiday( 2016,  6,  2), undef);
is($mh->is_pt_holiday( 2016,  6,  3), undef);
is($mh->is_pt_holiday( 2016,  6,  4), undef);
is($mh->is_pt_holiday( 2016,  6,  5), undef);
is($mh->is_pt_holiday( 2016,  6,  6), undef);
is($mh->is_pt_holiday( 2016,  6,  7), undef);
is($mh->is_pt_holiday( 2016,  6,  8), undef);
is($mh->is_pt_holiday( 2016,  6,  9), undef);
is($mh->is_pt_holiday( 2016,  6, 10), 'Dia de Portugal, de Camões e das Comunidades');
is($mh->is_pt_holiday( 2016,  6, 11), undef);
is($mh->is_pt_holiday( 2016,  6, 12), undef);
is($mh->is_pt_holiday( 2016,  6, 13), undef);
is($mh->is_pt_holiday( 2016,  6, 14), undef);
is($mh->is_pt_holiday( 2016,  6, 15), undef);
is($mh->is_pt_holiday( 2016,  6, 16), undef);
is($mh->is_pt_holiday( 2016,  6, 17), undef);
is($mh->is_pt_holiday( 2016,  6, 18), undef);
is($mh->is_pt_holiday( 2016,  6, 19), undef);
is($mh->is_pt_holiday( 2016,  6, 20), undef);
is($mh->is_pt_holiday( 2016,  6, 21), undef);
is($mh->is_pt_holiday( 2016,  6, 22), undef);
is($mh->is_pt_holiday( 2016,  6, 23), undef);
is($mh->is_pt_holiday( 2016,  6, 24), undef);
is($mh->is_pt_holiday( 2016,  6, 25), undef);
is($mh->is_pt_holiday( 2016,  6, 26), undef);
is($mh->is_pt_holiday( 2016,  6, 27), undef);
is($mh->is_pt_holiday( 2016,  6, 28), undef);
is($mh->is_pt_holiday( 2016,  6, 29), undef);
is($mh->is_pt_holiday( 2016,  6, 30), undef);

is($mh->is_pt_holiday( 2016,  7,  1), undef);
is($mh->is_pt_holiday( 2016,  7,  2), undef);
is($mh->is_pt_holiday( 2016,  7,  3), undef);
is($mh->is_pt_holiday( 2016,  7,  4), undef);
is($mh->is_pt_holiday( 2016,  7,  5), undef);
is($mh->is_pt_holiday( 2016,  7,  6), undef);
is($mh->is_pt_holiday( 2016,  7,  7), undef);
is($mh->is_pt_holiday( 2016,  7,  8), undef);
is($mh->is_pt_holiday( 2016,  7,  9), undef);
is($mh->is_pt_holiday( 2016,  7, 10), undef);
is($mh->is_pt_holiday( 2016,  7, 11), undef);
is($mh->is_pt_holiday( 2016,  7, 12), undef);
is($mh->is_pt_holiday( 2016,  7, 13), undef);
is($mh->is_pt_holiday( 2016,  7, 14), undef);
is($mh->is_pt_holiday( 2016,  7, 15), undef);
is($mh->is_pt_holiday( 2016,  7, 16), undef);
is($mh->is_pt_holiday( 2016,  7, 17), undef);
is($mh->is_pt_holiday( 2016,  7, 18), undef);
is($mh->is_pt_holiday( 2016,  7, 19), undef);
is($mh->is_pt_holiday( 2016,  7, 20), undef);
is($mh->is_pt_holiday( 2016,  7, 21), undef);
is($mh->is_pt_holiday( 2016,  7, 22), undef);
is($mh->is_pt_holiday( 2016,  7, 23), undef);
is($mh->is_pt_holiday( 2016,  7, 24), undef);
is($mh->is_pt_holiday( 2016,  7, 25), undef);
is($mh->is_pt_holiday( 2016,  7, 26), undef);
is($mh->is_pt_holiday( 2016,  7, 27), undef);
is($mh->is_pt_holiday( 2016,  7, 28), undef);
is($mh->is_pt_holiday( 2016,  7, 29), undef);
is($mh->is_pt_holiday( 2016,  7, 30), undef);
is($mh->is_pt_holiday( 2016,  7, 31), undef);

is($mh->is_pt_holiday( 2016,  8,  1), undef);
is($mh->is_pt_holiday( 2016,  8,  2), undef);
is($mh->is_pt_holiday( 2016,  8,  3), undef);
is($mh->is_pt_holiday( 2016,  8,  4), undef);
is($mh->is_pt_holiday( 2016,  8,  5), undef);
is($mh->is_pt_holiday( 2016,  8,  6), undef);
is($mh->is_pt_holiday( 2016,  8,  7), undef);
is($mh->is_pt_holiday( 2016,  8,  8), undef);
is($mh->is_pt_holiday( 2016,  8,  9), undef);
is($mh->is_pt_holiday( 2016,  8, 10), undef);
is($mh->is_pt_holiday( 2016,  8, 11), undef);
is($mh->is_pt_holiday( 2016,  8, 12), undef);
is($mh->is_pt_holiday( 2016,  8, 13), undef);
is($mh->is_pt_holiday( 2016,  8, 14), undef);
is($mh->is_pt_holiday( 2016,  8, 15), 'Assunção de Nossa Senhora');
is($mh->is_pt_holiday( 2016,  8, 16), undef);
is($mh->is_pt_holiday( 2016,  8, 17), undef);
is($mh->is_pt_holiday( 2016,  8, 18), undef);
is($mh->is_pt_holiday( 2016,  8, 19), undef);
is($mh->is_pt_holiday( 2016,  8, 20), undef);
is($mh->is_pt_holiday( 2016,  8, 21), undef);
is($mh->is_pt_holiday( 2016,  8, 22), undef);
is($mh->is_pt_holiday( 2016,  8, 23), undef);
is($mh->is_pt_holiday( 2016,  8, 24), undef);
is($mh->is_pt_holiday( 2016,  8, 25), undef);
is($mh->is_pt_holiday( 2016,  8, 26), undef);
is($mh->is_pt_holiday( 2016,  8, 27), undef);
is($mh->is_pt_holiday( 2016,  8, 28), undef);
is($mh->is_pt_holiday( 2016,  8, 29), undef);
is($mh->is_pt_holiday( 2016,  8, 30), undef);
is($mh->is_pt_holiday( 2016,  8, 31), undef);

is($mh->is_pt_holiday( 2016,  9,  1), undef);
is($mh->is_pt_holiday( 2016,  9,  2), undef);
is($mh->is_pt_holiday( 2016,  9,  3), undef);
is($mh->is_pt_holiday( 2016,  9,  4), undef);
is($mh->is_pt_holiday( 2016,  9,  5), undef);
is($mh->is_pt_holiday( 2016,  9,  6), undef);
is($mh->is_pt_holiday( 2016,  9,  7), undef);
is($mh->is_pt_holiday( 2016,  9,  8), undef);
is($mh->is_pt_holiday( 2016,  9,  9), undef);
is($mh->is_pt_holiday( 2016,  9, 10), undef);
is($mh->is_pt_holiday( 2016,  9, 11), undef);
is($mh->is_pt_holiday( 2016,  9, 12), undef);
is($mh->is_pt_holiday( 2016,  9, 13), undef);
is($mh->is_pt_holiday( 2016,  9, 14), undef);
is($mh->is_pt_holiday( 2016,  9, 15), undef);
is($mh->is_pt_holiday( 2016,  9, 16), undef);
is($mh->is_pt_holiday( 2016,  9, 17), undef);
is($mh->is_pt_holiday( 2016,  9, 18), undef);
is($mh->is_pt_holiday( 2016,  9, 19), undef);
is($mh->is_pt_holiday( 2016,  9, 20), undef);
is($mh->is_pt_holiday( 2016,  9, 21), undef);
is($mh->is_pt_holiday( 2016,  9, 22), undef);
is($mh->is_pt_holiday( 2016,  9, 23), undef);
is($mh->is_pt_holiday( 2016,  9, 24), undef);
is($mh->is_pt_holiday( 2016,  9, 25), undef);
is($mh->is_pt_holiday( 2016,  9, 26), undef);
is($mh->is_pt_holiday( 2016,  9, 27), undef);
is($mh->is_pt_holiday( 2016,  9, 28), undef);
is($mh->is_pt_holiday( 2016,  9, 29), undef);
is($mh->is_pt_holiday( 2016,  9, 30), undef);

is($mh->is_pt_holiday( 2016, 10,  1), undef);
is($mh->is_pt_holiday( 2016, 10,  2), undef);
is($mh->is_pt_holiday( 2016, 10,  3), undef);
is($mh->is_pt_holiday( 2016, 10,  4), undef);
is($mh->is_pt_holiday( 2016, 10,  5), undef);
is($mh->is_pt_holiday( 2016, 10,  6), undef);
is($mh->is_pt_holiday( 2016, 10,  7), undef);
is($mh->is_pt_holiday( 2016, 10,  8), undef);
is($mh->is_pt_holiday( 2016, 10,  9), undef);
is($mh->is_pt_holiday( 2016, 10, 10), undef);
is($mh->is_pt_holiday( 2016, 10, 11), undef);
is($mh->is_pt_holiday( 2016, 10, 12), undef);
is($mh->is_pt_holiday( 2016, 10, 13), undef);
is($mh->is_pt_holiday( 2016, 10, 14), undef);
is($mh->is_pt_holiday( 2016, 10, 15), undef);
is($mh->is_pt_holiday( 2016, 10, 16), undef);
is($mh->is_pt_holiday( 2016, 10, 17), undef);
is($mh->is_pt_holiday( 2016, 10, 18), undef);
is($mh->is_pt_holiday( 2016, 10, 19), undef);
is($mh->is_pt_holiday( 2016, 10, 20), undef);
is($mh->is_pt_holiday( 2016, 10, 21), undef);
is($mh->is_pt_holiday( 2016, 10, 22), undef);
is($mh->is_pt_holiday( 2016, 10, 23), undef);
is($mh->is_pt_holiday( 2016, 10, 24), undef);
is($mh->is_pt_holiday( 2016, 10, 25), undef);
is($mh->is_pt_holiday( 2016, 10, 26), undef);
is($mh->is_pt_holiday( 2016, 10, 27), undef);
is($mh->is_pt_holiday( 2016, 10, 28), undef);
is($mh->is_pt_holiday( 2016, 10, 29), undef);
is($mh->is_pt_holiday( 2016, 10, 30), undef);
is($mh->is_pt_holiday( 2016, 10, 31), undef);

is($mh->is_pt_holiday( 2016, 11,  1), undef);
is($mh->is_pt_holiday( 2016, 11,  2), undef);
is($mh->is_pt_holiday( 2016, 11,  3), undef);
is($mh->is_pt_holiday( 2016, 11,  4), undef);
is($mh->is_pt_holiday( 2016, 11,  5), undef);
is($mh->is_pt_holiday( 2016, 11,  6), undef);
is($mh->is_pt_holiday( 2016, 11,  7), undef);
is($mh->is_pt_holiday( 2016, 11,  8), undef);
is($mh->is_pt_holiday( 2016, 11,  9), undef);
is($mh->is_pt_holiday( 2016, 11, 10), undef);
is($mh->is_pt_holiday( 2016, 11, 11), undef);
is($mh->is_pt_holiday( 2016, 11, 12), undef);
is($mh->is_pt_holiday( 2016, 11, 13), undef);
is($mh->is_pt_holiday( 2016, 11, 14), undef);
is($mh->is_pt_holiday( 2016, 11, 15), undef);
is($mh->is_pt_holiday( 2016, 11, 16), undef);
is($mh->is_pt_holiday( 2016, 11, 17), undef);
is($mh->is_pt_holiday( 2016, 11, 18), undef);
is($mh->is_pt_holiday( 2016, 11, 19), undef);
is($mh->is_pt_holiday( 2016, 11, 20), undef);
is($mh->is_pt_holiday( 2016, 11, 21), undef);
is($mh->is_pt_holiday( 2016, 11, 22), undef);
is($mh->is_pt_holiday( 2016, 11, 23), undef);
is($mh->is_pt_holiday( 2016, 11, 24), undef);
is($mh->is_pt_holiday( 2016, 11, 25), undef);
is($mh->is_pt_holiday( 2016, 11, 26), undef);
is($mh->is_pt_holiday( 2016, 11, 27), undef);
is($mh->is_pt_holiday( 2016, 11, 28), undef);
is($mh->is_pt_holiday( 2016, 11, 29), undef);
is($mh->is_pt_holiday( 2016, 11, 30), undef);

is($mh->is_pt_holiday( 2016, 12,  1), undef);
is($mh->is_pt_holiday( 2016, 12,  2), undef);
is($mh->is_pt_holiday( 2016, 12,  3), undef);
is($mh->is_pt_holiday( 2016, 12,  4), undef);
is($mh->is_pt_holiday( 2016, 12,  5), undef);
is($mh->is_pt_holiday( 2016, 12,  6), undef);
is($mh->is_pt_holiday( 2016, 12,  7), undef);
is($mh->is_pt_holiday( 2016, 12,  8), 'Imaculada Conceição');
is($mh->is_pt_holiday( 2016, 12,  9), undef);
is($mh->is_pt_holiday( 2016, 12, 10), undef);
is($mh->is_pt_holiday( 2016, 12, 11), undef);
is($mh->is_pt_holiday( 2016, 12, 12), undef);
is($mh->is_pt_holiday( 2016, 12, 13), undef);
is($mh->is_pt_holiday( 2016, 12, 14), undef);
is($mh->is_pt_holiday( 2016, 12, 15), undef);
is($mh->is_pt_holiday( 2016, 12, 16), undef);
is($mh->is_pt_holiday( 2016, 12, 17), undef);
is($mh->is_pt_holiday( 2016, 12, 18), undef);
is($mh->is_pt_holiday( 2016, 12, 19), undef);
is($mh->is_pt_holiday( 2016, 12, 20), undef);
is($mh->is_pt_holiday( 2016, 12, 21), undef);
is($mh->is_pt_holiday( 2016, 12, 22), undef);
is($mh->is_pt_holiday( 2016, 12, 23), undef);
is($mh->is_pt_holiday( 2016, 12, 24), undef);
is($mh->is_pt_holiday( 2016, 12, 25), 'Natal');
is($mh->is_pt_holiday( 2016, 12, 26), undef);
is($mh->is_pt_holiday( 2016, 12, 27), undef);
is($mh->is_pt_holiday( 2016, 12, 28), undef);
is($mh->is_pt_holiday( 2016, 12, 29), undef);
is($mh->is_pt_holiday( 2016, 12, 30), undef);
is($mh->is_pt_holiday( 2016, 12, 31), undef);

ok($mh->is_holiday( 2016,  3, 25));
ok($mh->is_holiday( 2016,  3, 27));

is($mh->is_pt_holiday( 2016, 12    ), undef);
is($mh->is_pt_holiday( 2016        ), undef);
is($mh->is_pt_holiday(             ), undef);

is($mh->is_pt_holiday( 2016,  2, 24), undef);
is($mh->is_pt_holiday( 2016,  3, 25), 'Sexta-feira Santa');
is($mh->is_pt_holiday( 2016,  3, 27), 'Páscoa');
is($mh->is_pt_holiday( 2016,  6, 10), 'Dia de Portugal, de Camões e das Comunidades');

is_deeply(
  $mh->holidays(2016),
  {
     1 => {
        1 => 'Ano Novo'
     },
     3 => {
       25 => 'Sexta-feira Santa',
       27 => 'Páscoa',      
     },
     4 => {
       25 => 'Dia da Liberdade',
     },
     5 => {
        1 => 'Dia do Trabalhador'
     },
     6 => {
       10 => 'Dia de Portugal, de Camões e das Comunidades',
     },
     8 => {
       15 => 'Assunção de Nossa Senhora',
     },
     10 => {}, # keep it here
     11 => {}, # keep it here
    12 => {
        8 => 'Imaculada Conceição',
       25 => 'Natal',
     },
  }
);
