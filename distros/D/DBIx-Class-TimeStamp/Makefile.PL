use inc::Module::Install 1.00;

perl_version '5.008001';
name 'DBIx-Class-TimeStamp';
all_from 'lib/DBIx/Class/TimeStamp.pm';

requires 'DateTime'                     => 0.55;
requires 'DBIx::Class'                  => 0.08009;
requires 'DBIx::Class::DynamicDefault'  => 0.03;

test_requires 'DateTime::Format::SQLite';
test_requires 'Time::HiRes';
test_requires 'Time::Warp';

# legacy for old-ish DBICs
test_requires 'DateTime::Format::MySQL'; 
test_requires 'Class::Accessor::Grouped';


resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'http://dev.catalyst.perl.org/repos/bast/trunk/DBIx-Class-TimeStamp/';

postamble(<<"EOM") if $Module::Install::AUTHOR;
t/sql/test.sqlite.sql: t/lib/DBIC/Test/Schema.pm t/lib/DBIC/Test/Schema/*.pm
\t\$(MKPATH) t/sql
\t\$(PERL) t/generate_schema.pl > \$@

manifest : t/sql/test.sqlite.sql
EOM

auto_install;
WriteAll;
