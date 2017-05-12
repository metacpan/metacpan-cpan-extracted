use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub cv {
    my @v = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer .02, 0, sub { $cv->send(@v); undef $t };
    $cv;
}

my $repeated = cv('', 0)->while(sub {
    my ($str, $n) = @_;
    $n < 5;
}, sub {
    my ($str, $n) = @_;
    cv("$str*", $n + 1)
});

my ($str, $n) = $repeated->recv;
is $str, "*****";

done_testing;
