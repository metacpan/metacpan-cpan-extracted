use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $DEFINE = '-DHAS_PPPORT_H';

WriteMakefile(
    'NAME'		=> 'omnithreads::shared',
    'VERSION_FROM'	=> 'shared.pm', # finds $VERSION
	      'PM' => {
		  'shared.pm'    => '$(INST_LIBDIR)/shared.pm',
	      },
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'shared.pm', # retrieve abstract from module
       AUTHOR     => 'Arthur Bergman <arthur@contiller.se>') : ()),
    'MAN3PODS'		=> {},  # Pods will be built by installman
    'DEFINE'            => $DEFINE,
);
