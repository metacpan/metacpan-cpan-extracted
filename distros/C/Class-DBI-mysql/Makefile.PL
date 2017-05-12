use ExtUtils::MakeMaker;

my $PACKAGE = 'Class::DBI::mysql';
my $LOCN    = 'lib/Class/DBI/mysql.pm';

my $LAST_API_CHANGE = 0.16;

eval "require $PACKAGE";

unless ($@) {    # Make sure we did find the module.
	my $inst_version = ${ $PACKAGE . '::VERSION' };
	print <<"CHANGE_WARN" if $inst_version < $LAST_API_CHANGE;

NOTE: There have been API changes since your installed version
($inst_version)!  Please check carefully if these will impact on you:

Significant changes:

  0.16 - removed search_match() and initials(). 
       - deprecated count() in favour of count_all();

  0.14 - no longer support CURDATE() etc.

CHANGE_WARN
}

WriteMakefile(
	AUTHOR        => 'Tony Bowden <tony@tmtm.com>',
	NAME          => $PACKAGE,
	ABSTRACT_FROM => $LOCN,
	VERSION_FROM  => $LOCN,
	PREREQ_PM     => {
		'Class::DBI' => 0.94,
		'Test::More' => 0.45,
		'DBD::mysql' => 0,
	},
);
