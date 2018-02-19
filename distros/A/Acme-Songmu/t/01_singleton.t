use strict;
use warnings;
use utf8;
use Test::More;
use Acme::Songmu;

subtest singleton => sub {
    my $songmu = Acme::Songmu->instance;
    my $songmu2 = Acme::Songmu->instance;

    is $songmu.q(), $songmu2.q(), 'singleton ok';
};

subtest name => sub {
    is(Acme::Songmu->instance->name, 'Masayuki Matsuki');
};

done_testing;
