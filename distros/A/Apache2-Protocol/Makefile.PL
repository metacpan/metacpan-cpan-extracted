use 5.008005;
use ExtUtils::MakeMaker;



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2-Protocol',
    AUTHOR	      => "Will Whittaker <will\@mailchannels.com>\\nMike Smith <mike\@mailchannels.com>",
    VERSION_FROM      => 'lib/Apache2/Protocol.pm', # finds $VERSION
    PREREQ_PM         => {"Class::Accessor" => '',
			  "Apache2::TieBucketBrigade" => '',
			  "Apache2::Const" => ''}, # e.g., Module::Name => 1.1
);


