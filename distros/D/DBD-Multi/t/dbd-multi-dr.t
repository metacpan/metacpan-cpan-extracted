# vim: ft=perl
use Test::More tests => 5;
# $Id: dbd-multi-dr.t,v 1.2 2006/02/10 18:47:47 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';
can_ok 'DBD::Multi::dr', 'connect';
isa_ok DBI->connect('DBI:Multi:'), 'DBI::db';

my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:one.db'],
        2 => DBI->connect('DBI:SQLite:two.db'),
    ],
});

isa_ok $c, 'DBI::db';
cmp_ok scalar($c->data_sources), '>=', 1, "data_sources returned some";

unlink "$_.db" for qw[one two three four five six seven eight nine ten];
