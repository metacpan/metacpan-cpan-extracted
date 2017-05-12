use strict;
use warnings;
use Test::Requires { 'DBD::SQLite' => 1.48 };
use Test::More;
use t::Util;
use DBIx::Tracer ();

my $dbh = t::Util->new_dbh;

my @logs;

subtest 'enabled' => sub {
    my $tracer = DBIx::Tracer->new(sub {
        my %args = @_;
        push @logs, \%args;
    });
    $dbh->do('SELECT * FROM sqlite_master');
    is(0+@logs, 1);
};

subtest 'disabled' => sub {
    $dbh->do('SELECT * FROM sqlite_master');
    is(0+@logs, 1, 'not logged.');
};

done_testing;
