use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::Tracer;

my $dbh = t::Util->new_dbh;

my @logs = do {
    my @logs;
    my $tracer = DBIx::Tracer->new(sub {
        my %args = @_;
        push @logs, \%args;
    });
    $dbh->do('SELECT * FROM sqlite_master');
    @logs;
};

like $logs[0]->{sql}, qr/SELECT \* FROM sqlite_master/, 'SQL';

done_testing;
