#!/usr/bin/perl -w
use strict;
use File::Path 'mkpath';
use File::Copy 'copy';

my $VERSION = '0.02';			# Changelog at end
die "Debugging cycle detected"		# set to -1 to allow extra iteration
  if ++$ENV{PERL_DEBUG_MCODE_CYCLE} > 1;

my %opt;
$opt{$1} = shift while ($ARGV[0] || 0) =~ /^-([dq1])$/;
if ($opt{1}) {
  open STDERR, '>&STDOUT' or warn "can't redirect STDERR to STDOUT";
} else {
  open STDOUT, '>&STDERR' or warn "can't redirect STDOUT to STDERR";
}

my $bd = 'dbg-bld';
@ARGV >= 1 or die <<EOP;

Usage: $0 [-d] [-q] [-1] check-module [failing-script1 failing-script2 ...]

A tool to simplify remote debugging of build problems for XSUB modules.
By default, output goes to STDERR (to pass through the test suite wrappers).

If CHECK-MODULE is non-empty (and not 0) checks whether it may be
loaded (with -Mblib).  If FAILING-SCRIPTS are present, rebuilds the
current distribution with debugging (in subdirectory $bd), and
machine-code-debugs Perl crash when running each FAILING-SCRIPT.
Outputs as much info about the crash as it can massage from gdb or
dbx.

If any problem is detected, outputs the MakeMaker arguments (extracted
from the generated Makefiles).  Some minimal intelligence to avoid a
flood of useless information is applied: if CHECK-MODULE cannot be
loaded (but there is no crash during loading), no debugging for
FAILING-SCRIPTs is done.

Options:	With -d, prefers dbx to gdb (DEFAULT: prefer gdb).
		With -q and no FAILING-SCRIPTs, won't print anything unless a
			failure of loading is detected.
		With -1, all output goes to STDOUT.

Assumptions:
  Should be run in the root of a distribution, or its immediate subdir.
  Running Makefile.PL with OPTIMIZE=-g builds debugging version.
  If FAILING-SCRIPTs are relative paths, they should be local w.r.t. the
	root of the distribution.
  gdb (or dbx) is fresh enough to understand the options we throw in.
  Building in a subdirectory does not break a module (e.g., there is
	no dependence on its position in its parent distribution, if any).

Creates a subdirectory ./$bd.  Add it to `clean' in Makefile.PL.

			Version: $VERSION
EOP
my ($chk_module) = (shift);

sub report_Makefile ($) {
  my $f = shift;
  print STDERR "# reporting $f header:\n# ==========================\n";
  my ($base_d, $in) = (-f "t/sinl.t" ? '.' : '..', '');
  open M, "< $f" or die "Can't open $f";
  $in = <M> while defined $in and $in !~ /MakeMaker \s+ Parameters/xi;
  $in = <M>;
  $in = <M> while defined $in and $in !~ /\S/;
  print STDERR $in and $in = <M> while defined $in and $in =~ /^#/;
  close M;
  print STDERR "# ==========================\n";
}

# We assume that MANIFEST contains no filenames with spaces
chdir '..' or die "chdir ..: $!"
  if not -f 'MANIFEST' and -f '../MANIFEST';	# we may be in ./t

# Try to avoid debugging a code failing by some other reason than crashing.
# In principle, it is easier to do in the "trigger" code with proper BEGIN/END;
# just be extra careful, and recheck. (And we can be used standalone as well!)

# There are 4 cases detected below, with !@ARGV thrown in, one covers 8 types.
my($skip_makefiles, $mod_load_out);
if ($chk_module) {
  # Using blib may give a false positive (blib fails) unless distribution
  # is already built; but the cost is small: just a useless rebuild+test
  if (system $^X, q(-wle), q(use blib)) {
    warn <<EOW;

  Given that -Mblib fails, `perl Makefile.PL; make' was not run here yet...
  I can't do any intelligent pre-flight testing now;

EOW
    die "Having no FAILING-SCRIPT makes no sense when -Mblib fails"
      unless @ARGV;
    warn <<EOW;
  ... so I just presume YOU know that machine-code debugging IS needed...

EOW
    $skip_makefiles = 1;
  } else {	#`
    # The most common "perpendicular" problem is that a loader would not load DLL ==> no crash.
    # Then there is no point in running machine code debugging; try to detect this:
    my $mod_load = `$^X -wle "use blib; print(eval q(use $chk_module; 1) ? 123456789 : 987654321)" 2>&1`;
    # Crashes ==> no "digits" output; DO debug.  Do not debug if no crash, and no load
    if ($mod_load =~ /987654321/) { # DLL does not load, no crash
      $mod_load_out = `$^X -wle "use blib; use $chk_module" 2>&1`;
      warn "Module $chk_module won't load: $mod_load_out";
      @ARGV = ();		# machine-code debugging won't help
    } elsif ($mod_load =~ /123456789/) { # Loads OK
      # a (suspected) failure has a chance to be helped by machine-code debug
      ($opt{'q'} or warn(<<EOW)), exit 0 unless @ARGV;

Module loads without a problem.  (No FAILING-SCRIPT, so I skip debugging step.)

EOW
    }				# else: Crash during DLL load.  Do debug
  }
}
unless ($skip_makefiles) {
  report_Makefile($_) for grep -f "$_.PL" && -f, map "$_/Makefile", '.', <*>;
}
exit 0 unless @ARGV;

my $gdb = `gdb --version` unless $opt{d};
my $dbx = `dbx -V -c quit` unless $gdb;
$gdb = `gdb --version` unless $gdb or $dbx;
die "Can't find gdb or dbx" unless defined $gdb or defined $dbx;
die "Can't parse output of gdb --version"
  unless $dbx or $gdb =~ /\b GDB \b | \b Copyright \b .* \b Free Software \b/x;
die "Can't parse output of `dbx -V -c quit'"
  unless $gdb or $dbx =~ /\b dbx \s+ debugger \b/xi;

die "Directory $bd exist; won't overwrite" if -d $bd;
mkdir $bd or die "mkdir $bd: $!";
chdir $bd or die "chdir $bd: $!";

open MF, '../MANIFEST' or die "Can't read MANIFEST: $!";
while (<MF>) {
  next unless /^\S/;
  s/\s.*//;
  my ($f, $d) = m[^((.*/)?.*)];
  -d $d or mkpath $d if defined $d;	# croak()s itself
  copy "../$f", $f or die "copy `../$f' to `$f' (inside $bd): $!";
}
close MF or die "Can't close MANIFEST: $!";

system $^X, qw(Makefile.PL OPTIMIZE=-g) and die "system(Makefile.PL OPTIMIZE=-g): rc=$?";
system 'make' and die "system(make): rc=$?";

my $p = ($^X =~ m([\\/]) ? $^X : `which perl`) || $^X;
chomp $p unless $p eq $^X;
my(@cmd, $ver);

for my $script (@ARGV) {
  if ($gdb) {
    $ver = $gdb;
    my $gdb_in = 'gdb-in';
    open TT, ">$gdb_in" or die "Can't open $gdb_in for write: $!";
    # bt full: include local vars (not in 5.0; is in 6.5; is in 6.1, but crashes on 6.3:
	# http://www.cpantesters.org/cpan/report/2fffc390-afd2-11df-834b-ae20f5ac70d3)
    # disas /m : with source lines (FULL function?!) (not in 6.5; is in 7.0.1)
    # XXX all-registers may take 6K on amd64; maybe put at end?
    my $proc = (-d "/proc/$$" ? <<EOP : '');
info proc mapping
echo \\n=====================================\\n\\n
EOP
    print TT <<EOP;		# Slightly different order than dbx...
run -Mblib $script
echo \\n=====================================\\n\\n
bt
echo \\n=====================================\\n\\n
info all-registers
echo \\n=====================================\\n\\n
disassemble
echo \\n=====================================\\n\\n
bt 5 full
echo \\n=====================================\\n\\n
$proc disassemble /m
quit
EOP
    close TT or die "Can't close $gdb_in for write: $!";

    #open STDIN, $gdb_in or die "cannot open STDIN from $gdb_in: $!";
    @cmd = (qw(gdb -batch), "--command=$gdb_in", $p);
  } else {			# Assume $script has no spaces or metachars
	# Linux: /proc/$proc/maps has the text map
	# Solaris: /proc/$proc/map & /proc/$proc/rmap: binary used/reserved
	#   /usr/proc/bin/pmap $proc (>= 2.5) needs -F (force) inside dbx
    $ver = $dbx;
    # where -v		# Verbose traceback (include function args and line info)
    # dump                  # Print all variables local to the current procedure
    # regs [-f] [-F]        # Print value of registers (-f/-F: SPARC only)
    # list -<n>             # List previous <n> lines (next with +)
    #   -i or -instr        # Intermix source lines and assembly code
    @cmd = (qw(dbx -c),		# We do not do non-integer registers...
	    qq(run -Mblib $script; echo; echo =================================; echo; where -v; echo; echo =================================; echo; dump; echo; echo =================================; echo; regs; echo; echo =================================; echo; list -i +1; echo; echo =================================; echo; list -i -10; echo; echo =================================; echo; echo ============== up 1:; up; dump; echo; echo ============== up 2:; up; dump; echo; echo ============== up 3:; up; dump; echo; echo ============== up 4:; up; dump; echo ==============; /usr/proc/bin/pmap -F \$proc; quit),
	    $p);
  }
  system @cmd and die "Running @cmd: rc=$?";
  print $ver;
}
1;

__END__

# Changelog:
0.01	Print version of the debugger at end
	For GDB, protect against non-present disassemble /m
0.02	Add process memory map (for gdb; for dbx at least under Solaris)
