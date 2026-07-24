######################################################################
#
# 0029-sh-attrs-mapfile.t   SH umask / hash / readonly / declare -i /
#                           mapfile / readarray  (v0.08)
#
# New builtins and variable attributes added in v0.08.  Previously umask
# and hash fell through to an external shell (producing "Can't exec"
# errors), readonly and mapfile/readarray were unimplemented, and the
# integer attribute "declare -i" stored its right-hand side literally.
#
# UM01   umask prints the current mask as four octal digits
# UM02   umask MODE sets the mask
# UM03   umask -S prints the symbolic (permission) form
# UM04   umask accepts a symbolic set (u=rwx,g=,o=)
# UM05   umask accepts a symbolic modification (g-r)
# HS01   hash -r is a successful no-op
# HS02   hash NAME succeeds for a command on PATH
# HS03   hash NAME fails for an unknown command
# RO01   readonly VAR=VALUE assigns the value
# RO02   a later assignment to a readonly variable is refused
# RO03   the refused assignment yields a non-zero status
# RO04   unset of a readonly variable fails
# RO05   the readonly variable keeps its value after a refused unset
# DI01   declare -i evaluates the initialiser as arithmetic
# DI02   the integer attribute persists for a later plain assignment
# DI03   declare -i with a compound expression
# DI04   declare -i with a quoted expression containing spaces
# MF01   mapfile -t reads all lines into an indexed array
# MF02   mapfile -t element values (first and last)
# MF03   readarray is an alias for mapfile
# MF04   mapfile -s SKIP -n COUNT selects a slice
# MF05   mapfile -O ORIGIN offsets the starting index
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
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# A small data file for the mapfile / readarray tests.
my $DATA = "$FindBin::Bin/_mf_data_$$.txt";
{
    local *DF;
    open(DF, "> $DATA") or die "cannot write $DATA: $!";
    print DF "alpha\nbeta\ngamma\n";
    close(DF);
}
END { unlink($DATA) if defined $DATA }

# Run source through BATsh->run_string, capturing STDOUT and STDERR.
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap_out = "$FindBin::Bin/_am_out_$$.tmp";
    my $cap_err = "$FindBin::Bin/_am_err_$$.tmp";
    local *OLDOUT;
    local *OLDERR;
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
    my $out = '';
    my $err = '';
    local *RF;
    if (open(RF, $cap_out)) { local $/; $out = <RF>; close(RF) }
    unlink($cap_out);
    if (open(RF, $cap_err)) { local $/; $err = <RF>; close(RF) }
    unlink($cap_err);
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

# ---- umask --------------------------------------------------------

sub {
    my (undef, $out) = _run_capture("umask 022\numask\n");
    ok_is($out, "0022\n", 'UM01 umask prints four octal digits');
},
sub {
    my (undef, $out) = _run_capture("umask 077\numask\n");
    ok_is($out, "0077\n", 'UM02 umask MODE sets the mask');
},
sub {
    my (undef, $out) = _run_capture("umask 022\numask -S\n");
    ok_is($out, "u=rwx,g=rx,o=rx\n", 'UM03 umask -S symbolic form');
},
sub {
    my (undef, $out) =
        _run_capture("umask 000\numask u=rwx,g=,o=\numask\n");
    ok_is($out, "0077\n", 'UM04 umask symbolic set (=)');
},
sub {
    my (undef, $out) =
        _run_capture("umask 022\numask g-r\numask\n");
    ok_is($out, "0062\n", 'UM05 umask symbolic modify (-)');
},

# ---- hash ---------------------------------------------------------

sub {
    my (undef, $out) = _run_capture("hash -r\necho rc=\$?\n");
    ok_is($out, "rc=0\n", 'HS01 hash -r no-op success');
},
sub {
    my (undef, $out) = _run_capture("hash perl\necho rc=\$?\n");
    ok_is($out, "rc=0\n", 'HS02 hash of a PATH command');
},
sub {
    my (undef, $out) =
        _run_capture("hash nope_xyz_123\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'HS03 hash of an unknown command');
},

# ---- readonly -----------------------------------------------------

sub {
    my (undef, $out) = _run_capture("readonly RX=5\necho \$RX\n");
    ok_is($out, "5\n", 'RO01 readonly assigns the value');
},
sub {
    my (undef, $out) =
        _run_capture("readonly RX=5\nRX=9\necho \$RX\n");
    ok_is($out, "5\n", 'RO02 assignment to readonly is refused');
},
sub {
    my (undef, $out) =
        _run_capture("readonly RX=5\nRX=9\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'RO03 refused assignment -> status 1');
},
sub {
    my (undef, $out) =
        _run_capture("readonly RY=a\nunset RY\necho rc=\$?\n");
    ok_is($out, "rc=1\n", 'RO04 unset of readonly fails');
},
sub {
    my (undef, $out) =
        _run_capture("readonly RY=a\nunset RY\necho \$RY\n");
    ok_is($out, "a\n", 'RO05 value survives a refused unset');
},

# ---- declare -i ---------------------------------------------------

sub {
    my (undef, $out) = _run_capture("declare -i n=3+4\necho \$n\n");
    ok_is($out, "7\n", 'DI01 declare -i evaluates arithmetic');
},
sub {
    my (undef, $out) =
        _run_capture("declare -i m\nm=10*2\necho \$m\n");
    ok_is($out, "20\n", 'DI02 integer attribute persists');
},
sub {
    my (undef, $out) = _run_capture("declare -i k=2*3+1\necho \$k\n");
    ok_is($out, "7\n", 'DI03 declare -i compound expression');
},
sub {
    my (undef, $out) =
        _run_capture("declare -i s=\"1 + 2\"\necho \$s\n");
    ok_is($out, "3\n", 'DI04 declare -i quoted spaced expression');
},

# ---- mapfile / readarray ------------------------------------------

sub {
    my (undef, $out) =
        _run_capture("mapfile -t arr < $DATA\necho \${#arr[\@]}\n");
    ok_is($out, "3\n", 'MF01 mapfile -t reads all lines');
},
sub {
    my (undef, $out) =
        _run_capture("mapfile -t arr < $DATA\n"
                   . "echo \${arr[0]}-\${arr[2]}\n");
    ok_is($out, "alpha-gamma\n", 'MF02 mapfile element values');
},
sub {
    my (undef, $out) =
        _run_capture("readarray -t arr < $DATA\necho \${arr[1]}\n");
    ok_is($out, "beta\n", 'MF03 readarray alias');
},
sub {
    my (undef, $out) =
        _run_capture("mapfile -t -s 1 -n 1 arr < $DATA\n"
                   . "echo \${arr[0]}\n");
    ok_is($out, "beta\n", 'MF04 mapfile -s SKIP -n COUNT slice');
},
sub {
    my (undef, $out) =
        _run_capture("mapfile -t -O 5 arr < $DATA\necho \${arr[5]}\n");
    ok_is($out, "alpha\n", 'MF05 mapfile -O origin offset');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
