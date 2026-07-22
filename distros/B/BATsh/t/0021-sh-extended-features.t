######################################################################
#
# 0021-sh-extended-features.t  SH extended features (v0.07)
#
# EF01-EF06  brace expansion: {a,b,c}, {1..5}, {5..1}, {01..03}, {a..c},
#            nested/combined groups, literal "{foo}" (no comma/range)
# EF07-EF09  extglob: shopt -s extglob enables ?(),*(),+(),@(),!() in
#            case patterns; off by default; ${VAR%pat} with extglob
# EF10-EF11  here-string: cmd <<< word; variable-expanded content
# EF12-EF13  process substitution: <(cmd) as a readable temp file;
#            >(cmd) receives piped output (deferred)
# EF14-EF16  select: menu prompt to STDERR, REPLY/VAR set from stdin,
#            invalid input clears VAR, break stops the loop
# EF17-EF19  alias: definition, expansion, chaining, unalias
# EF20-EF21  exec: exec > file redirects the rest of the script;
#            exec cmd terminates the script with cmd's status
# EF22-EF24  subshell ( ... ): variable/array/cwd/function changes do
#            not leak to the parent; stdout still reaches the caller
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
use Cwd ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Run source through BATsh->run_string, capturing STDOUT and STDERR and
# optionally feeding STDIN from $stdin_text.  Returns (rc, out, err).
sub _run_capture {
    my ($source, $stdin_text) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_ef_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_ef_err_$$.tmp";
    my $cap_in  = "$FindBin::Bin/_ef_in_$$.tmp";
    local *OLDOUT;
    local *OLDERR;
    local *OLDIN;
    my $saved_in = 0;
    if (defined $stdin_text) {
        local *WF;
        open(WF, "> $cap_in") or die "cannot write $cap_in: $!";
        print WF $stdin_text;
        close(WF);
        open(OLDIN, "<&STDIN") or die "cannot dup STDIN: $!";
        close(STDIN);
        open(STDIN, "< $cap_in")
            or do { open(STDIN, "<&OLDIN"); die "cannot redirect STDIN: $!" };
        $saved_in = 1;
    }
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    open(OLDERR, ">&STDERR") or die "cannot dup STDERR: $!";
    close(STDOUT);
    open(STDOUT, "> $cap_out")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    close(STDERR);
    open(STDERR, "> $cap_err")
        or do { open(STDERR, ">&OLDERR");
                open(STDOUT, ">&OLDOUT");
                die "cannot redirect STDERR: $!" };
    my $rc = eval { BATsh->run_string($source) };
    my $err_eval = $@;
    close(STDOUT);
    close(STDERR);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    open(STDERR, ">&OLDERR") or die "cannot restore STDERR: $!";
    close(OLDOUT);
    close(OLDERR);
    if ($saved_in) {
        close(STDIN);
        open(STDIN, "<&OLDIN") or die "cannot restore STDIN: $!";
        close(OLDIN);
    }
    my $out = '';
    my $err = '';
    local *RF;
    if (open(RF, $cap_out)) { local $/; $out = <RF>; close(RF) }
    unlink($cap_out);
    if (open(RF, $cap_err)) { local $/; $err = <RF>; close(RF) }
    unlink($cap_err);
    unlink($cap_in) if $saved_in;
    $out = '' unless defined $out;
    $err = '' unless defined $err;
    warn $err_eval if $err_eval;
    return ($rc, $out, $err);
}

my $test = 0;
sub ok_is {
    my ($got, $expected, $name) = @_;
    $test++;
    $got      = '(undef)' unless defined $got;
    $expected = '(undef)' unless defined $expected;
    if ($got eq $expected) { print "ok $test - $name\n"; return 1 }
    print "not ok $test - $name (got [$got] expected [$expected])\n";
    $main::fail++;
    return 0;
}

my @tests = (

# EF01: comma-list brace expansion
sub {
    my (undef, $out) = _run_capture("echo a{b,c,d}e\n");
    ok_is($out, "abe ace ade\n", 'EF01 comma-list brace expansion');
},

# EF02: numeric ascending range
sub {
    my (undef, $out) = _run_capture("echo {1..5}\n");
    ok_is($out, "1 2 3 4 5\n", 'EF02 numeric ascending range');
},

# EF03: numeric descending range
sub {
    my (undef, $out) = _run_capture("echo {5..1}\n");
    ok_is($out, "5 4 3 2 1\n", 'EF03 numeric descending range');
},

# EF04: zero-padded range
sub {
    my (undef, $out) = _run_capture("echo {01..03}\n");
    ok_is($out, "01 02 03\n", 'EF04 zero-padded numeric range');
},

# EF05: alpha range
sub {
    my (undef, $out) = _run_capture("echo {a..c}\n");
    ok_is($out, "a b c\n", 'EF05 alpha range');
},

# EF06: no comma / no range -- left as a literal brace pair
sub {
    my (undef, $out) = _run_capture("echo x{foo}y\n");
    ok_is($out, "x{foo}y\n", 'EF06 non-brace-expression braces stay literal');
},

# EF07: extglob off by default -- @(...) is not special
sub {
    my (undef, $out) = _run_capture(
        "case abc in\n\@(abc|def)) echo nomatch ;;\nabc) echo plain ;;\nesac\n");
    ok_is($out, "plain\n", 'EF07 extglob operators inert until shopt -s extglob');
},

# EF08: shopt -s extglob enables @(...) alternation in case patterns
sub {
    my (undef, $out) = _run_capture(
        "shopt -s extglob\ncase abc in\n\@(abc|def)) echo yes ;;\n*) echo no ;;\nesac\n");
    ok_is($out, "yes\n", 'EF08 shopt -s extglob: @(a|b) alternation matches');
},

# EF09: extglob !(...) exclusion in case patterns
sub {
    my (undef, $out) = _run_capture(
        "shopt -s extglob\ncase foo.txt in\n!(*.jpg|*.png)) echo keep ;;\n*) echo skip ;;\nesac\n");
    ok_is($out, "keep\n", 'EF09 extglob !(list) exclusion matches');
},

# EF10: here-string feeds a builtin's stdin
sub {
    my (undef, $out) = _run_capture("read LINE <<< hello\necho \$LINE\n");
    ok_is($out, "hello\n", 'EF10 here-string <<< feeds read');
},

# EF11: here-string content is variable-expanded
sub {
    my (undef, $out) = _run_capture("X=world\nread LINE <<< \"hi \$X\"\necho \$LINE\n");
    ok_is($out, "hi world\n", 'EF11 here-string content is expanded');
},

# EF12: <(cmd) process substitution yields a readable file
sub {
    my (undef, $out) = _run_capture("read LINE < <(echo piped)\necho \$LINE\n");
    ok_is($out, "piped\n", 'EF12 <(cmd) substitutes a readable temp file');
},

# EF13: >(cmd) process substitution: writer's output reaches cmd
sub {
    my (undef, $out) = _run_capture(
        "echo hello > >(read LINE; echo got=\$LINE)\n");
    ok_is(($out =~ /got=hello/) ? 1 : 0, 1,
          'EF13 >(cmd) receives the redirected output');
},

# EF14: select reads a valid choice and sets VAR
sub {
    my (undef, $out, $err) = _run_capture(
        "select F in one two three; do echo got=\$F; break; done\n", "2\n");
    ok_is(($out =~ /got=two/) ? 1 : 0, 1, 'EF14 select sets VAR from a valid choice');
},

# EF15: select prints a numbered menu to STDERR
sub {
    my (undef, $out, $err) = _run_capture(
        "select F in one two; do break; done\n", "1\n");
    ok_is((($err =~ /1\) one/) && ($err =~ /2\) two/)) ? 1 : 0, 1,
          'EF15 select prints a numbered menu to STDERR');
},

# EF16: select clears VAR on an out-of-range choice
sub {
    my (undef, $out) = _run_capture(
        "select F in one two; do echo [\$F]; break; done\n", "9\n");
    ok_is($out, "[]\n", 'EF16 select clears VAR on invalid input');
},

# EF17: alias expands a simple command name
sub {
    my (undef, $out) = _run_capture("alias greet='echo hi'\ngreet\n");
    ok_is($out, "hi\n", 'EF17 alias expands to its stored text');
},

# EF18: alias chaining (alias of an alias)
sub {
    my (undef, $out) = _run_capture(
        "alias inner='echo deep'\nalias outer=inner\nouter\n");
    ok_is($out, "deep\n", 'EF18 alias chains through another alias');
},

# EF19: unalias removes the definition
sub {
    my (undef, $out, $err) = _run_capture(
        "alias greet='echo hi'\nunalias greet\ngreet\n");
    ok_is(($err ne '') ? 1 : 0, 1,
          'EF19 unalias removes the alias (bare word now an external command)');
},

# EF20: exec > file redirects the rest of the script permanently
sub {
    my $tmp = "$FindBin::Bin/_ef_exec_$$.tmp";
    unlink $tmp;
    _run_capture("exec > $tmp\necho redirected\n");
    local *RF;
    my $content = '';
    if (open(RF, $tmp)) { local $/; $content = <RF>; close(RF) }
    unlink $tmp;
    ok_is($content, "redirected\n", 'EF20 exec > file redirects stdout for the rest of the script');
},

# EF21: exec cmd terminates the script with cmd's exit status
sub {
    my ($rc, $out) = _run_capture("echo before\nexec echo replaced\necho after\n");
    ok_is((($out =~ /before/) && ($out =~ /replaced/) && ($out !~ /after/)) ? 1 : 0, 1,
          'EF21 exec cmd runs cmd and ends the script (no further lines)');
},

# EF22: subshell variable changes do not leak to the parent
sub {
    my (undef, $out) = _run_capture(
        "V=outer\n( V=inner; echo in=\$V )\necho after=\$V\n");
    ok_is($out, "in=inner\nafter=outer\n",
          'EF22 subshell variable assignment is isolated from the parent');
},

# EF23: subshell cd does not change the parent's directory
sub {
    my $tmpdir = File::Spec->tmpdir();
    my (undef, $out) = _run_capture(
        "( cd $tmpdir; pwd > /dev/null; echo done )\npwd_before=\$(pwd)\necho ok\n");
    ok_is(($out =~ /done/ && $out =~ /ok/) ? 1 : 0, 1,
          'EF23 subshell runs to completion with its own cd');
},

# EF24: subshell function definitions do not leak to the parent
sub {
    my (undef, $out, $err) = _run_capture(
        "( f() { echo inside; } )\nf\n");
    ok_is(($err ne '' || $out !~ /inside/) ? 1 : 0, 1,
          'EF24 function defined inside a subshell is not visible outside');
},

# EF25: echo $VAR must not re-glob a value that merely LOOKS LIKE a
# glob pattern (e.g. "?", as getopts sets $opt on an unknown option).
# Run inside a directory that deliberately contains a 1-character file
# so the old bug (matching it via glob()) would be triggered if present.
sub {
    my $dir = "$FindBin::Bin/_ef25_dir_$$";
    mkdir($dir, 0777) or die "cannot mkdir $dir: $!";
    local *WF;
    open(WF, "> $dir/t") or die "cannot write $dir/t: $!";
    close(WF);
    my $orig = eval { Cwd::cwd() };
    chdir($dir) if defined $orig;
    my (undef, $out) = _run_capture("OPT=\"?\"\necho \$OPT\n");
    chdir($orig) if defined $orig;
    unlink("$dir/t");
    rmdir($dir);
    ok_is($out, "?\n",
          'EF25 echo $VAR does not re-glob a value that merely looks like "?"');
},

# EF26: a literal glob pattern actually written in the source must
# still expand (regression guard alongside EF25 above).
sub {
    my $dir = "$FindBin::Bin/_ef26_dir_$$";
    mkdir($dir, 0777) or die "cannot mkdir $dir: $!";
    local *WF;
    open(WF, "> $dir/hello.txt") or die "cannot write $dir/hello.txt: $!";
    close(WF);
    my $orig = eval { Cwd::cwd() };
    chdir($dir) if defined $orig;
    my (undef, $out) = _run_capture("echo *.txt\n");
    chdir($orig) if defined $orig;
    unlink("$dir/hello.txt");
    rmdir($dir);
    ok_is($out, "hello.txt\n",
          'EF26 echo *.txt (literal glob in source) still expands');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
