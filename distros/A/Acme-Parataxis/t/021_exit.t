use v5.40;
use blib;
use Acme::Parataxis;
use Test2::V1 -ipP;
use File::Temp ();
$|++;
#
my $perl = $^X;

# The child must load the just-built module just like this process does, so
# hand it the same blib directories that `use blib` added to @INC (absolute
# paths, so the child's working directory does not matter).  When the module
# is already installed and no blib is around, nothing is added and the child
# simply uses the installed module.
my @inc = map { '-I' . $_ } grep {/blib/} @INC;

sub shell_quote {
    my ($s) = @_;
    return $s if $s =~ /^[A-Za-z0-9_\-\/.:\\]+$/;
    return '"' . $s . '"';
}

# Runs the child perl and returns ( status, output, trusted ).  On Unix the
# status comes from $? and is reliable.  Some Windows perl builds cannot
# report a spawned child's status at all (the child runs but the parent
# reads garbage such as 255 or 40, see perl5 GH issue #20081), so there the
# true exit code is read from cmd.exe's own delayed-expansion !errorlevel!
# instead of from perl's wait-status machinery.  The child code is written
# to a temp .pl file: cmd.exe strips the first/last quote and unbalances
# nested quotes, so an inline `-e "...code..."` command line gets mangled.
sub run_exit_code {
    my ($code) = @_;
    if ( $^O eq 'MSWin32' ) {
        my $script = File::Temp->newdir() . 'child.pl';
        open my $fh, '>', $script or die "cannot write $script: $!";
        print {$fh} $code;
        close $fh;
        my @cmd  = ( $perl, @inc, $script );
        my $line = join ' ', map { shell_quote($_) } @cmd;
        my $out  = `cmd /v:on /c "$line 2>&1 & echo PTXRC=!errorlevel!"`;
        if ( $out =~ /PTXRC=(-?\d+)/ ) {
            my $rc = $1;
            $out =~ s/\s*PTXRC=-?\d+\s*\z//;
            return ( $rc, $out, 1 );
        }
        return ( $? >> 8, $out, 0 );
    }
    my @cmd  = ( $perl, @inc, '-e', $code );
    my $line = join ' ', map { shell_quote($_) } @cmd;
    local $SIG{__WARN__} = sub { };
    my $out = `$line 2>&1`;
    return ( $? >> 8, $out, 1 );
}

# An untrusted status that arrives without a panic message is the
# "cannot read child status" signature: skip rather than report a bogus
# failure (Coro's own exit test skips on Windows for the same reason).  A
# genuinely-failing child would print a panic, which still fails loudly.
sub is_exit_code ( $got, $want, $name, $out, $trusted ) {
    if ( !$trusted && $out !~ /panic/ ) {
        plan skip_all => 'cannot read the child status on this perl (spawn reporting is broken)';
        return;
    }
    is $got, $want, $name;
}
subtest 'exit(0) from a nested fiber' => sub {
    my ( $rc, $out, $trusted ) = run_exit_code('use Acme::Parataxis qw[async yield fiber]; async { fiber { exit 0 }; yield; }');
    is_exit_code $rc, 0, 'nested fiber exit(0) terminates cleanly with status 0', $out, $trusted;
};
subtest 'exit(7) from the top-level async block' => sub {
    my ( $rc, $out, $trusted ) = run_exit_code('use Acme::Parataxis qw[async]; async { exit 7; }');
    is_exit_code $rc, 7, 'async top-level exit(7) propagates the requested status', $out, $trusted;
};
subtest 'exit(3) after yielding and being resumed' => sub {
    my ( $rc, $out, $trusted ) = run_exit_code('use Acme::Parataxis qw[async yield fiber]; async { fiber { 1 }; yield; exit 3; }');
    is_exit_code $rc, 3, 'exit(3) after a yield/resume cycle propagates the requested status', $out, $trusted;
};
subtest 'exit() does not double-free scheduler scopes' => sub {
    my ( $rc, $out, $trusted ) = run_exit_code('use Acme::Parataxis qw[async yield fiber]; async { fiber { exit 0 }; yield; }');
    if ( !$trusted && $out !~ /panic/ ) {
        plan skip_all => 'cannot read the child status on this perl (spawn reporting is broken)';
        return;
    }
    isnt $rc, 255, 'no wrong-pool panic (exit != 255)';
    ok $out !~ /panic/, 'no panic message in the child output';
};
#
done_testing();
