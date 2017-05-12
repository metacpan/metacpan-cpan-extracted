#!perl

use 5.010;
use strict;
use warnings;

use Data::Transmute qw(transmute_array transmute_hash);
#use Test::Exception;
use Test::More 0.98;

sub test_transmute {
    my $which = shift;
    my %args = @_;

    subtest $args{name} => sub {
        eval {
            if ($which eq 'hash') {
                transmute_hash (data => $args{data}, rules => $args{rules});
            } else {
                transmute_array(data => $args{data}, rules => $args{rules});
            }
        };

        if ($args{dies}) {
            ok($@, "dies");
            return;
        } else {
            ok(!$@, "doesn't die") or diag $@;
        }

        if (exists $args{result}) {
            is_deeply($args{data}, $args{result}, "result")
                or diag explain $args{data};
        }
    };
}

sub test_transmute_array {
    test_transmute('array', @_);
}

sub test_transmute_hash {
    test_transmute('hash', @_);
}

subtest transmute_array => sub {
    # not yet implemented
    ok 1;
};

subtest transmute_hash => sub {
    test_transmute_hash(
        name   => "missing data -> dies",
        rules  => [],
        dies   => 1,
    );
    test_transmute_hash(
        name   => "data not hash -> dies",
        data   => 1,
        rules  => [],
        dies   => 1,
    );
    test_transmute_hash(
        name   => "missing rules -> dies",
        data   => {},
        dies   => 1,
    );
    test_transmute_hash(
        name   => "unknown rule -> dies",
        data   => {},
        rules  => [ ['foo'=>{}] ],
        dies   => 1,
    );
    test_transmute_hash(
        name   => "empty rules -> noop",
        data   => {foo=>1},
        rules  => [],
        result => {foo=>1},
    );
    test_transmute_hash(
        name   => "composite rules",
        data   => {foo=>1},
        rules  => [
            [rename_key => {from=>'foo', to=>'bar'}],
            [rename_key => {from=>'bar', to=>'baz'}],
            [create_key => {name=>'foo', value=>10}],
        ],
        result => {foo=>10, baz=>1},
    );

    subtest create_key => sub {
        test_transmute_hash(
            name   => "create bar",
            data   => {foo=>1},
            rules  => [ [create_key=>{name=>'bar', value=>2}] ],
            result => {foo=>1, bar=>2},
        );
        test_transmute_hash(
            name   => "foo already exists -> dies",
            data   => {foo=>1},
            rules  => [ [create_key=>{name=>'foo', value=>2}] ],
            dies   => 1,
        );
        test_transmute_hash(
            name   => "foo already exists + ignore -> noop",
            data   => {foo=>1},
            rules  => [ [create_key=>{name=>'foo', value=>2, ignore=>1}] ],
            result => {foo=>1},
        );
        test_transmute_hash(
            name   => "foo already exists + replace -> replaced",
            data   => {foo=>1},
            rules  => [ [create_key=>{name=>'foo', value=>2, replace=>1}] ],
            result => {foo=>2},
        );
        # XXX test conflict between ignore & replace
    };

    subtest rename_key => sub {
        test_transmute_hash(
            name   => "rename foo",
            data   => {foo=>1},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar'}] ],
            result => {bar=>1},
        );
        test_transmute_hash(
            name   => "foo doesn't exist -> dies",
            data   => {baz=>1},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_hash(
            name   => "foo doesn't exist + ignore_missing_from -> noop",
            data   => {baz=>1},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar', ignore_missing_from=>1}] ],
            result => {baz=>1},
        );
        test_transmute_hash(
            name   => "bar exists -> dies",
            data   => {foo=>1, bar=>1},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_hash(
            name   => "bar exists + ignore_existing_target -> noop",
            data   => {foo=>1, bar=>2},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar', ignore_existing_target=>1}] ],
            result => {foo=>1, bar=>2},
        );
        test_transmute_hash(
            name   => "bar exists + replace -> replaced",
            data   => {foo=>1, bar=>2},
            rules  => [ [rename_key=>{from=>'foo', to=>'bar', replace=>1}] ],
            result => {bar=>1},
        );
    };

    subtest delete_key => sub {
        test_transmute_hash(
            name   => "delete foo",
            data   => {foo=>1},
            rules  => [ [delete_key=>{name=>'foo'}] ],
            result => {},
        );
        test_transmute_hash(
            name   => "foo doesn't exist -> noop",
            data   => {bar=>1},
            rules  => [ [delete_key=>{name=>'foo'}] ],
            result => {bar=>1},
        );
    };
};

DONE_TESTING:
done_testing;
