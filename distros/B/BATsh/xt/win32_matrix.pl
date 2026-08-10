######################################################################
#
# xt/win32_matrix.pl  Run the test suite over a matrix of Windows
#                     environments, from one Windows box
#
# WHY
#   Every Windows FAIL this distribution has received passed on the
#   author's own Windows machine first.  The suite was green there
#   because it had been run once, in one environment; the smokers run it
#   in environments that differ in ways the suite turned out to care
#   about:
#
#     HOME shape         C:\home\x  C:/home/x  C:\home\x\  "C:\ho me\x"
#                        and not set at all
#     working drive      the same drive as HOME, or a different one
#                        (Windows keeps a current directory PER DRIVE)
#     ANSI code page     932 (Japanese) or 65001 (UTF-8), which decides
#                        whether a CP932 file name can exist at all
#     perl               5.005_03 ... 5.42; the smokers have sent
#                        5.8.9, 5.18.4 and 5.42.0 so far
#     the environment    a smoker has no PERL5LIB, no PERL5OPT, no
#                        PERLIO or PERL_UNICODE, no interactive STDIN,
#                        and AUTOMATED_TESTING set; the author's shell
#                        has the opposite of all of that
#
#   Each of the three t/0020 failures, and the t/0015 and t/0019 ones,
#   would have been caught here before upload.  See rule R5 in
#   t/lib/BATsh_TestOS.pm.
#
#   The environment axis is rule R6, and it is why every cell runs in a
#   SCRUBBED environment by default rather than in the author's.  A cell
#   that inherits the author's %ENV reproduces the author's box, which
#   is the one machine already known to pass; reproducing the smoker is
#   the entire point.  --env=inherited or --env=both widens it back when
#   the question is specifically whether something works interactively.
#
# USAGE
#   From the distribution root, after "perl Makefile.PL && dmake":
#
#     perl xt\win32_matrix.pl                  run the whole matrix
#     perl xt\win32_matrix.pl t\0020*.t        only these test files
#     perl xt\win32_matrix.pl --list           show the matrix, run none
#     perl xt\win32_matrix.pl --perl=C:\perl5.005_03\bin\perl.exe
#                                              run it under another perl
#                                              (repeatable)
#     perl xt\win32_matrix.pl --cp=932         only this ANSI code page
#                                              (repeatable; "-" selects
#                                              the inherited one)
#     perl xt\win32_matrix.pl --home=space-in-name
#                                              only this HOME shape
#                                              (repeatable)
#     perl xt\win32_matrix.pl --env=both       run each cell twice, once
#                                              in the scrubbed smoker
#                                              environment (the default)
#                                              and once in the inherited
#                                              one.  --env=inherited
#                                              runs only the latter
#     perl xt\win32_matrix.pl --no-other-drive skip the second working
#                                              drive and the D:..Z: probe
#                                              that looks for one
#     perl xt\win32_matrix.pl --help           this text
#
# RUNNING TIME
#   The full Windows matrix is 15 cells, or 30 when a second drive is
#   found, and every cell starts all of the test files in a fresh child
#   perl -- there is no harness to amortise the process starts.  A full
#   run therefore takes tens of minutes on Windows, where creating a
#   process is an order of magnitude dearer than it is on Unix.
#
#   Because that is long enough to be mistaken for a hang, progress is
#   printed as it happens: one dot per test file, "F" for a file that
#   failed, "x" for a cell that could not even be entered, and a line
#   per cell carrying its elapsed time.  STDOUT is unbuffered, so a
#   terminal that has stopped moving means the run is genuinely stuck
#   rather than merely slow.  The first cell's elapsed time multiplied
#   by the cell count is a good estimate for the whole run.
#
#   One thing can block before any output at all: the D:..Z: probe that
#   looks for a second working drive.  An empty optical drive, or a
#   mapped network drive whose server has gone away, can make -d on that
#   letter hang or raise a "there is no disk in the drive" dialog that
#   may open behind the console window.  --no-other-drive skips the
#   probe entirely.
#
#   Every cell is run in a child perl with a modified environment; the
#   parent's own %ENV is not disturbed.  The exit status is the number
#   of cells that failed, so it can gate a release script.
#
#   This is a maintainer tool.  It is not part of "make test" and is
#   never run by a CPAN installer or a smoker.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use File::Spec ();
use File::Find ();
use File::Copy ();
use Cwd ();

# A cell is minutes long and prints nothing but single characters while
# it runs, so the stream must not sit in a buffer: an idle terminal has
# to mean an idle program.
$| = 1;

# The dist root as the OS itself spells it: reached with chdir() and
# read back with cwd(), never with realpath() -- see rule R1.
my $ROOT = do {
    my $save = Cwd::cwd();
    chdir(File::Spec->catdir($FindBin::RealBin, File::Spec->updir))
        or die "cannot reach the distribution root: $!";
    my $dir = Cwd::cwd();
    chdir($save);
    $dir;
};

my $IS_WIN = ($^O =~ /^(?:MSWin32|dos|os2)$/) ? 1 : 0;

######################################################################
# Command line
######################################################################
my @perls;
my @files;
my @want_cp;
my @want_home;
my @envmodes;
my $list_only       = 0;
my $no_other_drive  = 0;
my $no_build_paths  = 0;
for my $arg (@ARGV) {
    if    ($arg eq '--help')             { usage(); exit 0 }
    elsif ($arg eq '--list')             { $list_only = 1 }
    elsif ($arg eq '--no-other-drive')   { $no_other_drive = 1 }
    elsif ($arg eq '--no-build-paths')   { $no_build_paths = 1 }
    elsif ($arg =~ /^--perl=(.+)\z/)     { push @perls, $1 }
    elsif ($arg =~ /^--home=(.+)\z/)     { push @want_home, $1 }
    elsif ($arg =~ /^--env=(.+)\z/)      {
        my $v = lc($1);
        if    ($v eq 'both')      { @envmodes = ('smoker', 'inherited') }
        elsif ($v eq 'smoker')    { @envmodes = ('smoker') }
        elsif ($v eq 'inherited') { @envmodes = ('inherited') }
        else { die "unknown --env value: $1 (smoker, inherited or both)\n" }
    }
    elsif ($arg =~ /^--cp=(.+)\z/)       {
        my $v = $1;
        $v = '' if $v eq '-' || lc($v) eq 'inherited';
        push @want_cp, $v;
    }
    elsif ($arg =~ /^--/)                { die "unknown option: $arg\n" }
    else                                 { push @files, $arg }
}
push @perls, $^X unless @perls;
push @envmodes, 'smoker' unless @envmodes;

######################################################################
# The environment axis (rule R6).
#
# @SCRUB is the set of variables that make the author's box unlike a
# smoker's.  PERL5LIB and PERL5OPT are the ones that matter most: a
# distribution whose tests only pass because the author's PERL5LIB
# points at something is green locally and red everywhere else, and
# nothing in a local run says so.  PERLIO and PERL_UNICODE change the
# bytes that reach a file name.  The HARNESS_ variables are set by the
# harness the author is running inside and not by the child a smoker
# starts.  LANG and the LC_ variables decide the text of a diagnostic,
# which is why rule R2 exists.
#
# @SET is what a smoker actually does set, and what a distribution is
# expected to honour: no prompting, no interactive fallback.
#
# The whole of %ENV is not replaced.  PATH, COMSPEC, SystemRoot and the
# rest have to survive or no child perl starts at all; a smoker keeps
# them too.
######################################################################
my @SCRUB = qw(
    PERL5LIB PERL5OPT PERLIO PERL_UNICODE
    PERL_MM_OPT PERL_MB_OPT PERL5DB PERLDB_OPTS
    HARNESS_ACTIVE HARNESS_OPTIONS HARNESS_PERL_SWITCHES HARNESS_TIMER
    LANG LANGUAGE LC_ALL LC_CTYPE LC_MESSAGES
);
my @SET = qw(
    AUTOMATED_TESTING NONINTERACTIVE_TESTING PERL_MM_USE_DEFAULT
);


unless (@files) {
    local *MATRIX_DH;
    my $tdir = File::Spec->catdir($ROOT, 't');
    opendir(MATRIX_DH, $tdir) or die "cannot read $tdir: $!";
    my @names = sort readdir(MATRIX_DH);
    closedir(MATRIX_DH);
    for my $nm (@names) {
        next unless $nm =~ /\.t\z/;
        push @files, File::Spec->catfile($tdir, $nm);
    }
}
die "no test files\n" unless @files;

sub usage {
    print "usage: perl xt/win32_matrix.pl [options] [test files]\n";
    print "  --list             show the matrix and run nothing\n";
    print "  --perl=PATH        run under this perl (repeatable)\n";
    print "  --cp=NNN           only this ANSI code page (repeatable;\n";
    print "                     \"-\" selects the inherited one)\n";
    print "  --home=NAME        only this HOME shape (repeatable)\n";
    print "  --env=MODE         smoker (default), inherited, or both\n";
    print "  --no-other-drive   skip the second working drive and the\n";
    print "                     D:..Z: probe that looks for one\n";
    print "  --no-build-paths   skip the copies of the tree into awkwardly\n";
    print "                     named directories (rule R8)\n";
    print "  --help             this text\n";
    print "\n";
    print "A full Windows matrix is 30 cells, or 60 when a second drive\n";
    print "is found, and takes tens of minutes.  --list prints the exact\n";
    print "count for this machine without running anything.  Progress is\n";
    print "printed per test file as it happens.\n";
    return 1;
}

######################################################################
# The HOME shapes.
#
# A real directory is created for each, so that the cases which write
# into $HOME have somewhere to write.  The spellings below (five on
# Windows, four elsewhere, since only Windows can spell one directory
# with both separators) are the ones that have actually differed in
# behaviour: the trailing-separator
# form makes "$HOME/sub" contain a doubled separator, the forward-slash
# form is what git-for-Windows and MSYS set, and the space form is the
# one quote handling gets wrong.  The unset form matters because a case
# that skips when HOME is missing is a case that has never run.
######################################################################
my $BASE = File::Spec->catdir(
    File::Spec->tmpdir(), "batsh_matrix_$$");
mkdir($BASE, 0700);

sub make_home {
    my ($leaf) = @_;
    my $dir = File::Spec->catdir($BASE, $leaf);
    mkdir($dir, 0700);
    # Something for existing_entry() to find, so that t/0020 TE01 probes
    # rather than skips.
    mkdir(File::Spec->catdir($dir, 'anchor'), 0700);
    return $dir;
}

my @homes;
if ($IS_WIN) {
    my $plain = make_home('plain');
    my $space = make_home('with space');
    my $fwd   = $plain;
    $fwd =~ s{\\}{/}g;
    push @homes, ['backslash',        $plain],
                 ['forward-slash',    $fwd],
                 ['trailing-sep',     $plain . "\\"],
                 ['space-in-name',    $space],
                 ['unset',            undef];
}
else {
    my $plain = make_home('plain');
    my $space = make_home('with space');
    push @homes, ['plain',         $plain],
                 ['trailing-sep',  $plain . '/'],
                 ['space-in-name', $space],
                 ['unset',         undef];
}

if (@want_home) {
    my %keep;
    for my $w (@want_home) { $keep{$w} = 1 }
    my @sel = grep { $keep{$_->[0]} } @homes;
    die "no HOME shape matches: @want_home\n" unless @sel;
    @homes = @sel;
}

######################################################################
# The working directories.  Windows keeps a current directory per drive,
# and a relative probe (rule R1) behaves differently when the target is
# on another drive, so run once from the distribution root and once from
# a directory on a different drive if one can be found.
#
# The probe below is the one thing here that can block before the report
# is printed, which is why --no-other-drive exists.
######################################################################
my @workdirs = (['dist-root', $ROOT]);
if ($IS_WIN && !$no_other_drive) {
    my ($rootvol) = File::Spec->splitpath($ROOT);
    $rootvol = uc($rootvol);
    for my $letter ('D' .. 'Z') {
        my $other = "$letter:\\";
        next if uc("$letter:") eq $rootvol;
        next unless -d $other;
        push @workdirs, ["drive-$letter", $other];
        last;
    }
}

######################################################################
# The BUILD PATH spellings (rule R8).
#
# Every axis above varies something OUTSIDE the distribution, and that
# is exactly how a whole class of failure stayed invisible: $HOME was
# tried in five shapes while the directory the distribution itself sat
# in was only ever tried in one, the author's.  A tester's is not the
# author's -- on Windows "C:\Users\John Doe\...", "C:\Documents and
# Settings\..." and "C:\Program Files (x86)\..." are ordinary -- and a
# case that interpolates $FindBin::Bin into shell source behaves
# differently in each.  So the tree is copied to a directory named that
# way and the suite is run from the copy.
#
# The copy is plain File::Find + File::Copy so that it works on
# 5.005_03; blib/ is skipped because the cells add -I explicitly.
######################################################################
my @buildpaths = (['as-is', $ROOT]);
if (!$no_build_paths) {
    my $base = File::Spec->catdir($BASE, 'bp');
    mkdir($base, 0700);
    for my $spell ('with space', 'paren (x86)') {
        my $dest = File::Spec->catdir($base, $spell);
        if (copy_tree($ROOT, $dest)) {
            push @buildpaths, [$spell, $dest];
        }
        else {
            print "  (build path '$spell' skipped: cannot copy the tree)\n";
        }
    }
}

######################################################################
# The ANSI code pages.  chcp is a cmd.exe built-in, so the cell has to
# run through cmd; a cell whose chcp fails is reported, not silently
# dropped.
######################################################################
my @codepages = ('');
if ($IS_WIN) { @codepages = ('', '932', '65001') }
if (@want_cp) { @codepages = @want_cp }

######################################################################
# Report the matrix
######################################################################
my $cells = scalar(@perls) * scalar(@homes)
          * scalar(@workdirs) * scalar(@codepages) * scalar(@envmodes)
          * scalar(@buildpaths);
my $starts = $cells * scalar(@files);
print "BATsh Windows matrix\n";
print "  root      : $ROOT\n";
print "  platform  : $^O", ($IS_WIN ? '' : ' (not Windows -- reduced matrix)'), "\n";
print "  perls     : ", join(', ', @perls), "\n";
print "  homes     : ", join(', ', map { $_->[0] } @homes), "\n";
print "  workdirs  : ", join(', ', map { $_->[0] } @workdirs), "\n";
print "  buildpath : ", join(', ', map { $_->[0] } @buildpaths), "\n";
print "  codepages : ",
      join(', ', map { $_ eq '' ? '(inherited)' : $_ } @codepages), "\n";
print "  envs      : ", join(', ', @envmodes), "\n";
print "  files     : ", scalar(@files), "\n";
print "  cells     : $cells\n";
print "  starts    : $starts child perl run(s)\n";
print "\n";
if ($list_only) {
    cleanup();
    exit 0;
}
print "one dot per test file, F = failed file, x = cell not entered\n\n";

######################################################################
# Run
######################################################################
my $failed  = 0;
my $ran     = 0;
my $started = time();
for my $perl (@perls) {
  for my $bp (@buildpaths) {
    for my $home (@homes) {
        for my $wd (@workdirs) {
            for my $cp (@codepages) {
              for my $envmode (@envmodes) {
                $ran++;
                printf("cell %d/%d  %s  home=%s  wd=%s  cp=%s  env=%s  bp=%s\n",
                       $ran, $cells, short_perl($perl), $home->[0],
                       $wd->[0], ($cp eq '' ? '-' : $cp), $envmode, $bp->[0]);
                print '  ';
                my $t0 = time();
                my ($bad, $detail) = run_cell($perl, $home->[1],
                                              $wd->[1], $cp, $envmode,
                                              $bp->[1]);
                my $secs = time() - $t0;
                print '  ',
                      ($bad ? "FAIL -- $bad file(s)" : 'ok'),
                      " -- ${secs}s\n";
                print @{$detail};
                $failed++ if $bad;
                if ($ran == 1 && $cells > 1) {
                    my $est = $secs * $cells;
                    print "  (at this rate the whole matrix takes about ",
                          int(($est + 59) / 60), " minute(s))\n";
                }
              }
            }
        }
    }
  }
}

printf("\n%d cell(s), %d failed, %d second(s) total\n",
       $ran, $failed, time() - $started);
cleanup();
exit($failed ? 1 : 0);

######################################################################
# run_cell -- one environment, all the requested test files, in a child
# perl.  Prints one character per file as it goes, and returns the
# number of test files that did not exit 0 together with the diagnostic
# lines to print once the progress line is complete.
######################################################################
sub run_cell {
    my ($perl, $home, $workdir, $cp, $envmode, $root) = @_;
    $root = $ROOT unless defined $root && $root ne '';

    my $save_env  = save_env();
    my $save_cwd  = Cwd::cwd();
    my $bad = 0;
    my @detail;

    apply_smoker_env() if $envmode eq 'smoker';

    if (defined $home) { $ENV{'HOME'} = $home }
    else               { delete $ENV{'HOME'} }

    unless (chdir($workdir)) {
        print 'x';
        push @detail, "---- cannot chdir to $workdir: $!\n";
        restore_env($save_env);
        return (1, \@detail);
    }

    my $libs = join(' ',
        '-I' . quote(File::Spec->catdir($root, 'blib', 'lib')),
        '-I' . quote(File::Spec->catdir($root, 'lib')),
        '-I' . quote(File::Spec->catdir($root, 't', 'lib')));

    for my $file (@files) {
        my $abs = File::Spec->rel2abs($file, $root);
        my $cmd = quote($perl) . " $libs " . quote($abs);
        # A smoker's child has no console on its standard input.  Code
        # that reads STDIN blocks forever on a terminal and returns end
        # of file there, and that difference has to be in the cell.
        $cmd .= ' < ' . ($IS_WIN ? 'NUL' : '/dev/null')
            if $envmode eq 'smoker';
        $cmd = "chcp $cp > nul && $cmd" if $cp ne '';
        my $out = `$cmd 2>&1`;
        $out = '' unless defined $out;
        my $rc = $?;
        if ($rc != 0 || $out =~ /^not ok/m) {
            $bad++;
            print 'F';
            push @detail, "---- $file\n";
            for my $line (split /\n/, $out) {
                next unless $line =~ /^(?:not ok|# |Bad plan|1\.\.)/;
                push @detail, "     $line\n";
            }
            push @detail, "     exit=$rc\n" if $rc != 0;
        }
        else {
            print '.';
        }
    }

    chdir($save_cwd);
    restore_env($save_env);
    return ($bad, \@detail);
}

sub save_env {
    my %save;
    for my $k ('HOME', @SCRUB, @SET) {
        $save{$k} = exists $ENV{$k} ? $ENV{$k} : undef;
    }
    return \%save;
}

sub restore_env {
    my ($save) = @_;
    for my $k (keys %{$save}) {
        if (defined $save->{$k}) { $ENV{$k} = $save->{$k} }
        else                     { delete $ENV{$k} }
    }
    return 1;
}

sub apply_smoker_env {
    for my $k (@SCRUB) { delete $ENV{$k} }
    for my $k (@SET)   { $ENV{$k} = 1 }
    return 1;
}

######################################################################
# copy_tree -- copy the distribution into $dest so that the suite can be
# run from a directory whose NAME is the thing under test (rule R8).
# Plain File::Find and File::Copy, because this has to run on 5.005_03.
# blib/ is skipped: the cells pass -I for lib/ and t/lib/ themselves.
######################################################################
sub copy_tree {
    my ($src, $dest) = @_;
    return 0 unless -d $src;
    my $made = mkdir($dest, 0700);
    return 0 unless $made || -d $dest;
    my @rel;
    my $ok = 1;
    File::Find::find({
        'no_chdir' => 1,
        'wanted'   => sub {
            my $p = $File::Find::name;
            return if $p =~ m{[\\/]blib(?:[\\/]|\z)};
            return if $p eq $src;
            my $r = substr($p, length($src));
            $r =~ s{\A[\\/]+}{};
            push @rel, [$r, (-d $p) ? 1 : 0];
        },
    }, $src);
    for my $e (sort { $a->[0] cmp $b->[0] } @rel) {
        my ($r, $isdir) = @{$e};
        my @parts = split(m{[\\/]}, $r);
        my $to = File::Spec->catfile($dest, @parts);
        if ($isdir) {
            mkdir($to, 0700) unless -d $to;
            $ok = 0 unless -d $to;
        }
        else {
            my $from = File::Spec->catfile($src, @parts);
            unless (File::Copy::copy($from, $to)) { $ok = 0; last }
        }
    }
    return $ok;
}

sub quote {
    my ($s) = @_;
    return $s unless $s =~ /\s/;
    return '"' . $s . '"';
}

sub short_perl {
    my ($p) = @_;
    return length($p) > 28 ? '...' . substr($p, -25) : $p;
}

######################################################################
# cleanup -- remove the scratch homes.  Only the directories this script
# made are removed, and only if they are empty of anything unexpected.
######################################################################
sub cleanup {
    for my $leaf ('plain', 'with space') {
        my $dir = File::Spec->catdir($BASE, $leaf);
        next unless -d $dir;
        rmdir(File::Spec->catdir($dir, 'anchor'));
        rmdir($dir);
    }
    rmdir($BASE);
    return 1;
}
