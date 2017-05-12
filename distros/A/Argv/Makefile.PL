use ExtUtils::MakeMaker;
if (! -e 'Argv.html' && open(RM, '>Argv.html')) {
    print RM "TBD ...\n";
    close(RM);
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Argv',
    'VERSION_FROM'	=> 'Argv.pm',
    'PREREQ_PM'		=> { Getopt::Long => 2.23 },
    'dist'	=> {
	COMPRESS	=> 'gzip --force --best',
	PREOP		=> "pod2html Argv.pm --title='Argv Module' >Argv.html",
	POSTOP		=> 'rm -f pod2html-*cache',
	TAR		=> 'gtar',
	TARFLAGS	=> '--mode=u+w -cvf',
    },
    clean	=> {
	FILES		=> 'Argv.html',
    },
);

if ($^O =~ /MSWin32|Windows_NT/i) {
	eval "require Win32::Process::Info";
	$wpi = $@;
	eval "require Win32::ToolHelp";
	$wt = $@;
	if($wpi && $wt) {
		print "If you intend to use the ->pipe method, you should consider installing\nany of these modules:\n";
		print "  Win32::Process::Info\n";
		print "  Win32::ToolHelp\n";
		print "See documentation for reasons.\n"
	}
}
