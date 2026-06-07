######################################################################
#
# 0007-extcmd-env.t  Regression: external commands must be portable
#                    across cmd.exe (Windows) AND /bin/sh (Unix/BSD),
#                    plus static guards against the two known hazards.
#
# BACKGROUND
#   BATsh runs an external command through a real shell:
#     - Windows : system STRING -> cmd.exe
#     - Unix/BSD: system STRING -> /bin/sh -c
#   A shelled-out Perl one-liner must therefore satisfy BOTH shells at
#   once.  Two distinct foot-guns were observed:
#
#   (A) Unix vector -- a dollar default-variable token inside the
#       one-liner is expanded by /bin/sh using the environment variable
#       "_" (the path/last-arg the shell exports), which is
#       unpredictable on CPAN smokers.  This produced random failures
#       such as "Bareword found where operator expected ... 1EERDtQcrK".
#
#   (B) Windows vector -- cmd.exe does NOT treat single quotes as
#       quoting.  A one-liner wrapped in single quotes is split on
#       whitespace, so Perl receives a broken fragment and dies with
#       "Can't find string terminator".
#
#   The portable form satisfies both: wrap the code in DOUBLE quotes
#   and use NO dollar sign the shell would expand, e.g.
#       perl -ne "print uc"
#   (the default variable is used implicitly by uc, so no token leaks).
#
# THIS TEST
#   EE01/EE02 run the pipeline and here-document patterns under several
#             hostile values of the environment variable "_" (the Unix
#             vector) and confirm correct output -- this passes on every
#             OS, and on Unix it actively defeats vector (A).
#   EE03      clean-environment baseline.
#   EE04      static guard for vector (B): no inline Perl may be wrapped
#             in single quotes (cmd.exe-unsafe).  Runs on any OS, so a
#             Windows run still catches a Unix-introduced regression and
#             vice versa.
#   EE05      static guard for vector (A): no double-quoted inline Perl
#             may contain a shell-expandable dollar token.
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
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Portability: EE01/EE02/EE03 shell out to a bareword "perl".  On a CPAN
# smoker the perl under test is frequently NOT on PATH as "perl"
# (perlbrew/plenv, or perl invoked by absolute path), which would turn
# these regression checks into false failures.  Prepend the directory of
# the running interpreter ($^X) to PATH so "perl" resolves to it.  Done
# by environment (not by embedding $^X in the command), so a Win32 path
# with backslashes never reaches SH-mode quote/escape processing.  Must
# precede the first init(): init() snapshots %ENV into STORE and
# sync_to_env() later copies STORE back to %ENV.
{
    my ($pvol, $pdirs) = File::Spec->splitpath($^X);
    my $perldir = File::Spec->catpath($pvol, $pdirs, '');
    if (length $perldir) {
        my $sep = ($^O =~ /^(?:MSWin32|dos|os2)$/) ? ';' : ':';
        $ENV{'PATH'} = (defined($ENV{'PATH'}) && length($ENV{'PATH'}))
                     ? "$perldir$sep$ENV{'PATH'}" : $perldir;
    }
}
BATsh::Env::init();

# Hostile values that, with the old code, broke the generated Perl on
# Unix by leaking through /bin/sh's expansion of the environment "_".
my @HOSTILE = ('1EERDtQcrK', 'abc/test', 'bar/t', '9zz/b');

my @tests = (

    ##################################################################
    # 1. Pipeline to an external command, immune to a hostile "_"
    ##################################################################

    # EE01: echo X | perl -ne "print uc"   (double-quoted, no dollar)
    sub {
        my $saved = exists($ENV{'_'}) ? $ENV{'_'} : undef;
        my $bad   = 0;
        my $note  = '';
        for my $h (@HOSTILE) {
            $ENV{'_'} = $h;
            BATsh::Env::init();
            my $out = _capture(sub {
                BATsh->run_string('echo pipetest | perl -ne "print uc"');
            });
            $out =~ s/\r//g;
            unless ($out =~ /PIPETEST/) { $bad = 1; $note = "_=$h out=[$out]"; last }
        }
        if (defined $saved) { $ENV{'_'} = $saved } else { delete $ENV{'_'} }
        BATsh::Env::init();
        _ok(!$bad, "EE01: pipeline portable + immune to hostile env ($note)");
    },

    ##################################################################
    # 2. Here-document to an external command, immune to a hostile "_"
    ##################################################################

    # EE02: perl -ne "print uc" <<EOF ... under each hostile "_"
    sub {
        my $saved = exists($ENV{'_'}) ? $ENV{'_'} : undef;
        my $bad   = 0;
        my $note  = '';
        for my $h (@HOSTILE) {
            $ENV{'_'} = $h;
            BATsh::Env::init();
            my $out = _capture(sub {
                BATsh->run_string(
                    "perl -ne \"print uc\" <<EOF\nhello\nworld\nEOF");
            });
            $out =~ s/\r//g;
            unless ($out =~ /HELLO/ && $out =~ /WORLD/) {
                $bad = 1; $note = "_=$h out=[$out]"; last;
            }
        }
        if (defined $saved) { $ENV{'_'} = $saved } else { delete $ENV{'_'} }
        BATsh::Env::init();
        _ok(!$bad, "EE02: here-doc portable + immune to hostile env ($note)");
    },

    ##################################################################
    # 3. Baseline: clean environment
    ##################################################################

    # EE03: pipeline produces uppercase output (clean env)
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string('echo pipetest | perl -ne "print uc"');
        });
        $out =~ s/\r//g;
        _ok($out =~ /PIPETEST/, "EE03: pipeline baseline (got [$out])");
    },

    ##################################################################
    # 4. Static guard (B): cmd.exe single-quote hazard
    ##################################################################

    # EE04: no inline perl -e/-ne/-pe may be wrapped in single quotes,
    # which cmd.exe does not honor (Windows portability).
    sub {
        my @hits = _scan_perl_oneliners('SQ');
        if (@hits) { for my $h (@hits) { print "# WIN-HAZARD (single-quote): $h\n" } }
        _ok(!@hits,
            'EE04: no single-quote inline Perl in t/ eg/ lib/ doc/ README'
            . (@hits ? ' (' . scalar(@hits) . ' hit(s))' : ''));
    },

    ##################################################################
    # 5. Static guard (A): /bin/sh dollar-expansion hazard
    ##################################################################

    # EE05: no double-quoted inline perl -e/-ne/-pe may contain a
    # shell-expandable dollar token ($_ , $name , ${...} , $1..$9),
    # which /bin/sh would expand using the environment (Unix portability).
    # The harmless numeric $$ (PID) is exempt.
    sub {
        my @hits = _scan_perl_oneliners('DOLLAR');
        if (@hits) { for my $h (@hits) { print "# UNIX-HAZARD (dollar): $h\n" } }
        _ok(!@hits,
            'EE05: no shell-dollar in double-quoted inline Perl (all docs)'
            . (@hits ? ' (' . scalar(@hits) . ' hit(s))' : ''));
    },

);

######################################################################
# Helpers
######################################################################

# Scan every t/*.t and eg/* file for inline Perl one-liners and return
# the offending lines for the requested hazard class:
#   'SQ'     -- the -e/-ne/-pe flag is immediately followed by a single
#               quote (cmd.exe-unsafe wrapping).
#   'DOLLAR' -- the code is double-quoted and contains a dollar token
#               that /bin/sh would expand ($ + letter/underscore/digit
#               or ${ ), excluding the harmless numeric $$.
# Backslash-escaped quotes (\" \') as they appear inside .t string
# literals are normalised first, so the scan sees the effective command.
sub _scan_perl_oneliners {
    my ($mode) = @_;
    my $root = File::Spec->catdir($FindBin::Bin, File::Spec->updir);
    my @hits;
    # Directories scanned (relative to the distribution root), plus the
    # top-level README.  Covers executable code (t/, eg/), the module
    # POD samples (lib/), and the 21-language reference docs (doc/), so a
    # non-portable inline-Perl one-liner cannot be reintroduced anywhere.
    my @relfiles;
    for my $sub ('t', 'eg', 'doc', 'lib', 'lib/BATsh') {
        my $dir = File::Spec->catdir($root, split(m{/}, $sub));
        next unless -d $dir;
        local *EE_DIR;
        next unless opendir(EE_DIR, $dir);
        my @names = sort grep { $_ !~ /\A\./ } readdir(EE_DIR);
        closedir(EE_DIR);
        for my $name (@names) {
            # Only canonical source files; skip backups / editor files
            # (e.g. *-OLD, *-OLD2, *.bak, *~) that may sit in the tree.
            my $ok = 0;
            if    ($sub eq 't')   { $ok = ($name =~ /\.t\z/) }
            elsif ($sub eq 'eg')  { $ok = ($name =~ /\.(?:batsh|pl)\z/) }
            elsif ($sub eq 'doc') { $ok = ($name =~ /\.txt\z/) }
            else                  { $ok = ($name =~ /\.pm\z/) }   # lib, lib/BATsh
            next unless $ok;
            push @relfiles, "$sub/$name";
        }
    }
    push @relfiles, 'README';

    for my $rel (@relfiles) {
        # This regression file documents the hazards in prose on purpose,
        # so it must not scan itself.
        next if $rel =~ /0007-extcmd-env\.t\z/;
        my $path = File::Spec->catfile($root, split(m{/}, $rel));
        next unless -f $path;
        local *EE_FH;
        next unless open(EE_FH, $path);
        my $lineno = 0;
        while (<EE_FH>) {
            $lineno++;
            my $line = $_;
            $line =~ s/[\r\n]+\z//;
            # Skip full-line comments (Perl/SH '#', CMD '::' / 'REM') so
            # prose that merely mentions perl one-liners is ignored.
            next if $line =~ /\A\s*#/;
            next if $line =~ /\A\s*::/;
            next if $line =~ /\A\s*(?:REM|rem)\b/;
            # Normalise escaped quotes from .t string literals.
            my $eff = $line;
            $eff =~ s/\\"/"/g;
            $eff =~ s/\\'/'/g;
            my $bad = 0;
            if ($mode eq 'SQ') {
                # perl <flags ending in e> followed by a single quote
                $bad = 1 if $eff =~ /\bperl\b[^|<>;&`]*?-\w*e\b\s*'/;
            }
            else {
                # perl <flags ending in e> "double-quoted-code"
                if ($eff =~ /\bperl\b[^|<>;&`]*?-\w*e\b\s*"([^"]*)"/) {
                    my $code = $1;
                    $bad = 1 if $code =~ /\$[A-Za-z_0-9{]/;
                }
            }
            push @hits, "$rel:$lineno: $line" if $bad;
        }
        close(EE_FH);
    }
    return @hits;
}

sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_cap7_$$\.tmp");
    open(_CAP_OLD, '>&STDOUT') or return '';
    open(_CAP_FH,  ">$tmpfile") or do { open(STDOUT, '>&_CAP_OLD'); return '' };
    open(STDOUT, '>&_CAP_FH');
    close(_CAP_FH);
    eval { $code->() };
    open(STDOUT, '>&_CAP_OLD');
    close(_CAP_OLD);
    my $buf = '';
    if (open(_CAP_RFH, "< $tmpfile")) {
        local $/;
        $buf = <_CAP_RFH>;
        close(_CAP_RFH);
    }
    unlink $tmpfile;
    $buf = '' unless defined $buf;
    return $buf;
}

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { $? = 1 if $fail }
