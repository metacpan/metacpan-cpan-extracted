use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;

subtest 'no-rebase-on-empty-path' => sub {
    my $rebase_rule_called = 0;
    my $errors = validator({})->rebase('/a' => sub {
        $rebase_rule_called = 1;
    })->errors;
    is_deeply $errors, [], "no errors";
    is $rebase_rule_called, 0, "no rebase rule has been called";
};

subtest 'rebase-simple' => sub {
    my $data = [
        {
            a => {
                b => [1],
                c => {
                    dd => { v1 => 2 },
                    ee => [ 3, 4 ],
                }
            },
        },
        {
            zz => [6],
        }
    ];
    my @visited_bases;
    my $errors = validator($data)->rebase('/*/*[key eq "a"]' => sub {
        my $v = shift;
        push @visited_bases, $v->current_base;
        $v->(
            on      => '/b/0',
            should  => sub {
                push @visited_bases, "/0/a/b/0";
                $_[0] == 1;
            },
            because => '...r1...',
        );
        $v->rebase('/c' => sub {
            my $v = shift;
            push @visited_bases, $v->current_base;
            $v->(
                on      => '/dd/v1',
                should  => sub {
                    push @visited_bases, "/0/a/c/dd/v1";
                    $_[0] == 2;
                },
                because => '...r2...',
            )->(
                on      => '/ee/*',
                should  => sub {
                    push @visited_bases, "/0/a/c/ee";
                    @_ == 2 && $_[0] == 3 && $_[1] == 4;
                },
                because => '...r3..',
            )->(
                on      => '//1/zz/*',
                should  => sub {
                    push @visited_bases, "/1/zz/1";
                    $_[0] == 6;
                },
                because => '...r5...',
            );
        });
    })->(
        on      => '/1/zz/*',
        should  => sub {
            push @visited_bases, "/1/zz/1";
            $_[0] == 6;
        },
        because => '...r4...',
    )->errors;
    is_deeply $errors, [], "no errors";

    # we have hash, so, walking order can be undertermined
    @visited_bases = sort @visited_bases;
    is_deeply \@visited_bases, [
        "/0/a",
        "/0/a/b/0",
        "/0/a/c",
        "/0/a/c/dd/v1",
        "/0/a/c/ee",
        "/1/zz/1",
        "/1/zz/1",
    ], "visited routes with rebasing are correct";
};

done_testing;
