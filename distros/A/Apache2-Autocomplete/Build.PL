use strict;
use warnings;

use Module::Build;
my %prereq = (
              'JavaScript::Autocomplete::Backend'     => 0,
	      'Apache2::RequestRec' => 0,
             );

eval {require Apache::TestMB; };
if ($@) {
  warn qq{Please install ModPerl::MM first};
  exit 0;
}

my $build = Apache::TestMB->new(
  module_name => 'Apache2::Autocomplete',
  license => 'perl',
  requires => \%prereq,
  dist_version_from => 'lib/Apache2/Autocomplete.pm',
  dist_author => ['Randy Kobes <r.kobes@uwinnipeg.ca>'],
  dist_abstract_from => 'lib/Apache2/Autocomplete.pm',
);

$build->create_build_script;

