
eval 'use DBI';
if ($@ ne '') {
	print <<EOF;
	You do not seem to have DBI installed, so you will not be able
	to use DBD::XBase (but XBase.pm should still be running fine).
EOF
	}
elsif ( eval ' $DBI::VERSION < 1.0 ' ) {
	print <<EOF;
	You have the DBI module, but it's the old version. Upgrade to
	at least 1.0 to use this DBD::XBase. Or, use the DBD::XBase
	version < 0.09, from your favorite CPAN mirror.
EOF
	}

print <<EOF;

	If there are some problems with this module, read the README first.

EOF

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'XBase',
	'DISTNAME'	=> 'DBD-XBase',
	'VERSION_FROM'	=> 'lib/XBase.pm',
    ($] >= 5.005 ? (
	'AUTHOR'	=> 'Jan Pazdziora (adelton@fi.muni.cz)',
	'ABSTRACT'	=> 'Reads and writes XBase (dbf) files, includes DBI support',
		) : ()),
	'PL_FILES'	=> { 'bin/dbfdump.PL' => 'bin/dbfdump' },
	'EXE_FILES'	=> [ 'bin/dbfdump' ],
        'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	'clean'		=> { FILES => 'bin/dbfdump t/newtable.dbf t/newtable.dbt t/write.dbf t/write.dbt'},	
	);

