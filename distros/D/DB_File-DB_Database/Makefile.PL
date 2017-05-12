eval 'use DB_File';
if ($@) {
	print <<EOF;
	You do not seem to have DB_File installed, so you will not be able
	to use DB_File::DB_Database.
EOF
	}
print <<EOF;

	If there are any problems with this module, read the README first.

EOF

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DB_File::DB_Database',
    'VERSION_FROM'	=> 'lib/DB_File/DB_Database.pm',
    ($] >= 5.005 ? (
    'AUTHOR'		=> 'Ran Ningyu (rny@163.net)',
    'ABSTRACT'		=> 'DB_File to MutiField Table with Index',
		) : ()),
#    'clean'		=> { FILES => ''},
);
