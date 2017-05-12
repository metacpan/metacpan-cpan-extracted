use 5.008001;

use ExtUtils::MakeMaker;
use Apache::TestMM qw(test clean); #enable 'make test'
  
# prerequisites
my %require =
(
    "Apache::Test" => "",
    "IO::WrapTie" => "",
    "IO::File" => "",
    "Class::Data::Inheritable" => "",
    "ex::override" => "",
);
my @scripts = qw(t/TEST);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME         => 'Apache::TieBucketBrigade',
    VERSION_FROM => 'lib/Apache/TieBucketBrigade.pm',
    PREREQ_PM    => \%require,
    clean        => {
                       FILES => "@{ clean_files() }",
                      },
      ($] >= 5.005 ?
          (ABSTRACT_FROM => 'lib/Apache/TieBucketBrigade.pm',
           AUTHOR        => 'mock <mock@obscurity.org>',
        ) : ()
    ),
);

sub clean_files {
      return [@scripts];
}
