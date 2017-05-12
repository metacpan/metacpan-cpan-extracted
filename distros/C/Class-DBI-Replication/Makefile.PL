use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Class::DBI::Replication',
    'VERSION_FROM' => 'lib/Class/DBI/Replication.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Class::DBI' => 0,
    },
);

warn <<WARN;
Currently, you require mysql database to test this module.
If you have mysql installed,

    CREATE DATABASE test_0;
    CREATE DATABASE test_1;

is what you need to do.

Currently username, password, host are really hard-coded. Change their
values by your hand, if you want to change this.
WARN
    ;


    
