use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub say_hello($) {
    my $success = shift;
    my $failure = 0;
    sub {
        my $name = shift;
        ++$failure < $success ? cv_fail : cv_unit "Hello, $name";
    };
}

subtest basic => sub {
    ok cv_unit("Gaishi Takeuchi")->retry(3, say_hello 2)->recv;
    ok cv_unit("Gaishi Takeuchi")->retry(3, say_hello 3)->recv;
    eval { cv_unit("Gaishi Takeuchi")->retry(3, say_hello 4)->recv };
    ok $@;
};

subtest pace => sub {
    my $go;
    cv_unit->sleep(.04)->map(sub { $go++ });
    is cv_unit->retry(3, .02, sub { $go ? cv_unit "OK" : cv_fail })->recv, 
       "OK";
};

done_testing;
