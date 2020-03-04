use 5.010_001;

use strict;
use warnings FATAL => 'all';

use inc::Module::Install 0.91;

homepage 'http://search.cpan.org/perldoc?DBIx%3A%3AClass%3A%3ASims';
resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'https://github.com/robkinyon/dbix-class-sims',
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Sims';

perl_version '5.010_001';
all_from 'lib/DBIx/Class/Sims.pm';

requires 'strictures';
requires 'Clone::Any';
requires 'Data::Compare';
requires 'Data::Printer' => '0.36'; # np() isn't exported before 0.36+
requires 'Data::Walk';
requires 'DateTime';
requires 'DateTime::Event::Random';
requires 'DBIx::Class::TopoSort' => '0.060000';
requires 'Hash::Merge';
requires 'JSON::MaybeXS';
requires 'List::MoreUtils';
requires 'List::PowerSet';
requires 'List::Util';
requires 'Scalar::Util';
requires 'String::Random';
requires 'Try::Tiny';
requires 'YAML::Any'; # Removes a warning.
 
test_requires 'File::Temp'        => '0.01';
test_requires 'JSON'              => '0.01';
test_requires 'Test::DBIx::Class' => '0.01';
test_requires 'Test::Warn'        => '0.01';
test_requires 'Test::Trap'        => '0.3.2';
test_requires 'DBD::SQLite'       => '1.40';
test_requires 'Test2::Harness'    => '0.001079'; # yath
test_requires 'Test2::Suite'      => '0.000122'; # improved test tools

# All of the following are needed for Devel::Cover and its optional reports.
test_requires 'Devel::Cover';
test_requires 'Template';
test_requires 'PPI::HTML';
test_requires 'Perl::Tidy';
test_requires 'Pod::Coverage::CountParents';
test_requires 'JSON::MaybeXS';

tests_recursive;

auto_install;
 
WriteAll;
