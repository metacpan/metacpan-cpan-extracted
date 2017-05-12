
use 5.010;

{
local $SIG{__WARN__} = sub {};
eval 'use XBase;';
}
if (Xbase->can("open_dbf")) {
	print <<EOF;
	You seem to have case insensitive filesystem and an old module
	Xbase.pm (note the lowercase b) installed. It will clash with
	XBase.pm badly. Please, remove Xbase.pm before continuing.
EOF

	sleep 3;
}

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
	at least 1.0 to use this DBD::XBase.
EOF
	}

print <<EOF;

	If there are any problems with this module, read the README first.

EOF

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'XBase',
	'DISTNAME'	=> 'DBD-XBase',
	'VERSION_FROM'	=> 'lib/DBD/XBase.pm',
    ($] >= 5.005 ? (
	'AUTHOR'	=> 'Jan Pazdziora',
	'ABSTRACT'	=> 'Reads and writes XBase (dbf) files, includes DBI support',
		) : ()),
	'PL_FILES'	=> { 'bin/dbfdump.PL' => 'bin/dbfdump',
				'bin/indexdump.PL' => 'bin/indexdump' },
	'EXE_FILES'	=> [ 'bin/dbfdump', ' bin/indexdump' ],
        'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	'clean'		=> { FILES => 'bin/dbfdump bin/indexdump t/newtable.* t/write*.* t/rooms.sdbm* t/rooms1.* t/tstidx* '},	
	);

