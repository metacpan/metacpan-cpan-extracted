use strict;
use warnings;
use Test::More;

eval { require DBI; require DBD::D1 };
plan skip_all => "DBI or DBD::D1 not available: $@" if $@;
plan tests => 4;

# RaiseError=>0, PrintError=>0 — errors must be silent
my $dbh = DBI->connect(
    'dbi:D1:database_id=abc', undef, 'tok',
    { RaiseError => 0, PrintError => 0 }
);
is($dbh, undef, 'missing account_id returns undef');
like($DBI::errstr, qr/account_id/, 'error mentions account_id');

$dbh = DBI->connect(
    'dbi:D1:account_id=abc', undef, 'tok',
    { RaiseError => 0, PrintError => 0 }
);
is($dbh, undef, 'missing database_id returns undef');
like($DBI::errstr, qr/database_id/, 'error mentions database_id');
