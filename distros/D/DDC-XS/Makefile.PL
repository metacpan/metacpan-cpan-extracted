use 5.006001; ##-- from xspp Makefile.PL
use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Configuration
##----------------------------------------------------------------------
use Alien::DDC::Concordance;
my %prereq = (
	      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
	      'Alien::DDC::Concordance' => 0.007,
	      'ExtUtils::XSpp' => '0.18',
	      'JSON' => 0,

	      'Test::More'=>0, ##-- 1.001002
	     );

##-- ensure mininum ddc version
my $min_version = "2.2.8";
if (Alien::DDC::Concordance->install_type ne 'system') {
  my $alien_vstr = Alien::DDC::Concordance->config('version');
  (my $alien_version = $alien_vstr) =~ s/\-/_/g;
  $alien_version =~ s/[^0-9\._]//g; ##-- 2020-12-09: version->parse() doesn't like "_rc2" suffix
  die("Required package ddc >= v$min_version not found; we have v$alien_vstr (via Alien::DDC::Concordance v$Alien::DDC::Concordance::VERSION)\n")
    if (version->parse($alien_version) < version->parse($min_version));
}
elsif (system("pkg-config --atleast-version=${min_version} ddc") != 0) {
  my ($got_version) = map {chomp;$_} `pkg-config --modversion ddc`;
  die("Required package ddc >= v$min_version not found; we have v$got_version (maybe try updating Alien::DDC::Concordance?)");
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'DDC::XS',
   #DISTNAME	=> 'ddc-perl-xs',
   #DISTNAME	=> 'DDC::XS',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Perl interface to libDDC* ddc concordance libraries',
   VERSION_FROM	=> 'XS.pm',
   LICENSE      => 'perl_5',
   META_MERGE   => {
		    'meta-spec' => { version => 2 }, ##-- doesn't seem to work
		    resources  => {
				   repository => {
						  type => 'svn',
						  url => 'svn://svn.code.sf.net/p/ddc-concordance/code/ddc-perl-xs/',
						  web => 'https://sourceforge.net/p/ddc-concordance/code/HEAD/tree/ddc-perl-xs/',
						 },
				  },
		    prereqs => {
				runtime => {
					    recommends => {
							   #'DDC::Concordance' => 0.24,
							  },
					    suggests => {
							 'DDC::Concordance' => 0.24,
							},
					   },
			       },
		   },

   ##-- prerequisites
   ##  + 2016-11-23: copy refs to avoid "ExtUtils::MakeMaker::YAML does not support circular references" errors
   ##    - there are in fact no *circular* references here, just shared ones, so the error message is misleading
   CONFIGURE_REQUIRES => { %prereq },
   PREREQ_PM => { %prereq },


   ##-- user variables
   CC           => 'c++',   ##-- your c++ compiler
   LD		=> '$(CC)',
   LIBS         => Alien::DDC::Concordance->libs,	##-- additional libraries
   INC          => Alien::DDC::Concordance->cflags,	##-- additional includes
   DEFINE       => '-DHAVE_CONFIG_H',			##-- additional defines
   CCFLAGS      => '',					##-- additional compiler flags
   OPTIMIZE    => '-O2 -pipe',				##-- optimization flags
   #OBJECT       => '',

   ##-- install these
   #EXE_FILES => [glob("bin/*.perl")],
   EXE_FILES => [],

   ##-- DEBUG
   #MAKEAPERL=>1,
   #LINKTYPE=>'static',
   #MAP_TARGET=>'gfsmperl',
   #CCFLAGS=>'-g',
   ##-- /DEBUG

   ##-- stuff that probably doesn't need to be changed
   #XSOPT        => '-C++',
   XSOPT        => '-C++ -hiertype', ##-- from xspp Makefile.PL
   TYPEMAPS     => ['perlobject.map', 'typemap'],
  );


#-----------------------------------------------------------------------
# Extensions

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ##-- depends -> README.txt
		 "\n\n"
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		 ##-- included xs dependencies
		 ."\n\n"
		 ."XS.c: "
		 .(''
		   ." XS.xs"
		   ." Constants.xs"
		   ." Object.xsp"
		   ." QueryCompiler.xsp"
		   ." Query.xsp"
		   ." QCount.xsp"
		   ." QueryFilter.xsp"
		   ." QueryOptions.xsp"
		   #." dummy.xs"
		  )
		 ."\n\n"
		 ##-- c->o dependencies
		 ."XS.o: XS.c ddcxs.h\n"
		 ."\n"
		 ## -- more here
		 ."\n"
		);
  $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  return $inherited."
.SUFFIXES: .pm .pod .rpod .man .txt .html

##-- README: special handling
readme: README.txt README.html

README.html : README.rpod
\tpod2html --infile=README.rpod --outfile=README.html --title='DDC-perl-xs README'

.rpod.txt:
\tpod2text \$< \$@
";
}
