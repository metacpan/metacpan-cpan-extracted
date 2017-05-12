use strict;
use warnings;

use Module::Build;
my %prereq = (
              'File::Spec'         => 0.8,
              'Apache2::Request'     => 0,
	      'Apache2::RequestRec' => 0,
             );
eval {require Apache::TestMB; };
if ($@) {
  warn qq{Please install ModPerl::MM first};
  exit 0;
}

my $build = Apache::TestMB->new(
  module_name => 'CGI::Apache2::Wrapper',
  license => 'perl',
  requires => \%prereq,
  dist_version_from => 'lib/CGI/Apache2/Wrapper.pm',
  dist_author => ['Randy Kobes <r.kobes@uwinnipeg.ca>'],
  dist_abstract_from => 'lib/CGI/Apache2/Wrapper.pm',
);

$build->create_build_script;

