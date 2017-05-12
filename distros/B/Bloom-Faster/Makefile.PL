use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bloom::Faster',
    VERSION_FROM      => 'lib/Bloom/Faster.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bloom/Faster.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Alvaro and Dmitriy Ryaboy <peter@eecs.berkeley.edu>') : ()),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other',
	# Un-comment this if you add C files to link with later:
    ##MYEXTLIB => 'leopold/src/.libs/libbloom.a'
    'CC'                => $CC,
    'LD'                => '$(CC)',
    'OBJECT'          => 'bloom.o suggestions.o jenkins.o Faster.o', # link all the C files too
    'XSOPT'             => '-C++',
);

##sub MY::postamble {
sub psyche {
'
	# something strange happens to this Makefile.in file 
	# when I run "make dist" from the perl installation.  I need
	# to replace it with the right file from the c build
	tar -xvzf leopold-1.1.tar.gz
	cp -f leopold-1.1/src/Makefile.in leopold/src/Makefile.in
	##cd leopold && CFLAGS=-fPIC ./configure && CFLAGS=-fPIC make
	cd leopold && ./configure && make

';	

}	



if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(HASHCNT PRIME_SIZ SIZ));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Bloom',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
