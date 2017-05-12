# $id$

use ExtUtils::MakeMaker;
require 5.004;
#use Config;

if (system("which xsltproc > /dev/null")) {
    print <<MSG;

WARNING: ** You do not have xsltproc **

This tool is not required for the core of chaos-xml perl lib, but it
is required for certain kinds of format conversion, such as
Chaos<=>ChadoXML

xsltproc is available as part of libxslt. See http://xmlsoft.org/XSLT/
for details

MSG
      
}

$p = "XML::Parser::PerlSAX";
if (!eval "require $p") {
    print <<MSG;

WARNING: ** You do not have XML::Parser::PerlSAX installed **

This tool is not required for the core of chaos-xml perl lib, but it
is required for parsing chaos-xml documents. It is not required for
generating chaos from genbank

MSG
      
}

WriteMakefile(
	      'NAME'         => "Bio-Chaos",
	      'DISTNAME'         => "Bio-Chaos",
	      'ABSTRACT'     => 'Chaos biotools',
	      'AUTHOR'       => 'Chris Mungall <cjm AT fruitfly DOT org>',
	      'VERSION_FROM' => "lib/Bio/Chaos/Root.pm",
	      'PREREQ_PM'    => {
				 'Data::Stag' => '0.07',
				 'Bio::Seq'         => '1.5',
                                 'Graph' => 0,
				},
	      'EXE_FILES'    => [
                                 qw(
                                    bin/cx-chadoxml2chaos.pl
                                    bin/cx-chaos-report.pl
                                    bin/cx-download-enscore.pl
                                    bin/cx-enscore2chaos.pl
                                    bin/cx-genbank2chaos.pl
                                   )
				],
	      'dist'         => { 
				 'SUFFIX'       => ".gz",
				 'DIST_DEFAULT' => 'all tardist',
				 'COMPRESS'     => "gzip -9f" 
				},
	      clean => {
			FILES => 'Bio-Chaos-$(VERSION).tar.gz',
		       },
	     );


sub MY::postamble {
  qq{


# INSTALL .xsl FILES AS PERL MODULES
# this is only required by the Bio-Chaos developer in charge of
# releases to make a Bio-Chaos dist that includes the XSLs

# directory for source XSLs; this only makes sense if Bio-Chaos
# is a subdir of go-dev
XSL_SRC_DIR = xsl

# xsls which Bio-Chaos can use

XSL = chado-create-feature-nesting chado-expand-macros chado-feature-summary-html chado-insert-macros chado-remove-default-elements chado-remove-feature-nesting chado-to-gff3 cx-chado-to-chaos cx-chaos-to-chado cx-chaos-to-chaos cx-chaos-to-dbxref-tbl cx-chaos-to-feature-summary-tbl cx-chaos-to-gff3

XSL_FILES = \$(patsubst %,\$(XSL_SRC_DIR)/%.xsl,\$(XSL))

# this dir should always be made before a distribution; the end-user
# installer never needs to build this, their distribution will come
# with these files. When a 'make install' is performed, the xsls will
# go in the location where perl modules usually go.
# we re-run 'make' at the end of this to rebuild TO_INST_PM in Makefile
lib/Bio/Chaos/xsl :: \$(XSL_FILES)
	(test -d lib/Bio/Chaos/xsl || mkdir lib/Bio/Chaos/xsl) && cp \$(XSL_FILES) lib/Bio/Chaos/xsl && make

  };  
}

