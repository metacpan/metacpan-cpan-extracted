use ExtUtils::MakeMaker;

#
# WARNING: reading this file may cause real pain - stefan
#

# versions >= 5.7 should be ok
require 5.007;

unless(-f "./gen/cache.ok") {
   print STDERR <<'EOF';

Hey dude, it doesn't work this way.
Please read the INSTALL file.
You need to build a new Cache-Binary
in ./gen first.

The reason why you can't install this
module easily is simply the fact
that Intersystems doesn't
ship Cache as shared library.

It would be easy for them but
they refused to do so.


EOF
  exit(1);
}

use Config;

WriteMakefile(
    'NAME'		=> 'Cac',
    'dist'              => {
                             PREOP => 'chown -R root.root .; chmod -R u=rwX,go=rX . ;',
                             COMPRESS => 'gzip -9v',
                             SUFFIX   => '.gz',
                             DIST_DEFAULT=> 'predist',
                           },
    'VERSION_FROM'	=> 'Cac.pm',
    'PREREQ_PM'		=> { # 'Spreadsheet::WriteExcel' => 0.32,
    			     # 'Parse::RecDescent' => 1.80,	
    			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Cac.pm', # retrieve abstract from module
       AUTHOR     => 'Stefan Traby <stefan@hello-penguin.com>') : ()),
    'PM' => {
    		'Cac.pm'              => '$(INST_LIBDIR)/Cac.pm',
    		'Cac/Global.pm'       => '$(INST_LIBDIR)/Cac/Global.pm',
    		'Cac/Routine.pm'      => '$(INST_LIBDIR)/Cac/Routine.pm',
    		'Cac/Util.pm'         => '$(INST_LIBDIR)/Cac/Util.pm',
    		'Cac/ObjectScript.pm' => '$(INST_LIBDIR)/Cac/ObjectScript.pm',
    		'Cac/Bind.pm'         => '$(INST_LIBDIR)/Cac/Bind.pm',
            },
    'clean' => { FILES => "t/*.fin t/x.xls ", }, 
);

sub MY::postamble {
"
#
# this is a bit heavy, I know. But it's needed for make test, we want to check the newly created binary.
# NOTE: you can't use cache --perl there, because somebody expects that exec argv[0] results in
# a working perl. hey, that's a cache :)
#
FULLPERL=\$(shell pwd)/gen/cperl

setver:
	\$(PERL) -pi -e 's/^(\\s*(?:our)?\\s*\\\$\$VERSION\\s*=\\s*).*\$\$/\$\${1}\$(VERSION);/' *.pm Cac/*.pm

predist:  setver
	pod2text Cac.pm >README
	\$(MAKE) tardist

# that's the way, I like it (DON'T)
_html:
	d=\$\$PWD; \\
	t=/usr/websys/htdocs/cacperl; \\
	for i in ./*.pm ./Cac/*.pm ; do \\
	mkdir -p \"\$\$t\"/\$\$(dirname \"\$\$i\") && \\
	o=\"\$\$t\"/\$\$(dirname \"\$\$i\")/\$\$(basename \$\$i|sed -e s/.pm\$\$/.html/) ; \\
	o=\"\$\$t\"/\$\$(basename \$\$i|sed -e s/.pm\$\$/.html/) ; \\
	       pod2html --podpath '.:Cac' \\
	                --infile \"\$\$i\" \\
			--outfile \"\$\$o\" && \\
	\$(PERL) -pi -e 's|href=\"/./blib/lib/Cac/|href=\"|g'  \"\$\$o\" && \\
	\$(PERL) -pi -e 's|href=\"/./Cac/|href=\"|g'  \"\$\$o\" && \\
	\$(PERL) -pi -e 's|href=\"/\\./Cac\\.|href=\"Cac.|g' \"\$\$o\" ; \\
	  done && \\
	chmod -R 444 \"\$\$t\"

_clean:
	find . -iname '*~' -print0|xargs -0r rm -f
	find . -iname '*.html' -print0|xargs -0r rm -f
	find . -iname '*.tmp' -print0|xargs -0r rm -f
	rm -rf ./html
	( cd ./gen && \$(MAKE) -f Makefile.unix clean)
"
}

