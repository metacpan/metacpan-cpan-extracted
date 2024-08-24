use Modern::Perl;
use open ':std', ':encoding(utf8)';
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', database_entity => 'foo', database_entities => ['bar', 'baz']) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");
ok(defined(&foo),                  'import "database_entity"');
ok(defined(&bar) && defined(&baz), 'import "database_entities"');
done_testing();
