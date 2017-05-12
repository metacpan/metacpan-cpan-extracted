# vim: ft=perl
use Test::More tests => 7;
# $Id: dbd-multi-db.t,v 1.3 2006/02/10 18:47:47 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';
can_ok 'DBD::Multi::db', 'prepare';

my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:one.db', '',''],
        1 => DBI->connect('DBI:SQLite:two.db'),
        2 => ['dbi:SQLite:three.db','',''],
        2 => DBI->connect('DBI:SQLite:four.db'),
    ],
});

isa_ok $c, 'DBI::db';
cmp_ok scalar($c->data_sources), '==', 4, "data_sources returned some";

# one
my $sth = $c->prepare("CREATE TABLE multi(id int)");
isa_ok $sth, 'DBI::st';

# two
is $c->do("CREATE TABLE multi(id int)"), '0E0', 'do successful';

$SIG{__WARN__} = sub {}; # I don't want to hear it.
eval {
    my $sth = $c->prepare("CREAATE TABLE multi(id int)");
};
ok $@, "$@";

unlink "$_.db" for qw[one two three four five six seven eight nine ten];
