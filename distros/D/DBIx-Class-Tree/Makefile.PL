use inc::Module::Install;

BEGIN {
  if ($Module::Install::AUTHOR) {
    require Module::Install::ReadmeFromPod;
  }
}

name            'DBIx-Class-Tree';
perl_version    '5.008001';
all_from        'lib/DBIx/Class/Tree.pm';
readme_from     'lib/DBIx/Class/Tree.pm';

resources 'repository'  => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=dbsrgits/DBIx-Class-Tree.git';

requires        'DBIx::Class' => '0.08100';
test_requires   'Test::Exception';

WriteAll;

