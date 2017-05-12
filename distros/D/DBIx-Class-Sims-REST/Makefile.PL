use 5.010_000;

use strict;
use warnings FATAL => 'all';

use inc::Module::Install 0.91;

homepage 'http://search.cpan.org/perldoc?DBIx%3A%3AClass%3A%3ASims%3A%3AREST';
resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'https://github.com/robkinyon/dbix-class-sims-rest',
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';
resources 'bugtracker'  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Sims-REST';

perl_version '5.008_004';
all_from 'lib/DBIx/Class/Sims/REST.pm';

requires 'DBIx::Class::Sims';
requires 'Hash::Merge';
requires 'JSON::XS';
requires 'Plack::Request';
requires 'Web::Simple';
 
test_requires 'Test::DBIx::Class' => '0.01';
test_requires 'Test::More'        => '0.88'; # done_testing
test_requires 'Test::Deep'        => '0.01';
test_requires 'LWP::UserAgent'    => '0.01';
test_requires 'HTTP::Request'     => '0.01';

tests_recursive;

auto_install;
 
WriteAll;
