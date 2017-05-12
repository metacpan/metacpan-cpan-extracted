use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %prereq = (
              'File::Spec'         => 0.8,
              'Apache2::Request'     => 0,
	      'Apache2::RequestRec' => 0,
            );

my %opts = (
	    NAME		=> 'CGI::Apache2::Wrapper',
	    VERSION_FROM	=> 'lib/CGI/Apache2/Wrapper.pm',
            PL_FILES            => {},
            PREREQ_PM           => \%prereq,
	   );

my $eu_version = $ExtUtils::MakeMaker::VERSION;
if ($eu_version >= 5.43) {
  $opts{ABSTRACT_FROM} = 'lib/CGI/Apache2/Wrapper.pm';
  $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
}
if ($eu_version > 6.11) {
  $opts{NO_META} = 1;
}

eval {require ModPerl::MM; };
if ($@) {
  warn qq{Please install ModPerl::MM first};
  exit 0;
}

require Apache::TestMM;
import Apache::TestMM qw(test clean);

Apache::TestMM::filter_args();

Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile( %opts);
