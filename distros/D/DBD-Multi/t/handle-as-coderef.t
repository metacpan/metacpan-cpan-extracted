# vim: ft=perl
use Test::More 'no_plan';
# $Id: handle-as-coderef.t,v 1.2 2010/07/16 00:12:58 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';
can_ok 'DBD::Multi::db', 'prepare';

my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:one.db', '',''],
        1 => sub { DBI->connect('DBI:SQLite:two.db') },
        2 => ['dbi:SQLite:three.db','',''],
        2 => sub { DBI->connect('DBI:SQLite:four.db') },
    ],
});

isa_ok $c, 'DBI::db';
cmp_ok scalar($c->data_sources), '==', 4, "data_sources returned some";

# one
my $sth = $c->prepare("CREATE TABLE multi(id int)");
isa_ok $sth, 'DBI::st';

# two
is $c->do("CREATE TABLE multi(id int)"), '0E0', 'do successful';

{
    local $SIG{__WARN__} = sub { };    # I don't want to hear it.
    eval { my $sth = $c->prepare("CREAATE TABLE multi(id int)"); };
    ok $@, "Syntax errror: $@";
}

$c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => sub { return undef },
        2 => ['dbi:SQLite:one.db', '',''],
    ],
});

# CPAN Ticket 58769
my $sth2 = $c->prepare("CREATE TABLE multi2(id int)");
isa_ok $sth2, 'DBI::st';
is $c->do("CREATE TABLE multi2(id int)"), '0E0', 'do successful';

unlink "$_.db" for qw[one two three four five six seven eight nine ten];

