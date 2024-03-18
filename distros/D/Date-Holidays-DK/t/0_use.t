# -*- perl -*-
use Test::More tests => 24;
use utf8;

BEGIN {
  use_ok('Date::Holidays::DK');
};

t(2002,  3, 24, "Palmesøndag");
t(2002,  3, 28, "Skærtorsdag");
t(2002,  4,  1, "2. Påskedag");
t(2002,  4, 26, "Store Bededag");
t(2002,  5,  9, "Kristi Himmelfartsdag");
t(2002,  5, 19, "Pinsedag");
t(2002,  5, 20, "2. Pinsedag");
t(2003,  4, 13, "Palmesøndag");
t(2003,  4, 18, "Langfredag");
t(2003,  4, 20, "Påskedag");
t(2003,  5, 16, "Store Bededag");
t(2003,  5, 29, "Kristi Himmelfartsdag");
t(2003,  6,  8, "Pinsedag");
t(2004,  1,  1, "Nytårsdag");
t(2004,  6,  5, "Grundlovsdag");
t(2004, 12, 25, "Juledag");
t(2004,  5, 29, undef);
t(2004,  5, 30, "Pinsedag");
t(2004,  5, 31, "2. Pinsedag");
t(2004,  6,  1, undef);
t(2024,  4, 26, undef); # "Store Bededag" not a holiday after 2023

sub t {
  my ($y, $m, $d, $n) = @_;
  is(is_dk_holiday($y, $m, $d), $n, $n || 'undef');
}

my $h;
ok($h = dk_holidays(2004), 'call dk_holidays()');

ok(eq_hash($h, {
  '0101' => "Nytårsdag",
  '0404' => "Palmesøndag",
  '0408' => "Skærtorsdag",
  '0409' => "Langfredag",
  '0411' => "Påskedag",
  '0412' => "2. Påskedag",
  '0520' => "Kristi Himmelfartsdag",
  '0530' => "Pinsedag",
  '0531' => "2. Pinsedag",
  '0605' => "Grundlovsdag",
  '1224' => "Juleaftensdag",
  '1225' => "Juledag",
  '1226' => "2. Juledag",
}), 'check return values');
