# vim: ft=perl
use Test::More tests => 42;
# $Id: dbd-multi-st.t,v 1.3 2006/02/10 18:47:47 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';
can_ok 'DBD::Multi::st', 'execute', 'rows';

my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:one.db', '',''],
        1 => DBI->connect('DBI:SQLite:two.db'),
        2 => ['dbi:SQLite:three.db','',''],
        3 => DBI->connect('DBI:SQLite:four.db'),
    ],
});

isa_ok $c, 'DBI::db';

my $handler = $c->{handler};
isa_ok $handler, 'DBD::Multi::Handler';

$handler->multi_do_all(sub {
    my $dbh = shift;
    is $dbh->do("CREATE TABLE multi(id int)"), '0E0', 'do create successful';
});

$handler->multi_do_all(sub {
    my $dbh = shift;
    is($dbh->do("INSERT INTO multi VALUES($_)"), 1, 'insert via do works')
      for 1..4;
});

$handler->multi_do_all(sub {
    my $dbh = shift;
    my $sth = $dbh->prepare("INSERT INTO multi VALUES(?)");
    isa_ok $sth, 'DBI::st';
    is($sth->execute($_), 1, 'insert via prepare/execute works') for 5..6;
});

my $sth = $c->prepare("SELECT * FROM multi");
isa_ok $sth, 'DBI::st';

    use Data::Dumper;
is $sth->execute, '0E0', 'executed select';

my $all_arrayref = $sth->fetchall_arrayref;
is scalar(@{$all_arrayref}), 6, 'six records returned';

is $sth->execute, '0E0', 'executed select';
my $all_hashref = $sth->fetchall_hashref('id');
is scalar(keys %{$all_hashref}), 6, 'six records returned';

is $sth->finish, 1, 'finished';

unlink "$_.db" for qw[one two three four five six seven eight nine ten];
