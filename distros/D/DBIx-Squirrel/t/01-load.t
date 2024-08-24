use Modern::Perl;
use open ':std', ':encoding(utf8)';
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', ':utils', ':sql_types') || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");
ok(defined(&neat)     && defined(&neat_list)   && defined(&looks_like_number), 'import DBI tag ":utils"');
ok(defined(&SQL_CHAR) && defined(&SQL_INTEGER) && defined(&SQL_VARCHAR),       'import DBI tag ":sql_types"');
done_testing();
