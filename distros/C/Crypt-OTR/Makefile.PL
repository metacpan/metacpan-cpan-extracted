use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub libOtrIsInstalled(){
	if(-f('/usr/include/libotr/version.h')){
		return 1;
	} elsif (-f('/usr/local/include/libotr/version.h')){
		return 1;
	} else {
		return 0;
	}
}

sub libGcryptIsInstalled(){
	if(-f('/usr/include/gcrypt.h')){
		return 1;
	} elsif (-f('/usr/local/include/gcrypt.h')){
		return 1;
	} else {
		return 0;
	}
}


unless( libOtrIsInstalled() ) {
	die("OTR library not installed.  Please install (package=libotr2-dev) and continue.");
}

unless( libGcryptIsInstalled() ) {
	die("gcrypt not installed.  Please install (package=libgcrypt-dev) and continue.");
}



WriteMakefile(
    NAME              => 'Crypt::OTR',
    VERSION_FROM      => 'lib/Crypt/OTR.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/OTR.pm', # retrieve abstract from module
       AUTHOR         => 'Mischa Spiegelmock <mspiegelmock@gmail.com>') : ()),
    LIBS              => ['-L/usr/lib -lotr'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/include', # e.g., '-I. -I/usr/include/other'

    META_ADD => { resources => { repository => 'git://github.com/revmischa/Crypt-OTR.git' } },
    
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Crypt::OTR',
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
