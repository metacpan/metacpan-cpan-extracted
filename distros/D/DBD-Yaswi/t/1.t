# -*- Mode: Perl -*-

use Test::More tests => 8;
BEGIN { use_ok('DBI') };

ok($db=DBI->connect('dbi:Yaswi:user'), "connect");
ok($sth=$db->prepare('find [X] where member(X, [1,2,3])'), "prepare");
ok($sth->execute, "execute");
push @x, @a while @a=$sth->fetchrow_array;
is_deeply([@x], [1,2,3], "fetch");

ok($sth2=$db->prepare('insert foo(?)'), "prepare insert");
@values=qw(foo bar doo moz goo too);
foreach (@values) { $sth2->execute($_) }

ok($sth3=$db->prepare('find [X] where findall(T, foo(T), X)'), "prepare");
$sth3->execute;
is_deeply($sth3->fetchrow_array, \@values, "values");
