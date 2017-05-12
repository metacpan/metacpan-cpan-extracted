use ExtUtils::MakeMaker qw(prompt WriteMakefile);
WriteMakefile(
	      'NAME' => 'DBIx::Tree::NestedSet',
	      'VERSION_FROM' => 'lib/DBIx/Tree/NestedSet.pm',
	      'PREREQ_PM' => {
			      DBI=>'1.15'
			     },
	      'AUTHOR' => 'Daniel Collis Puro <dan@geekuprising.com>',
	     );

$rdbms	 = prompt ("RDBMS you're testing on? (Valid choices are MySQL and SQLite)","MySQL");
$connstr = prompt ("DBI Connection String?", "DBI:mysql:test");
$userid  = prompt ("User ID?", "");
$passwd  = prompt ("Password?", "");

open(PWD, ">PWD") || die "Could not open PWD for writing!";
print PWD $rdbms, "\n";
print PWD $connstr, "\n";
print PWD $userid, "\n";
print PWD $passwd, "\n";
