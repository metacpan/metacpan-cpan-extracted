use inc::Module::Install;
name 'DBIx-CouchLike';
all_from 'lib/DBIx/CouchLike.pm';

requires
    'Math::BigInt'          => 1.55,
    'JSON'                  => 2,
    'UNIVERSAL::require'    => 0,
    'DBI'                   => 1,
    'Class::Accessor::Fast' => 0,
    'Unicode::RecursiveDowngrade' => 0,
;

tests 't/*.t';
author_tests('xt') if eval { require Module::Install::AuthorTests };

test_requires 'Test::More' => "0.87_01";
test_requires 'Test::Requires';

auto_include;
WriteAll;
