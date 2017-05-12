use strict;
use warnings;
use Test::More;
use App::Prove::RunScripts;
use t::Utils qw(app_with_args);

subtest 'empty' => sub {
    my $app = app_with_args( [] );
    is_deeply $app->{before}, [], 'before option does not exist';
    is_deeply $app->{after}, [], 'after option does not exist';
};

subtest 'before' => sub {
    my $app = app_with_args( [qw(--before hello.pl)] );
    is_deeply $app->{before}, ['hello.pl'], 'before option exists';
    is_deeply $app->{after}, [], 'after option does not exist';
};

subtest 'before more' => sub {
    my $app = app_with_args( [qw(--before hello.pl --before hello2.pl)] );
    is_deeply $app->{before}, ['hello.pl', 'hello2.pl'], 'before option exists';
    is_deeply $app->{after}, [], 'after option does not exist';
};

subtest 'after' => sub {
    my $app = app_with_args( [qw(--after hello.pl --after hello2.pl)] );
    is_deeply $app->{before}, [], 'before option does not exist';
    is_deeply $app->{after}, ['hello.pl', 'hello2.pl'], 'after option exists';
};

subtest 'after more' => sub {
    my $app = app_with_args( [qw(--after hello.pl --after hello2.pl)] );
    is_deeply $app->{before}, [], 'before option does not exist';
    is_deeply $app->{after}, ['hello.pl', 'hello2.pl'], 'after option exists';
};

subtest 'before and after' => sub {
    my $app = app_with_args( [qw(--before hello1.pl --after hello2.pl)] );
    is_deeply $app->{before}, ['hello1.pl'], 'before option exists';
    is_deeply $app->{after},  ['hello2.pl'], 'after option exists';
};

done_testing;
