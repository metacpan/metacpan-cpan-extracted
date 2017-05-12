package t::query;
use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_deeply isa);
use Exporter qw(import);

our @EXPORT = qw();
our @TESTS = qw(
    select_one select_row select_all txn
);

{
    no warnings 'redefine';
    sub import {
        my $class = shift;

        my $pkg = caller;
        $pkg->add_testinfo($_, test => 'no_plan') for @TESTS;
        push @EXPORT, @TESTS;

        @_ = ($class, @_);
        goto \&Exporter::import;
    }
}

sub select_one {
    my $db = shift->handler;
    ok $db;
    is $db->select_one('SELECT :a + :b', { a => 1, b => 2 }), 3;
}

sub select_row {
    my $db = shift->handler;
    cmp_deeply
        $db->select_row('SELECT :a + :b AS c', { a => 1, b => 2 }),
        { c => 3 };
}

sub select_all {
    my $db = shift->handler;
    cmp_deeply
        $db->select_all('SELECT :a + :b AS c', { a => 1, b => 2 }),
        [ { c => 3 } ];
}

sub txn {
    my $db = shift->handler;

    ok !$db->in_txn;
    $db->txn(sub {
        my $dbh = shift;
        ok $dbh->in_txn;
        isa $dbh, 'DBIx::Handler::Sunny';
    });

    local $@;
    eval {
        $db->txn(sub {
            my $dbh = shift;
            $dbh->query(
                q(INSERT INTO query_test (name) VALUES ('sunnykun'))
            );
            die 'rollback!';
        });
    };

    like $@, qr/\Arollback!/;
    ok !$db->select_one(q(SELECT 1 FROM query_test WHERE name = 'sunnykun'));
}

1;
__END__
