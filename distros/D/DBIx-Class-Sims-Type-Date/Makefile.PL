use 5.010_001;

use strict;
use warnings FATAL => 'all';

use inc::Module::Install 0.91;

homepage 'http://search.cpan.org/perldoc?DBIx%3A%3AClass%3A%3ASims%3A%3AType%3A%3ADate';
resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'https://github.com/robkinyon/dbix-class-sims-type-date',
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Sims-Type-Date';

perl_version '5.010_001';
all_from 'lib/DBIx/Class/Sims/Type/Date.pm';

requires 'DateTime::Event::Random' => '0.03';
requires 'DBIx::Class::Sims'       => '0.300700';
requires 'Data::Printer'           => '0.36'; # np() isn't exported before 0.36+
 
test_requires 'File::Temp'        => '0.01';
test_requires 'Test::DBIx::Class' => '0.01';
test_requires 'Test::Exception'   => '0.21';
test_requires 'Test::More'        => '0.88'; # done_testing
test_requires 'Test::Deep'        => '0.01';
test_requires 'Test::Warn'        => '0.01';
test_requires 'Test::Trap'        => '0.3.2';
test_requires 'DBD::SQLite'       => '1.40';

tests_recursive;

auto_install;
 
WriteAll;
