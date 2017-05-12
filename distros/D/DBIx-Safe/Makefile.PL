use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DBIx::Safe',
    VERSION_FROM => 'Safe.pm',
    PREREQ_PM    => {
					 DBD::Pg       => 1.49,
					 DBI           => 1.49,
					 Test::Simple  => 0.30,
					 Test::More    => 0.61,
					 Test::Harness => 2.03,
				 },
	ABSTRACT     => 'Safe wrapper to DBI interface',
    AUTHOR       => 'Greg Sabino Mullane <greg@endpoint.com>',
    NO_META      => 1,
    clean        => { FILES => '*~ *.tmp outgoingmail.*' },
);
package MY;
sub manifypods {
	my $after = "\t \$(NOECHO) pod2html Safe.pm > Safe.pm.html\n\t\$(NOECHO) \$(RM_F) pod*.tmp pm_to_blib\n";
	$after .= qq{\t\$(NOECHO) \$(PERL) -pi -e "s/<link.*?>//" Safe.pm.html\n};
	$after .= qq{\t\$(NOECHO) \$(ECHO) Created Safe.pm.html\n};
	return shift->SUPER::manifypods(@_) . $after;
}
