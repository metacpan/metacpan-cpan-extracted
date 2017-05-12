use 5.008_004;

use strict;
use warnings FATAL => 'all';

use inc::Module::Install 0.91;
 
homepage 'http://search.cpan.org/perldoc?DBIx%3A%3AClass%3A%3ATopoSort';
resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'https://github.com/robkinyon/dbix-class-toposort',
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-TopoSort';

perl_version '5.008_004';
all_from 'lib/DBIx/Class/TopoSort.pm';

requires 'DBIx::Class';
requires 'Graph';
 
test_requires 'Test::Exception'   => '0.21';
test_requires 'Test::DBIx::Class' => '0.01';
test_requires 'Test::More'        => '0.88'; # done_testing
test_requires 'Test::Deep'        => '0.01';
test_requires 'List::MoreUtils'   => '0.01'; # first_index
test_requires 'YAML::XS'          => '0.01'; # Force a usable YAML parser
 
tests_recursive;

auto_install;
 
WriteAll;
