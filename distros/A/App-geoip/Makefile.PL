use 5.014000;
use warnings;

use ExtUtils::MakeMaker;

-f "lib/App/geoip.pm" or system $^X, "./2lib";

my $VERSION;
open my $fh, "<", "geoip";
while (<$fh>) {
    m/VERSION\s*=\s*["']?([0-9.]+)/ or next;
    $VERSION = $1;
    last;
    }
close $fh;

my %wmf = (
    NAME		=> "App::geoip",
    DISTNAME		=> "App-geoip",
    ABSTRACT		=> "Show geographical data based on hostname or IP address(es)",
    AUTHOR		=> "H.Merijn Brand",
    EXE_FILES		=> [ "geoip" ],
    VERSION		=> $VERSION,
    MIN_PERL_VERSION	=> "5.14.0",
    PREREQ_PM		=> {
	"DBI"		=> 0,
	"Socket"	=> 0,
	"Net::CIDR"	=> 0,
	"Data::Dumper"	=> 0,
	"Math::Trig"	=> 0,
	"LWP::Simple"	=> 0,
	"Archive::Zip"	=> 0,
	"Text::CSV_XS"	=> "1.39",
	"JSON::PP"	=> 0,
	"Pod::Text"	=> 0,
	"List::Util"	=> 0,
	"Getopt::Long"	=> 0,
	},
    LICENSE		=> "artistic_2",
    CONFIGURE_REQUIRES	=> { "ExtUtils::MakeMaker" => 0 },
    TEST_REQUIRES	=> { "Test::More"          => 0 },
    macro		=> { TARFLAGS => "--format=ustar -c -v -f", },

    META_MERGE			=> {
	"meta-spec"		=> { version => 2 },
	licence			=> "artistic_2",
	resources		=> {
	    type		=> "git",
	    url			=> "git://github.com/Tux/GeoIP2.git",
	    web			=> "https://github.com/Tux/GeoIP2",
	    IRC			=> "irc://irc.perl.org/#csv",
	    },
	provides		=> {
	    "App::geoip"	=> {
		file		=> "geoip",
		version		=> $VERSION,
		},
	    },
	},
    );

eval { ExtUtils::MakeMaker->VERSION (6.63_03) } or
    delete $wmf{TEST_REQUIRES};

my $rv = WriteMakefile (%wmf);

# perlcriticrc uses Config::Tiny, which does not support nesting
-f ".perlcriticrc" && -s "$ENV{HOME}/.perlcriticrc" and eval {
    open my $fh, ">", ".perlcriticrc";

    require Config::Tiny;
    my $cnf = Config::Tiny->read ("$ENV{HOME}/.perlcriticrc");
    for ("ControlStructures::ProhibitPostfixControls",	# postfix if in diag
         "Freenode::PackageMatchesFilename",		# XS
	 "Subroutines::ProhibitBuiltinHomonyms",	# eof, say
	 "ErrorHandling::RequireCarping",		# for autodie
	 "BuiltinFunctions::ProhibitBooleanGrep",
	 "Variables::RequireLocalizedPunctuationVars",	# *_, %_
	 ) {
	delete $cnf->{$_};
	$cnf->{"-$_"} = {};
	}
    $cnf->{"Compatibility::PodMinimumVersion"}
	{above_version} = "5.014";	# For L<> and =head3
    $cnf->write (".perlcriticrc");
    };

1;

package MY;

sub postamble {
    my @mpm = (-d ".git" || -x "2lib")
        ? ("", "lib/App/geoip.pm: geoip\n\t$^X ./2lib\n")
        : ();
    -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1 and
	push @mpm =>
	    '',
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic';
    join "\n" =>
        'spellcheck:',
        '	pod-spell-check --aspell --ispell geoip',
        '',
        'META.json META.yml:	geoip',
        '	-@make metafile',
        '	-@mv $(DISTVNAME)/META.* .',
        '	-@rm -rf $(DISTVNAME)',
        '',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
        'tgzdist:	lib/App/geoip.pm checkmeta fixmeta spellcheck doc $(DISTVNAME).tar.gz distcheck',
        '	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
        '	-@cpants_lint.pl $(DISTVNAME).tgz',
        '	-@rm -f Debian_CPANTS.txt',
        '',
	'doc:			doc/geoip.md doc/geoip.html doc/geoip.man',
	'doc/geoip.md:		geoip',
	'	pod2markdown  < $? > $@',
	'doc/geoip.html:	geoip',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/geoip.3:		geoip',
	'	pod2man       < $? > $@',
	'doc/geoip.man:	doc/geoip.3',
	'	nroff -mandoc < $? > $@',
        @mpm;
    } # postamble

1;
