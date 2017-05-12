use ExtUtils::MakeMaker;

use Apache::TestMM qw(test clean); #enable 'make test'
my @scripts = qw(t/TEST);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');
WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    'NAME'		=> 'Apache::UploadMeter',
    'VERSION_FROM'	=> 'lib/Apache/UploadMeter.pm', # finds $VERSION
    'PREREQ_PM'		=> {mod_perl2=>2.000003,Apache2::Request=>2.08,Cache::Cache=>0.09,Number::Format=>0.01,Date::Format=>0.01}, 
    clean               => {
                            FILES => "@{ clean_files() }",
                            },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Apache/UploadMeter.pm', # retrieve abstract from module
       AUTHOR     => 'Issac Goldstand <margol@beamartyr.net>') : ()),
);

sub clean_files {
    return [@scripts];
}