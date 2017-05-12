#!/usr/local/bin/perl -w

require 5.008004;

use strict;

# Be kind to testers, not verbose
if (exists $ENV{AUTOMATED_TESTING} and $ENV{AUTOMATED_TESTING}) {
    exists $ENV{UNIFY} or exit 0;
    }

use Cwd qw( cwd abs_path );

use ExtUtils::MakeMaker;
use Config;

use DBI 1.42;
use DBI::DBD;

print "\nConfiguring DBD::Unify ...\n\n";

$^O =~ m/^(?: VMS | MsWin32 | cygwin )$/x and
    die "No support for OS $^O (yet)\n";

use vars qw($UNIFY $UNITOP $ULIBS $ULDOPTS);

CheckUnify ();

my %wm = (
    NAME          =>   "DBD::Unify",
    DISTNAME      =>   "DBD-Unify",
    VERSION_FROM  =>   "lib/DBD/Unify.pm",
    AUTHOR        =>   "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    ABSTRACT_FROM =>   "lib/DBD/Unify.pm",

    PREREQ_PM     => { # CORE stuff
		       "Carp"		=> 0,
		       "DynaLoader"	=> 0,
		       # For unstallu.pl
		       "Config"		=> 0,
		       "Cwd"		=> 0,
		       "File::Find"	=> 0,
		       "File::Copy"	=> 0,

		       # Real deps
		       "DBI"		=> 1.42,

		       # Test deps
		       "Test::More"	=> 0.90,
		       },

    dist          => { COMPRESS => "gzip -9f",
		       SUFFIX   => ".gz",
		       },

    clean         => { FILES => "dbdimp.c dbdimp.ec Unify.ec",
		       },
    realclean     => { FILES => "Unify.xsi ulib",
		       },

    LINKTYPE      =>   "dynamic",
    INC           =>   "-I$UNITOP -I$UNITOP/include -I\$(DBI_INSTARCH_DIR)",
    OBJECT        =>   "Unify\$(OBJ_EXT) dbdimp\$(OBJ_EXT)",

    depend        => { "dbdimp\$(OBJ_EXT)" => "dbdimp.c Unify.h",
		       "Unify\$(OBJ_EXT)"  => "Unify.h",
		       },

    dynamic_lib   => { OTHERLDFLAGS => " $ULIBS \$(COMPOBJS) " .
					    "-L$UNIFY " .(
					    { hpux	=> "",
					      aix	=> "-lm",
					      dec_osf	=> "-lxnet",
					      }->{$^O}||"") . $ULDOPTS,
		       },
    macro         => { EPP    => "$UNITOP/bin/EPP",
		       EPPOPT => "",
		       CC     => ($^O eq "aix" ? "env UPPNAME='cc -E' " : "")
		       			. "$UNITOP/bin/ucc",
		       SELINUXENABLED => "/usr/sbin/selinuxenabled",
		       },
    );
my $eummv = eval $ExtUtils::MakeMaker::VERSION;
$eummv > 6.30				and $wm{LICENSE} = "perl";
$Config{myarchname} eq "ia64-hpux"	and delete $wm{macro}{CC};

my $rv = WriteMakefile (%wm);

if ($rv && <ulib/*.s[lo] >) {
    open my $mf, "<Makefile" or die "Cannot read Makefile: $!\n";
    my @MF = <$mf>;
    close $mf;
    s/\bPERL_DL_NONLAZY=\d+\s+// for @MF;
    open  $mf, ">Makefile"   or die "Cannot modify Makefile: $!\n";
    print $mf @MF;
    close $mf;
    }

sub CheckUnify
{
    unless (exists $ENV{UNIFY}) {
	print STDERR
	    "\$UNIFY not set.  This probably means that you either do not have\n",
	    "Unify products installed on your system, or you did not set up a\n",
	    "minimal runtime environment to make it work.\n";
	exit 1;
	}
    unless (exists $ENV{DBPATH}) {
	print STDERR
	    "\$DBPATH not set.  Even if your UNIFY environment might be set up\n",
	    "correctly, building and testing will need an available database.\n";
	exit 1;
	}

    $UNIFY = abs_path $ENV{UNIFY};

    -d $UNIFY		or die "\$UNIFY is not a valid directory\n";
    -d $ENV{DBPATH}	or die "\$DBPATH is not a valid directory\n";

    $UNITOP = abs_path "$UNIFY/..";
    my $cwd = cwd;

    my @sqlv = `SQL -version`;

    unlink "ulib";
    symlink $UNIFY, "./ulib";
    # Checked for A/SQL DS 6.3 AB and beyond
    my @ulibs = grep { -f "ulib/$_" } qw(
	ACCELL.a
	S2000e.a S2000c.a
	libuse.a
	U2000c.a U2000u.a U2000k.a
	U2000c.a
	S2000u.a S2000c.a U2000r.a
	libnwrpc.a libnwstcp.a
	libusu.a libudsu.a
	U2000c.a U2000u.a);
    my $localremote = prompt (
	"Link (L)ocal-only, (R)emote-only, or (B)oth? [L/r/b] >", "L");
    if    ($localremote =~ m/^\s*[Rr]/) {
	@ulibs = map { s/([0s]u)\.a/$1r.a/; $_ } @ulibs;
	}
    elsif ($localremote =~ m/^\s*[Bb]/) {
	# No change
	}
    else { # Local-only is (fastest) default
	@ulibs = map { s/([0s]u)\.a/$1l.a/; $_ } @ulibs;
	}
    $ULDOPTS = -f "ulib/libgcc.a" ? " -lgcc" : "";

    my ($rev) = ("@sqlv" =~ m/Revision:\s+(\d[.\d]*)/);
    my $dlext = $Config{dlext} || "sl";
    my $try_shared = $^O eq "hpux" && $rev >= 8.2 ? 1 : 0;
    if ($try_shared) {
	if (<ulib/*.$dlext >) {
	    my $answer = prompt ("Build a shared lib version? [Y/n] >", "Y");
	    $answer =~ m/^\s*[Qq]/   and exit;
	    $answer =~ m/^\s*[NnFf]/ and $try_shared = 0;
	    }
	elsif (-w $UNIFY) {
	    my $answer = prompt (
		"Building for rev $rev on HP-UX would support Shared Libraries\n".
		" but I don't see them (yet) in your \$UNIFY.\n".
		"Shall I try to use Shared Objects? [Y/n] >", "Y");
	    $answer =~ m/^\s*[Qq]/ and exit;
	    if ($answer =~ m/^\s*[NnFf]/) {
		$try_shared = 0;
		}
	    else {
		chdir $UNIFY or die "Cannot chdir to $UNIFY: $!\n";
		foreach my $a (<*.a >) {
		    $a eq "ACLMAIN.a" || $a eq "libgcc.a" and next;
		    (my $sl = "lib$a") =~ s/\.a$/.$dlext/o;
		    $sl =~ s/^liblib/lib/;
		    -f $sl and next;	# Already done;
		    mkdir "_a_SL" or die "Cannot create temp dir for conversion: $!";
		    chdir "_a_SL" or die "Cannot chdir to temp dir: $!";
		    print STDERR "  Converting $a ...\n";
		    system "ar x ../$a";
		    system "ld -b +s -o ../$sl *.o";
		    unlink <*.o >;
		    chdir "..";
		    rmdir "_a_SL";
		    }
		chdir $cwd;
		}
	    }
	else {
	    $try_shared = 0;
	    }
	}

    <ulib/*.s[lo] > or $try_shared = 0;
    if ($try_shared) {
	s/\.a$// for @ulibs;
	s/^lib// for @ulibs;
	$ULIBS = join " -l" => "-L$UNIFY", @ulibs;
	}
    else {
	$ULIBS = join " ulib/" => "", @ulibs;
	}
    print "\n";

    # --- Check development environment

    sub Check ($)
    {
	my $f = shift;
	-r "$UNITOP/$f" && -s _ && (-x _ || $f !~ m/^bin/) and return;
	die "I can't find $f\n".
	    "Is your Unify ($UNITOP) set up correctly??\n";
	} # Check
    Check ("bin/SQL");
    Check ("bin/EPP");
    if ($try_shared) {
	Check ("lib/lib${_}.$dlext") for @ulibs;
	}
    else {
	Check ($_) for split m/ u/ => $ULIBS;
	}

    splice @sqlv, -2, 2;
    print "System:           perl$] $^O\n",
	  "UNIFY:            $UNITOP\n",
	  @sqlv,
	  "\n";

    $UNITOP;
    } # CheckUnify

1;

package MY;

sub postamble
{
    join "\n" =>
	DBI::DBD::dbd_postamble (),
	'',
	'dbdimp.c:		dbdimp.ec Unify.h',
	'	$(EPP) $(EPPOPT) dbdimp.ec ',
	'',
	'dbdimp.ec:		dbdimp.ic',
	'	$(PERL) ic2ec dbdimp.ic > dbdimp.ec',
	'',
	'installu uinstall:	all',
	'	$(PERL) installu.pl',
	'',
	'cover test_cover:',
#	'	ccache -C',
	'	cover -test',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genPPPort_h.pl',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'	ls -l */META.yml',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'linkext::',
	'	if [ -x $(SELINUXENABLED) ] && $(SELINUXENABLED); then chcon -t textrel_shlib_t $(INST_ARCHLIB)/auto/$(FULLEXT)/$(DLBASE).so; fi',
	'',
	'install::',
	'	if [ -x $(SELINUXENABLED) ] && $(SELINUXENABLED); then chcon -t textrel_shlib_t $(INSTALLSITEARCH)/auto/$(FULLEXT)/$(DLBASE).so; fi',
	'';
    } # postamble

sub libscan
{
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
    } # libscan

1;
