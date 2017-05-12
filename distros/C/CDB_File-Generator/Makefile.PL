use ExtUtils::MakeMaker;

$found=0;
DIRCHECK: foreach (split /:/, $ENV{"PATH"}) {
  -x $_ . '/' . 'cdbmake' && do {
    $found=1;
    last DIRCHECK;
  }
}
print STDERR <<EOF unless $found;
*****************************************************************
*WARNING CDB_File::Generator needs access to the cdbmake program*
*****************************************************************
EOF

WriteMakefile( NAME => "CDB_File::Generator",
	       VERSION_FROM => "lib/CDB_File/Generator.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
	       PREREQ_PM => {CDB_File => 0.6}, # actually only needed
                                               # for tests..
	     );
