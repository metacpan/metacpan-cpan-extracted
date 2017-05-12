## Created with help from make2build 0.17

use Module::Build;

my $b = Module::Build->new(
  module_name => 'CGI::Application::Plugin::Output::XSV',
  pm_files => { 'XSV.pm' => 'lib/CGI/Application/Plugin/Output/XSV.pm' },
  license => 'perl',
  dist_version_from => 'XSV.pm',
  requires => {
    'CGI::Application' => 0,
    'Text::CSV_XS' => 0,
  },
  recommends => {
   'Test::Exception'  => 0,
   'Test::MockObject' => 0,
  },
  build_requires => {
    'Test::More' => 0,
  },
  #create_makefile_pl => 'traditional',
  dist_author => 'Evan A. Zacks <zackse@cpan.org>',
  dist_abstract => 'Produce csv output from a CGI::Application runmode',
  add_to_cleanup => [ 'Makefile.old', 'CGI-Application-*.gz' ],
);
  
$b->create_build_script;
