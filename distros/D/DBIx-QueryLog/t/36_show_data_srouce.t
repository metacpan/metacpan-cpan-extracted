use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;
use File::Temp qw(tempfile);
use IO::Handle;

sub test_params {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($desc, $code) = @_;

    my %params;
    local $DBIx::QueryLog::OUTPUT = sub { %params = @_ };
    $code->();

    subtest $desc => sub {
        my $expects = sprintf
            "[%s] [%s] [%s] [%s] %s at %s line %s\n",
            @params{qw/localtime pkg time data_source sql file line/};

        note $params{message};
        is $params{message}, $expects;
    };
}

my $dbh = t::Util->new_dbh;

DBIx::QueryLog->show_data_source(1);

TEST:
test_params simple => sub {
    $dbh->do('SELECT * FROM sqlite_master');
};

DBIx::QueryLog->show_data_source(0);

unless ($ENV{DBIX_QUERYLOG_SHOW_DATASOURCE}) {
    $ENV{DBIX_QUERYLOG_SHOW_DATASOURCE} = 1;
    goto TEST;
}

done_testing;
