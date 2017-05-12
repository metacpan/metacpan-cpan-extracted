# vim: ft=perl
use Test::More tests => 88;
# $Id: dbd-multi-multi.t,v 1.4 2006/02/10 18:47:47 wright Exp $
use strict;
$^W = 1;

use_ok 'DBD::Multi';

my $child_one = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:one.db', '',''],
        2 => DBI->connect('DBI:SQLite:two.db'),
        3 => ['dbi:SQLite:three.db','',''],
        4 => DBI->connect('DBI:SQLite:four.db'),
    ],
});
my $child_two = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:five.db', '',''],
        2 => DBI->connect('DBI:SQLite:six.db'),
        3 => ['dbi:SQLite:seven.db','',''],
        4 => DBI->connect('DBI:SQLite:eight.db'),
    ],
});

my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:SQLite:nine.db', '',''],
        2 => $child_one,
        3 => $child_two,
        4 => ['dbi:SQLite:ten.db', '',''],
    ],
});

isa_ok $child_one, 'DBI::db';
isa_ok $child_two, 'DBI::db';
isa_ok $c, 'DBI::db';

is $child_one->data_sources, 4, 'four data sources';
is $child_two->data_sources, 4, 'four data sources';
is $c->data_sources, 4, 'four data sources';

sub do_on_all {
    my @args = @_;
    my $i = 1;
    $c->{handler}->multi_do_all(sub {ok shift->do(@args), "$i: @args"; $i++});
#    # should be in nine, one, five, ten
#    ok $c->do(@args), "@args" for 1..4;
#    # should be in two, three, four
#    ok $child_one->do(@args), "@args" for 1..3;
#    # should be in six, seven, eight 
#    ok $child_two->do(@args), "@args" for 1..3;
}

do_on_all("CREATE TABLE multi(id int)");
do_on_all("INSERT INTO multi VALUES(?)", {}, $_) for 1..5;

for my $val ( 1 .. 5 ) {
    my $sth = $c->prepare("SELECT * FROM multi where id = ?");
    isa_ok $sth, 'DBI::st';
    ok $sth->execute($val), 'executed';
    my $hash = $sth->fetchall_hashref('id');

    is scalar(keys %{$hash}), 1, 'just one';
    is $hash->{$val}->{id}, $val, 'hash structure correct';
}

ok $c->disconnect, "Disconnected.";

unlink "$_.db" for qw[one two three four five six seven eight nine ten];

