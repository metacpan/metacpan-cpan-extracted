use inc::Module::Install;

name 'DBIx-Class-UserStamp';
all_from 'lib/DBIx/Class/UserStamp.pm';

requires 'DBIx::Class';
requires 'DBIx::Class::DynamicDefault';

build_requires 'Class::Accessor::Grouped';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/DBIx/Class/UserStamp.pm > README');
}

tests_recursive();
auto_install;
WriteAll;

