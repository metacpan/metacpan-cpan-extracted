#file:Makefile.PL
#----------------
use 5.008;
use ExtUtils::MakeMaker;
use Apache2::Build ();
use Apache2::BuildConfig ();

use lib qw(../blib/lib lib );

use Apache::TestMM qw(test clean); #enable 'make test'

# prerequisites
my %require =
  (
   "Apache::Test" => "", # any version will do
   "Sys::Proctitle" => '0.02',
  );
my @scripts = qw(t/TEST);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME              => 'Apache2::ShowStatus',
    VERSION_FROM      => 'lib/Apache2/ShowStatus.pm', # finds $VERSION
    PREREQ_PM         => \%require,
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-Ixs '.Apache2::BuildConfig->new->inc,
    clean             => {
			  FILES => "@{ clean_files() }",
			 },
    depend            => {
			 },
    dist              => {
			  PREOP => './mk_README.sh',
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache2/ShowStatus.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Förtsch <torsten.foertsch@gmx.net>') : ()),
);

sub clean_files {
    return [@scripts];
}

sub MY::postamble {
  return <<'EOF';
README: lib/Apache2/ShowStatus.pm mk_README.sh
	./mk_README.sh
EOF
}
