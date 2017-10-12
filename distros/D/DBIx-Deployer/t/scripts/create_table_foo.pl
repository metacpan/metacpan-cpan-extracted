#!/usr/bin/env perl
use Modern::Perl;
use DBI;

my $db = DBI->connect('dbi:SQLite:' . $ARGV[0]);
$db->begin_work;
$db->do('CREATE TABLE foo(a,b)');
my $result = $db->selectall_arrayref('PRAGMA table_info(foo)');
if( eval { $result->[0]->[1] eq 'a' && $result->[1]->[1] eq 'b' } ) {
    $db->commit && exit 0;
}
else {
    $db->rollback && die 'create_table_foo.pl failed';
}
