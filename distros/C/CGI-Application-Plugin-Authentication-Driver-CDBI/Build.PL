use strict;
use warnings;
use Module::Build;

print <<'ADOPTME';
-------------------------------------------------------------------
ADOPT ME!    ADOPT ME!    ADOPT ME!    ADOPT ME!    ADOPT ME!
-------------------------------------------------------------------
CGI::Application::Plugin::Authentication::Driver::CDBI

This is a module looking for a home. If you are still using it, you
might want to adopt it. Write to modules@perl.org to ask to become
its owner!

Otherwise, this module is unsupported.
-------------------------------------------------------------------
ADOPT ME!    ADOPT ME!    ADOPT ME!    ADOPT ME!    ADOPT ME!
-------------------------------------------------------------------

(I'll give you 5 seconds to think about that).
ADOPTME

sleep 5;

my $builder = Module::Build->new(
  module_name => 'CGI::Application::Plugin::Authentication::Driver::CDBI',
  license            => 'perl',
  create_readme      => 1,
  configure_requires => { 'Module::Build' => 0.38 },
  dist_author        => 'Shawn Sorichetti <ssoriche@coloredblocks.net>',
  dist_version_from  =>
    'lib/CGI/Application/Plugin/Authentication/Driver/CDBI.pm',
  requires => {
    'Test::More'                               => '0',
    'CGI::Application::Plugin::Authentication' => '0.06',
    'Class::DBI'                               => '0',
    'DBD::SQLite'                              => '0',
	'CGI::Application::Plugin::Session'        => '0',
 },
  resources => {
    repository => 'https://github.com/briandfoy/CGI-Application-Plugin-Authentication-Driver-CDBI',
    },
  add_to_cleanup => ['CGI-Application-Plugin-Authentication-Driver-CDBI-*'],
);

$builder->create_build_script();
