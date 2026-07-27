######################################################################
#
# 0030-expansion-literals.t  Expansion results are literal data (v0.09)
#
# BACKGROUND
#   BATsh expands a line first and removes quotes from it afterwards.
#   Until v0.09 the quote-removal stage could not tell source text from
#   text an expansion had just produced, so every backslash coming out
#   of an expansion was re-read as a shell escape and deleted:
#
#       HOME=c:\home\flower ; cd ~        -> tried to enter c:homeflower
#       d="C:\Users\x" ; cd $d            -> tried to enter C:Usersx
#
#   which broke practically every Windows path that travelled through a
#   variable (CPAN Testers FAIL of BATsh-0.08 on Windows / perl 5.8.9,
#   t/0020 TE01 TE02 TE04 TE07).  POSIX quote removal applies to the
#   source word only, never to the result of an expansion, and BATsh now
#   follows that rule: a backslash produced by a variable expansion,
#   command substitution or tilde expansion stays literal, while a
#   backslash actually written in the script is still an escape.
#
# THIS TEST
#   EL01-EL02  Unquoted and quoted $VAR keep a backslash in the value.
#   EL03       A backslash written in the source is still an escape.
#   EL04       Assigning one variable from another keeps the value.
#   EL05       Command-substitution output keeps its backslashes.
#   EL06       printf arguments keep them too.
#   EL07       echo -e still interprets \t arriving from a variable.
#   EL08       export VAR=value stores the value, not its quotes.
#   EL09       test/[ compares the literal value.
#   EL10       Array elements and ${A[@]} keep their backslashes.
#   EL11       for over quoted words keeps them.
#   EL12       A value read back from a pipeline keeps them.
#   EL13       ${#VAR} counts the backslash (no silent removal).
#   EL14       An unmatched glob pattern is left untouched.
#   EL15-EL16  Tilde expansion of a $HOME containing a space stays one
#              word (POSIX: a tilde-expansion result is not field-split).
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
use Cwd ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

sub _capture {
    my ($code) = @_;
    my $out = '';
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    my $tmp = "$FindBin::Bin/_el_cap_$$.tmp";
    close(STDOUT);
    open(STDOUT, "> $tmp")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { $code->() };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    local *RF;
    if (open(RF, $tmp)) { local $/; $out = <RF>; close(RF) }
    unlink($tmp);
    $out = '' unless defined $out;
    warn $err if $err;
    $out =~ s/\r//g;
    $out =~ s/\s+\z//;
    return $out;
}

# Run one script and return its (trimmed) standard output.
sub _run {
    my ($script) = @_;
    BATsh::Env::init();
    return _capture(sub { BATsh->run_string($script) });
}

# A home directory whose name contains a space, for the tilde checks.
my $SPACEHOME = "$FindBin::Bin/_el home $$";
my $HAVE_SPACEHOME = mkdir($SPACEHOME, 0755) ? 1 : 0;

my @tests = (

    ##################################################################
    # 1. Variable values
    ##################################################################

    sub {
        _ok(_run('V="a\b"; echo $V') eq 'a\b',
            'EL01: unquoted $VAR keeps a backslash in the value');
    },

    sub {
        _ok(_run('V="a\b"; echo "$V"') eq 'a\b',
            'EL02: quoted "$VAR" keeps a backslash in the value');
    },

    sub {
        _ok(_run('echo a\b') eq 'ab',
            'EL03: a backslash written in the source is still an escape');
    },

    sub {
        _ok(_run('V="a\b"; W=$V; echo "$W"') eq 'a\b',
            'EL04: assignment from another variable keeps the value');
    },

    ##################################################################
    # 2. Command substitution and builtin arguments
    ##################################################################

    sub {
        _ok(_run("V=\$(echo 'a\\b'); echo \$V") eq 'a\b',
            'EL05: command-substitution output keeps its backslashes');
    },

    sub {
        _ok(_run('V="a\b"; printf "[%s]\n" $V') eq '[a\b]',
            'EL06: printf argument keeps its backslashes');
    },

    sub {
        _ok(_run("V='a\\tb'; echo -e \$V") eq "a\tb",
            'EL07: echo -e still interprets \t coming from a variable');
    },

    sub {
        _ok(_run("export V='a\\b'; echo \$V") eq 'a\b',
            'EL08: export stores the value, not the quote characters');
    },

    sub {
        my $out = _run("V='a\\b'; if test \"\$V\" = 'a\\b'; then echo Y; else echo N; fi");
        _ok($out eq 'Y', 'EL09: test compares the literal value');
    },

    ##################################################################
    # 3. Arrays, loops, pipelines
    ##################################################################

    sub {
        _ok(_run("A=('a\\b' 'c\\d'); echo \${A[@]}") eq 'a\b c\d',
            'EL10: array elements keep their backslashes');
    },

    sub {
        my $out = _run('for w in "a\b" c; do echo [$w]; done');
        $out =~ s/\n/ /g;
        _ok($out eq '[a\b] [c]', 'EL11: for over quoted words keeps them');
    },

    sub {
        my $out = _run("echo 'a\\b' | while read L; do echo [\$L]; done");
        _ok($out eq '[a\b]', 'EL12: a value read from a pipeline keeps them');
    },

    sub {
        _ok(_run('V="a\b"; echo ${#V}') eq '3',
            'EL13: ${#VAR} counts the backslash');
    },

    sub {
        my $pat = '/no_such_dir_' . $$ . '/*.txt';
        _ok(_run("echo $pat") eq $pat,
            'EL14: an unmatched glob pattern is left untouched');
    },

    ##################################################################
    # 4. Tilde expansion of a home directory containing a space
    ##################################################################

    sub {
        return _ok(1, 'EL15: skipped (cannot create the test home)')
            unless $HAVE_SPACEHOME;
        local $ENV{'HOME'} = $SPACEHOME;
        _ok(_run('echo ~') eq $SPACEHOME,
            'EL15: echo ~ yields the whole home directory in one word');
    },

    sub {
        return _ok(1, 'EL16: skipped (cannot create the test home)')
            unless $HAVE_SPACEHOME;
        local $ENV{'HOME'} = $SPACEHOME;
        my $save = Cwd::cwd();
        _run('cd ~');
        my $here = Cwd::cwd();
        my $ok = ($here eq $SPACEHOME) || ($here eq Cwd::realpath($SPACEHOME));
        chdir($save);
        _ok($ok, 'EL16: cd ~ enters a home directory containing a space');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
rmdir($SPACEHOME) if $HAVE_SPACEHOME;
END { $? = 1 if $fail }
