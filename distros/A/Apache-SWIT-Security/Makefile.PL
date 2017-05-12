use strict;
use warnings FATAL => 'all';
use Apache::SWIT::Subsystem::Makefile;

Apache::SWIT::Subsystem::Makefile->new->write_makefile(
    NAME         => 'Apache::SWIT::Security',
    VERSION_FROM => 'lib/Apache/SWIT/Security.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Security subsystem for Apache::SWIT based modules',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Apache::SWIT' => 0.47
		     , 'Class::DBI::Pg::More' => '0.04'
		     , 'HTML::Tested' => '0.51'
                    },
);
