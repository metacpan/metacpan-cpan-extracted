use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# get some stuff we need to know
print "Enter path to kerberos libraries: ";
my $krblibs = <STDIN>;
chomp($krblibs);
print "Enter path to kerberos headers: ";
my $krbincs = <STDIN>;
chomp($krbincs);

WriteMakefile(
    'NAME'		=> 'Authen::Krb5::Easy',
    'VERSION_FROM'	=> 'Easy.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ['-L' . $krblibs . ' -lkrb5'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I' . $krbincs . '', # e.g., '-I/usr/include/other'
);
