use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$| = 1;
print "Checking your operating system ... ";
if ($^O =~ /sco/) {
	print STDERR "\nYou seem to be running an SCO Unix system ($^O)\n";
    print STDERR "If you see the message below when you run the test.pl ";
	print STDERR "script:\n\n";
	print STDERR "Can\'t load \'./blib/arch/auto/Prot/Prot.so\' for module ";
	print STDERR "Prot: Unknown error \n\n";
	print STDERR "You may need to build a static version of this module.\n";
	print STDERR "Use the following command to do so:\n";
	print STDERR "\$ perl Makefile.PL LINKTYPE=static\n";
}
print "ok\n";

WriteMakefile(
    'NAME'	       => 'Authen::Prot',
    'VERSION_FROM' => 'Prot.pm',	# finds $VERSION
    'CONFIG'    => ['osname'],		# Used to determine available functions
    'DEFINE'    => '-D$(OSNAME)',
    'dist'         => {
		PREOP      => '/opt/perl5/bin/pod2text Prot.pm > README;\
                       /opt/perl5/bin/pod2html --noindex \
                       Prot.pm > Authen-Prot.man.html',
		COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
    },
);
