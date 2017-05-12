use 5.006001;
use ExtUtils::MakeMaker;

# Verify the modules that can be installed, based on the modules that
# are present.

sub mod_check
{
    my $mods	= shift;
    my $feature	= shift;
    foreach (@$mods)
    {
	eval "use $_;";
	if ($@)
	{
	    print "\n$feature won't be available (failed to use $_)\n";
	    print "Install the following modules to enable this feature:\n";
	    print "  $_\n" for @$mods;
	    print "\n\n";
	    return;
	}
    }
    print "$feature will be available\n";
    return 1;
}

mod_check($_->[1], $_->[0])
    for ( [ 'dnsbltool interactive mode', 
	    ['Term::ReadLine']],
	  );

WriteMakefile(
    NAME              => 'DNS::BL',
    VERSION_FROM      => 'lib/DNS/BL.pm', # finds $VERSION
    EXE_FILES	      => [ 'bin/dnsbltool',
			   ],
    PREREQ_PM         => {
	'NetAddr::IP'	=> 3,
	'Test::More'	=> 0,
	'BerkeleyDB'	=> 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DNS/BL.pm', # retrieve abstract from module
       AUTHOR         => 'Luis Muñoz <luismunoz@cpan.org>') : ()),
);
