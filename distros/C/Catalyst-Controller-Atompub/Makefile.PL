use strict;
use warnings;
use inc::Module::Install;

name('Catalyst-Controller-Atompub');
all_from('lib/Catalyst/Controller/Atompub.pm');
license('perl');

requires('Catalyst::Devel');
requires('Catalyst::Plugin::ConfigLoader');
requires('Catalyst::Runtime', 5.7);

requires('Atompub', 0.003); # 0.3.0
requires('English');
requires('File::Slurp');
requires('FindBin');
requires('HTTP::Status');
requires('MIME::Base64');
requires('Text::CSV');
requires('Time::HiRes');
requires('URI::Escape');

requires('version', 0.74);

build_requires('Test::More');
build_requires('Test::Perl::Critic');
build_requires('Test::WWW::Mechanize::Catalyst');

auto_include;
auto_install;

WriteAll;
