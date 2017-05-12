use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Data::Monad::Base::Sugar;
use Test::More;

sub cv {
    my @v = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer .02, 0 => sub { $cv->(@v); undef $t };
    return $cv;
}

is Data::Monad::Base::Sugar::for {
    pick \my $x => sub { cv 10 / 2 };
    pick \my $y => sub { cv_unit($x + 1) };
    pick \my $z => sub { cv_unit($x - 1) };
    pick sub { cv_unit($y * $z) };
}->recv, 24;

is_deeply [Data::Monad::Base::Sugar::for {
    pick \my @x => sub { cv 1, 2, 3 };
    pick \my @y => sub { cv map {$_ + 1} @x };
    pick \my @z => sub { cv map {$_ - 1} @x };
    yield { @y, @z };
}->recv], [2, 3, 4, 0, 1, 2];

is Data::Monad::Base::Sugar::for {
    pick \my $x => sub { cv 10 / 2 };
    let \my $m => sub { cv_unit($x + 1) };
    pick \my $y => sub { $m };
    pick \my $z => sub { cv_unit($x - 1) };
    pick sub { cv_unit($y * $z) };
}->recv, 24;

done_testing;
