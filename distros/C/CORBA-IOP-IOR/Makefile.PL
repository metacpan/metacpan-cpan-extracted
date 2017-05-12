use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence the
# contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	     => 'CORBA::IOP',
	      'DISTNAME'     => 'CORBA-IOP-IOR',
	      'VERSION_FROM' => 'CORBA/IOP/IOR.pm',

# Couldn't find a next way of installing to CORBA/IOP without overriding this...
	      'PM' => { 'CORBA/IOP/IOR.pm'           => '$(INST_LIBDIR)/IOP/IOR.pm',
	                'CORBA/IOP/TaggedProfile.pm' => '$(INST_LIBDIR)/IOP/TaggedProfile.pm',
		        'CORBA/IOP/Util.pm'          => '$(INST_LIBDIR)/IOP/Util.pm' },
	      'dist'         => {
				 'COMPRESS'=>'gzip',
				 'SUFFIX' => 'gz',
				}
);
