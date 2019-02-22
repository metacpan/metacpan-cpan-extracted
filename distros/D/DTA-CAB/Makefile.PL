use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Constants
my $VERSION = '1.107';

##----------------------------------------------------------------------
## Hacks

##-- workaround for irritating symlink-related errors on kira (ubuntu 16.04 LTS / EUMM v7.0401)
do "./find.hack" if (-e "./find.hack");


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'DTA::CAB',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> '"Cascaded Analysis Broker" for robust linguistic analysis',
   VERSION	=> $VERSION,

   PREREQ_PM    => {
		    'Gfsm'     => 0.0216,
		    'Gfsm::XL' => 0.03, ##-- 0.02 works too, but doesn't support binary storage of analyzer configs
		    'Unicruft' => 0.03,
		    #'moot' => 0.02, ##-- moot/swig
		    'Moot' => 0.01,  ##-- moot/xs
		    'Lingua::TT' => 0.07, ##-- for Lingua::TT::Dict, DB_File, CDB_File
		    'DTA::TokWrap' => 0, ##-- for DTA::CAB::Format::TEI, DTA::CAB::Format::TEIws [version parsing doesn't work]
		    'GermaNet::Flat' => 0.01, ##-- for GermaNet::* analyzers
		    ##--
		    'Unicode::Normalize' =>0, # 1.02
		    'Encode'=>0,
		    'File::Basename'=>0,
		    'Getopt::Long'=>0,
		    'LWP::Protocol::http::SocketUnixAlt'=>0, #0.0204
		    'Pod::Usage'=>0,
		    'Storable'=>0,
		    'Time::HiRes'=>0,
		    'Text::LevenshteinXS'=>0, ##-- for Analyzer::MootSub best-lemma heuristics
		    ##--
		    #File::Queue =>0,
		    'File::Temp'  =>0,
		    'File::Path'  =>0, ##-- for rmtree(), make_path()
		    'File::Map'   =>0, ##-- for regex-based blockScan()
		    ##--
		    'DB_File' =>0,
		    'CDB_File' =>0,
		    'JSON::XS' =>0,
		    #'YAML::XS' =>0,  ##-- debian package libyaml-libyaml-perl; optional
		    'XML::LibXML' => 2.0001,
		    'Template' =>0,
		    'LWP::UserAgent' =>0,
		    'HTTP::Daemon' =>0,
		    'HTTP::Daemon::UNIX' =>0, #0.06
		    ##--
		    'Log::Log4perl' => 1.07,
		    'Unicode::String' => 2.09,
		    'RPC::XML' => 0.59,
		    ##
		    #'Log::Dispatch' => 2.22, ##-- for cab servers, FileRotate
		    ##--
		    #'DocClassify' => 0.04,
		    #'Lingua::LangId' => 0.01,
		    ##--
		    #'Text::Unidecode' => 0.04,
		    #'Tie::Cache'=>0,
		    #'Unicode::UCD' =>0,
		    #'Unicode::CharName' =>0,
		    ##--
		    'Test::More' => 0,
		   },

   EXE_FILES   => [glob('dta-cab-*.perl')],
  );

##-----------------------------------------------------------------------
## Extensions
##-----------------------------------------------------------------------

##---------------------------------------------------------------
## maintainer-only: Version.pm
if (-d ".svn") {
  ##-- write CAB/Version.pm
  no warnings;
  print STDERR "Updating CAB/Version.pm\n";

  #my $svnroot = (map {/^URL\: (.*)$/ ? $1 : qw()} `svn info . 2>/dev/null`)[0];
  my $SVNVERSION = `svnversion .`;
  chomp($SVNVERSION);
  $SVNVERSION = "unknown version" if (!$SVNVERSION);

  open(VERSION_PM,">CAB/Version.pm")
    or die("$0: could not open CAB/Version.pm for write: $!");
  print VERSION_PM <<EOF;
##--- automatically generated file: DO NOT EDIT! ---
##
## File: DTA/CAB/Version.pm
## Description: DTA::CAB version constants (auto-generated)
##
package DTA::CAB::Version;
\$DTA::CAB::VERSION = '$VERSION';
\$DTA::CAB::SVNVERSION = '$SVNVERSION';
1;
EOF
} else {
  warn("This does not appear to be an SVN checkout -- NOT updating CAB/Version.pm\n");
}

##---------------------------------------------------------------
sub MY::dist_basics {
  package MY;
  my $inherited = shift->SUPER::dist_basics(@_);
  $inherited =~ s{-e (\S+)}{-e 'do "./find.hack" if (-e "./find.hack"); $1'}g;
  return $inherited;
}

##---------------------------------------------------------------
sub MY::constants {
  package MY;
  my $css = 'dtacab.css';
  my $inherited = shift->SUPER::constants(@_);
  $inherited .= (
		 ###-- constants: html css
		 "\n"
		 ."CSS ?= $css\n"
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ###-- depends -> README.txt, CAB/Version.pm
		 "\n\n"
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt CAB/Version.pm\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		 #."blibdirs: CAB/Version.pm\n"
		 #."\n"
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

.pm.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

";

  return $inherited;
}

##---------------------------------------------------------------
sub MY::manifypods {
  package MY;
  my $inherited = shift->SUPER::manifypods(@_);
  my $out = $inherited;

  my $new = $inherited;
  my $html_ns_sep = ".";
  $new =~ s/.*(?=^manifypods\b)//sm;
  $new =~ s/\n\n.*//s;
  my ($deps0,$rules0) = split(/(?<!\\)\n/, $new, 2);
  my ($deps,$rules);

  ##-----------------------
  ## html
  my $htmlvars ='

##--- pod -> HTML

.SUFFIXES: .html

INST_CSS ?= ../../$(CSS)
#POD2HTMLFLAGS ?= --css="$(INST_CSS)" --backlink="(Back to top)" --podroot=blib --podpath=script --header
POD2HTMLFLAGS ?= --css="$(INST_CSS)" --backlink --podroot=blib --podpath=lib:script --noheader
POD2HTML ?= pod2html $(POD2HTMLFLAGS)

INST_HTMLDIR ?= blib/html

HTML_EXT ?= html
HTML1EXT ?= $(HTML_EXT)
HTML3EXT ?= $(HTML_EXT)

HTML_EXTRA ?= \
  doc-extra/elephant.raw \
  doc-extra/elephant.tei-xml \
  doc-extra/elephant.teiws-xml \
  doc-extra/elephant.teiws-ling-xml \
  doc-extra/elephant.raw.tcf \
  doc-extra/elephant.tok.tcf \
  cab-curl-post.sh \
  cab-curl-xpost.sh \
  doc-extra/spliced2norm.xsl \
  doc-extra/spliced2orig+reg.xsl \
  doc-extra/spliced2clean.xsl \
  doc-extra/spliced2cleaner.xsl \
  doc-extra/spliced2clean+cabns.xsl \
  doc-extra/spliced2cab.xsl \
  doc-extra/spliced2ling.xsl \
  doc-extra/tcf-orthswap.xsl \
  doc-extra/cab-screenshot-annotated.png

##-- lifted from MakeMaker blibdir section
$(INST_HTMLDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_HTMLDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_HTMLDIR)
	$(NOECHO) $(TOUCH) $(INST_HTMLDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/htmlifypods/;
  $deps .= "\\\n\thtmlifypods-extra";
  $deps .= "\\\n\t".'$(INST_HTMLDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2HTML/g;
  $rules =~ s/MAN(\d)EXT/HTML$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_HTMLDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${html_ns_sep}/sg if ($html_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules .= '

htmlifypods-extra: $(HTML_EXTRA) $(INST_HTMLDIR)$(DFSEP).exists
	$(CP) $(HTML_EXTRA) $(INST_HTMLDIR)

';
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2HTML) --infile=$1 | \$(PERL) pod2htmlhack.perl \\\n\t > $2 || (rm -f $2 && false)/sg;
  $out .= $htmlvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## text
  my $text_ns_sep = $html_ns_sep;
  my $textvars ='

##--- pod -> txt
.SUFFIXES: .txt

POD2TEXT ?= pod2text

INST_TEXTDIR ?= blib/txt
TEXT_EXT ?= txt
TEXT1EXT ?= $(TEXT_EXT)
TEXT3EXT ?= $(TEXT_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_TEXTDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_TEXTDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_TEXTDIR)
	$(NOECHO) $(TOUCH) $(INST_TEXTDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/textifypods/;
  $deps .= "\\\n\t".'$(INST_TEXTDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2TEXT/g;
  $rules =~ s/MAN(\d)EXT/TEXT$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_TEXTDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${text_ns_sep}/sg if ($text_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2TEXT) $1 $2/sg;
  $rules .= "\n\ntxtifypods: textifypods\n\n";
  $out .= $textvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## pod
  my $pod_ns_sep = $html_ns_sep;
  my $podvars ='

##--- pod+perl -> pod

.SUFFIXES: .pod

POD2POD ?= podselect -section ""

INST_PODDIR ?= blib/pod
POD_EXT ?= pod
POD1EXT ?= $(POD_EXT)
POD3EXT ?= $(POD_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_PODDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_PODDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_PODDIR)
	$(NOECHO) $(TOUCH) $(INST_PODDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/podifypods/;
  $deps .= "\\\n\t".'$(INST_PODDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2POD/g;
  $rules =~ s/MAN(\d)EXT/POD$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_PODDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${pod_ns_sep}/sg if ($pod_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2POD) $1 > $2/sg;
  $out .= $podvars.$deps."\n".$rules."\n\n";

  ##-- return
  return $out;
}

##---------------------------------------------------------------
sub MY::distdir {
  package MY;
  my $inherited = shift->SUPER::distdir(@_);
  my $local =
'
##-- distdir_am: hacked create_distdir for superordinate automake
DISTDIR_AM ?= $(DISTNAME).am
distdir_am:
	$(RM_RF) $(DISTDIR_AM)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \\
	  -e \'do "./find.hack" if (-e "./find.hack");\' \\
	  -e "manicopy(maniread(),\'$(DISTDIR_AM)\', \'$(DIST_CP)\');"

PMLIST_AM ?= ../doc/pm_list
pm_list: $(PMLIST_AM)
$(PMLIST_AM): $(TO_INST_PM)
	echo "$(TO_INST_PM)" | xargs -n 1 echo | grep -v "\.in$$" > $@
';
  return $inherited.$local;
}

##---------------------------------------------------------------
sub MY::postamble {
  package MY;
  my $inherited = shift->SUPER::postamble(@_);
  return $inherited;
}
