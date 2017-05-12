use inc::Module::Install;

name     'App-Prove-Plugin-Idempotent';
all_from 'lib/App/Prove/Plugin/Idempotent.pm';
author   q{Steffen Schwigon <ss5@renormalist.net>};
license  'perl';

author_requires 'Module::Install::AuthorTests';

build_requires 'Test::More';

requires 'TAP::Parser' => "3.24";

repository 'git://github.com/renormalist/App-Prove-Plugin-Idempotent.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Prove-Plugin-Idempotent';

auto_install;

WriteAll;
