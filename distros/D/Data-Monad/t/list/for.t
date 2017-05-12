use strict;
use warnings;
use Data::Monad::List;
use Data::Monad::Base::Sugar;
use Test::More;

ok eq_array([Data::Monad::Base::Sugar::for {
    pick \my $x => sub { scalar_list(2, 4) };
    pick \my $y => sub { scalar_list($x + 1) };
    pick \my $z => sub { scalar_list($x - 1) };
    yield { $y * $z };
}->scalars], [3, 15]);

ok eq_set([Data::Monad::Base::Sugar::for {
    pick \my $x => sub { scalar_list(1, 2) };
    pick \my $y => sub { scalar_list(3, 4, 5) };
    yield { "$x-$y" };
}->scalars], ["1-3", "2-3", "1-4", "2-4", "1-5", "2-5"]);

ok eq_set([Data::Monad::Base::Sugar::for {
    pick \my $x => sub { scalar_list(1, 2) };
    pick \my $y => sub { scalar_list(3, 4, 5) };
    satisfy { ($x + $y) % 2 == 0 };
    yield { "$x-$y" };
}->scalars], ["1-3", "2-4", "1-5"]);

ok eq_set([Data::Monad::Base::Sugar::for {
    let \my $m1 => sub { scalar_list(1, 2) };
    pick \my $x => sub { $m1 };
    let \my $m2 => sub { scalar_list($x, $x + 1, $x + 2) };
    let \my $m3 => sub { scalar_list('dummy') };
    pick \my $y => sub { $m2 };
    let \my $m4 => sub { scalar_list("dummy2") };
    satisfy { ($x + $y) % 2 == 0 };
    let \my $m5 => sub { scalar_list("$x-$y") };
    satisfy { $y <= 3 };
    pick \my $result => sub { $m5 };
    yield { $result };
}->scalars], ["1-1", "1-3", "2-2"]);


done_testing;
