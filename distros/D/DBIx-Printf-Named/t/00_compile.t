use strict;
use Test::More;

BEGIN { use_ok 'DBIx::Printf::Named' }

my $dbh = DBI->connect('DBI:Mock:', '', '');

is($dbh->nprintf('select 1'), 'select 1', 'no args');
is($dbh->nprintf('select %%s'), 'select %s', '%% -> %');
is($dbh->nprintf('select %%%(key)s', {key=>1}), "select %'1'", '%%%s -> %(string)');

is($dbh->nprintf('select %(key)d', {key=>1}), 'select 1', 'single %d');
is($dbh->nprintf('select %(key)d', {key=> "1.3' or 1"}), 'select 1', '%d with garbage');
is($dbh->nprintf('select %(key)d', {key=>''}), 'select 0', '%d with empty string');
is($dbh->nprintf('select %(key)d', {key=>'abc'}), 'select 0', '%d with not a number at all');

is($dbh->nprintf('select %(key)f', {key=>1}), 'select 1', 'single %f');
is($dbh->nprintf('select %(key)f', {key=>1.3e1}), 'select 13', 'single %f given a fp');
is($dbh->nprintf('select %(key)f', {key=>'1.3e1'}), 'select 13', 'single %f given a fp str');
is($dbh->nprintf('select %(key)f', {key=>"'or 1"}), 'select 0', 'single %f given a garbage');

is($dbh->nprintf('select %(key)s', {key=>"don't"}), "select 'don''t'", '%s');

is($dbh->nprintf('select %(key)t', {key=>"don't"}), "select don't", '%t');

is($dbh->nprintf('select %(key1)d,%(key2)d,%(key3)d', {key1=>1, key2=>2, key3=>3}), 'select 1,2,3', 'multiple args');

is($dbh->nprintf('select 1 like %like()'), "select 1 like ''", 'empty %like');
is($dbh->nprintf('select 1 like %like(%(key)s%%)', {key=>'a'}), "select 1 like 'a%'", '%like');
is($dbh->nprintf('select 1 like %like(%(key)s%%)', {key=>"%a_b'"}), "select 1 like '\\%a\\_b''%'", '%like escape check');

is($dbh->nprintf(q!select 1 like %like(%(key)s%%) escape '\'!, {key=>"%a_b'"}), qq!select 1 like '\\%a\\_b''%' escape '\\'!, '%like escape check backslash');
is($dbh->nprintf(q!select 1 like %like(%(key)s%%) ESCAPE '$'!, {key=>"%a_b'"}), qq!select 1 like '\$%a\$_b''%' ESCAPE '\$'!, '%like escape check doller');
is($dbh->nprintf(q!select 1 like %like(%(key)s%%) Escape ''!, {key=>"%a_b'"}), qq!select 1 like '%a_b''%' Escape ''!, '%like escape check backslash');
is($dbh->nprintf(<<'EOF',{key=>"%a_b'"}), qq!select 1 like '\*%a\*_b''%'\nESCAPE '\*'\n!, '%like escape check *');
select 1 like %like(%(key)s%%)
ESCAPE '*'
EOF

eval {
    $dbh->nprintf('select %(key)d',{key2=>'a'});
};
ok($@, 'not exists');

done_testing();



