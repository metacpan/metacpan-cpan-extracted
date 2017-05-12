use ExtUtils::MakeMaker;
use 5.010; ##-- in case old EU::MM doesn't grok MIN_PERL_VERSION
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

##-- argh argh argh: NetServer::Generic doesn't work in PREREQ_PM (at least on 2011-11-15 / svn rev 7)
#BEGIN {
#  use NetServer::Generic;
#  die("ERROR: Prerequisite module NetServer::Generic not found")
#    if (!defined($NetServer::Generic::VERSION));
#}

WriteMakefile
  (
   NAME         => 'DDC::Concordance',
   #DISTNAME     => 'DDC-Concordance',
   VERSION_FROM => 'lib/DDC/Concordance.pm', # finds $VERSION
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT     => 'Query utilities for ddc-concordance search engine',
   LICENSE      => 'perl_5',
   MIN_PERL_VERSION => 5.010, ##-- we need perl >= v5.10.0 for /p regex modifier in yyqlexer.pm
   META_MERGE   => {
		    'meta-spec' => { version => 2 }, ##-- doesn't seem to work
		    resources  => {
				   repository => {
						  type => 'svn',
						  url => 'svn://svn.code.sf.net/p/ddc-concordance/code/ddc-perl/',
						  web => 'https://sourceforge.net/p/ddc-concordance/code/HEAD/tree/ddc-perl/',
						 },
				  },
		    prereqs => {
				runtime => {
					    recommends => {
							   'Alien::DDC::Concordance' => 0.002,
							   'DDC::XS' => 0.14,
							  },
					    #suggests => {},
					   },
			       },
		   },


   PREREQ_PM    => {
		    'IO::Socket::INET'=>0,
		    'NetServer::Generic'=>1.03, ##-- for drop-in server replacement
		    'Text::Wrap'=>0,
		    #'Lingua::LTS'=>0.01, ##-- needed for LTS stuff
		    #'JSON::XS' => 0,
		    'JSON' => 0,
		    ##
		    'Parse::Yapp' => 0, ##-- tested v1.05
		    ##
		    ##-- TEST backwards-compatible dependencies
		    #'DDC' => 0.17,
		    #'DDC::Compat' => 0.17,
		    ##
		    ##-- test modules
		    'Test::More' => 0, ##-- 1.001002
		   },

   EXE_FILES    => [
		    grep {$_ !~ /-lts-/}
		    glob("ddc-*.perl")
		   ],
  );

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ###-- depends -> README.txt
		 "\n\n"
		 ."dist: README.txt lib/DDC/PP/yyqparser.pm\n"
		 ."\n"
		 ."create_distdir: README.txt lib/DDC/PP/yyqparser.pm\n"
		 #."distdir_am: README.txt\n"
		 ."\n"
		 ."distcheck: README.txt lib/DDC/PP/yyqparser.pm\n"
		 ."\n"
		 ."manicheck: README.txt lib/DDC/PP/yyqparser.pm\n"
		 ."\n"
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

##-- yapp
yapp:
\trm -f lib/DDC/PP/yyqparser.pm
\t\$(MAKE) lib/DDC/PP/yyqparser.pm

lib/DDC/PP/yyqparser.pm: lib/DDC/PP/yyqparser.yp
\tyapp -v -m DDC::PP::yyqparser -o \$@ \$<

##-- pod2xxx
.pm.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

##-- readme
.rpod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

readme: README.txt

";
  return $inherited;
}

