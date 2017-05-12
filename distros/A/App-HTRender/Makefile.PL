use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::HTRender',
    VERSION_FROM      => 'lib/App/HTRender.pm', # finds $VERSION
    AUTHOR            => 'Andrew Johnson <lajandy at cpan dotorg>',
    LICENSE           => 'artistic_2',
    
    PREREQ_PM         => {
    						HTML::Template => 2.90,
    						JSON::Tiny     => 0.49,
    						Getopt::Long   => 2.37,
    						File::Basename => 2.76,
    						Pod::Usage     => 1.35,
                         }, # e.g., Module::Name => 1.1
	EXE_FILES         => ['ht_render'],
	INST_SCRIPT       => 'bin',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/HTRender.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Johnson <lajandy at cpan dot org>') : ()),

	(ExtUtils::MakeMaker->VERSION >= 6.46 ? 
		(
			META_MERGE => 
			{
				'meta-spec' => { version => 1.4 },
				resources => 
				{
					repository => 'git://github.com/lajandy/htrender.git',
				},
			},    	
    	) 
    	: ()
    ),

);
