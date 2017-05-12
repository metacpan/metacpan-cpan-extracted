use 5.008008;
use ExtUtils::MakeMaker;

my $github = 'github.com/alexvogel/cae-nastran-nasmod';
my $repo = "https://$github";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CAE::Nastran::Nasmod',
    VERSION_FROM      => 'lib/CAE/Nastran/Nasmod.pm', # finds $VERSION
    ABSTRACT          => 'basic access to nastran models',
    LICENSE           => 'perl',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Alexander Vogel <avoge@cpan>',
      ) : ()
    ),
    META_MERGE => {
    	'meta-spec' => {
    		version => 2,
    	},
    	resources => {
    		repository => {
    			type => 'git',
    			url => "git://$github.git",
    			web => $repo,
    		},
    	},
    	bugtracker => {
    		web => "$repo/issues",
    	},
    	homepage => 'http://',
    },
    MIN_PERL_VERSION => '5.006000',
);
