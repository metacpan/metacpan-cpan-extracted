# -*- perl -*-

# Copyright (c) 2009-2023 H.Merijn Brand

require 5.008001;

use strict;

use ExtUtils::MakeMaker;
use File::Spec;

eval { require DBI;      };
if ($@) {
    print <<"MSG";

DBD::CSV requires DBI and it cannot be loaded:
$@

Please be sure your toolchain picks up the dependency requirement and
installs DBI before tests start

MSG
    sleep 10;
    }
if ($DBI::VERSION < 1.628) {
    print <<"MSG";

Trying to use DBD::CSV with DBI-$DBI::VERSION is heading for failure.
DBD::CSV is relying on DBD::File, bundled in the DBI release and does
require features not present in this version of DBI.

Please be sure your toolchain picks up the dependency requirement and
installs DBI-1.628 or newer before tests start

MSG
    sleep 10;
    }
eval { require DBD::CSV; };
if (!$@ && $DBD::CSV::VERSION < 0.1010) {
    print <<'MSG';

WARNING!  You seem to have installed a recent version of the DBD::CSV module.
Note that the API (in particular attribute names) has changed, to conform to
the DBI specifications.  For example  $dbh->{directory}  has been renamed to
$dbh->{f_dir} and $dbh->{eol}, $dbh->{quote_char}, ... are gone in favour of
$dbh->{tables}{$table}{csv}, which is used for storing meta information. You
might need to modify existing sources before doing a "make install". See the
README for details.

MSG
    sleep 5;
    }

use vars qw( $DBI_INC_DIR );

{   my $tmp_dir = File::Spec->tmpdir ();
    if (!$ENV{AUTOMATED_TESTING} &&
         prompt ("Enable the use of $tmp_dir for tests?", "y") =~ m/[Yy]/) {
	unlink "tests.skip";
	}
    else {
	open my $fh, ">", "tests.skip";
	print $fh "tmpdir\n";
	close $fh;
	}
    }
my %wm = (
    NAME         => "DBD::CSV",
    DISTNAME     => "DBD-CSV",
    ABSTRACT     => "DBI driver for CSV and similar structured files",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM => "lib/DBD/CSV.pm",
    PREREQ_PM    => {
	"DBI"            => 1.628,
	"DBD::File"      => 0.42,
	"Text::CSV_XS"   => 1.01,
	"SQL::Statement" => 1.405,
	"Test::More"     => 0.90,
	"Encode"         => 0,
	"charnames"      => 0,
	},
    clean        => {
	FILES => join " ", qw(
	    output
	    cover_db
	    valgrind.log
	    )
	},
    macro        => {
	TARFLAGS => "--format=ustar -c -v -f",
	},
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

# Windows is case-insensitive! Do not remove lib.pl and tmp.csv
$File::Path::VERSION > 2.06 and File::Path::remove_tree (glob "t/[bA-KM-SU-Z]*");

eval "use DBI::Test::Conf ();";
if ($@) {
#   warn "******\n",
#        "******\tDBI::Test is not installed.\n",
#        "******\tIt will be required in one of the upcoming releases.\n",
#        "******\n";
    }
else {
    use lib "lib";

    local $" = " ";
    $wm{PREREQ_PM}{"DBI::Test"} = "0.001";
    my @nt = DBI::Test::Conf->setup (CONTAINED_DBDS => [qw( CSV )]);
    $wm{test} = { TESTS => join " " => (sort glob "t/*.t"), @nt };
    $wm{clean}{FILES} .= " @nt";
    }

my $rv = WriteMakefile (%wm);

# perlcriticrc uses Config::Tiny, which does not support nesting
if (-f ".perlcriticrc" && -s "$ENV{HOME}/.perlcriticrc") {
    open my $fh, ">", ".perlcriticrc";
    print $fh do {
	local (@ARGV, $/) = ("$ENV{HOME}/.perlcriticrc"); <> };
    print $fh join "\n" => "",
	"[-Modules::ProhibitMultiplePackages]",
	"[-Subroutines::ProhibitBuiltinHomonyms]", # connect
	"[-ValuesAndExpressions::RestrictLongStrings]",	# error message
	"[-Variables::ProhibitPackageVars]", # very deliberate for compatability
	"[-Variables::ProhibitReusedNames]", # @ISA
	"";
    close $fh;
    }

1;

package MY;

sub postamble {
    my $min_vsn = ($] >= 5.010 && -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env DBI_SQL_NANO=1 make -e test_dynamic TEST_FILES=t/[1-9]*.t',
	    '',
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover test_cover:',
	'	cover -test',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/DBD-CSV.md doc/DBD-CSV.html doc/DBD-CSV.man',
	'	-@rm -f pod2html.tmp',
	'doc/DBD-CSV.md:		lib/DBD/CSV.pm',
	'	pod2markdown  < $? > $@',
	'doc/DBD-CSV.html:		lib/DBD/CSV.pm',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/DBD-CSV.3:		lib/DBD/CSV.pm',
	'	pod2man       < $? > $@',
	'doc/DBD-CSV.man:	doc/DBD-CSV.3',
	'	nroff -mandoc < $? > $@',
	$min_vsn;
    } # postamble
