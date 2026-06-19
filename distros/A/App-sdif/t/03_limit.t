use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempfile);
use Command::Run::Tmpfile;

my $lib    = File::Spec->rel2abs('lib');
my $script = File::Spec->rel2abs('script');
my $sdif   = "$script/sdif";
my $cdif   = "$script/cdif";

# Skip on systems where /dev/fd/N (N>2) is unavailable, e.g. FreeBSD
# without fdescfs mounted.
{
    my $probe = Command::Run::Tmpfile->new;
    my $path  = $probe->path;
    unless (defined $path and -r $path) {
	plan skip_all => 'no /dev/fd or /proc/self/fd path available';
    }
}

sub run_with_input {
    my($input, @cmd) = @_;
    my($fh, $tmpfile) = tempfile(UNLINK => 1);
    print $fh $input;
    close $fh;
    open my $out, '-|', @cmd, $tmpfile or die "exec: $!";
    my $result = do { local $/; <$out> };
    close $out;
    $result;
}

sub run_sdif { run_with_input($_[0], $^X, "-I$lib", $sdif, @_[1..$#_]) }
sub run_cdif { run_with_input($_[0], $^X, "-I$lib", $cdif, @_[1..$#_]) }

sub make_diff {
    my($old, $new) = @_;
    my($fh1, $f1) = tempfile(UNLINK => 1);
    my($fh2, $f2) = tempfile(UNLINK => 1);
    print $fh1 $old; close $fh1;
    print $fh2 $new; close $fh2;
    my $diff = `diff -u $f1 $f2`;
    $diff;
}

# --limit line: truncate add/delete sections
subtest 'sdif --limit line' => sub {
    my $diff = make_diff("", join("", map "$_\n", 1..30));
    my $out = run_sdif($diff, '--nocdif', '--limit', 'line=5', '-W80', '--nocolor');
    like($out, qr/25 lines omitted/, 'omission message present');
};

# --limit line: change sections not truncated
subtest 'sdif --limit line skip change' => sub {
    my $diff = make_diff(
	join("", map "old$_\n", 1..20),
	join("", map "new$_\n", 1..20),
    );
    my $out = run_sdif($diff, '--nocdif', '--limit', 'line=5', '-W80', '--nocolor');
    unlike($out, qr/lines omitted/, 'change sections not truncated');
};

# --limit length: truncate long lines
subtest 'sdif --limit length' => sub {
    my $diff = make_diff("", "x" x 50000 . "\n");
    my $out = run_sdif($diff, '--nocdif', '--limit', 'length=100', '-W200', '--nocolor');
    like($out, qr/characters omitted/, 'long line truncated');
};

# --limit length=0: disable
subtest 'sdif --limit length=0' => sub {
    my $diff = make_diff("", "x" x 200 . "\n");
    my $out = run_sdif($diff, '--nocdif', '--limit', 'length=0', '-W80', '--nocolor');
    unlike($out, qr/characters omitted/, 'length=0 disables truncation');
};

# --limit line and length together
subtest 'sdif --limit line + length' => sub {
    my $diff = make_diff("", join("", map "$_\n", 1..30));
    my $out = run_sdif($diff, '--nocdif', '--limit', 'line=3', '--limit', 'length=5000',
		       '-W80', '--nocolor');
    like($out, qr/27 lines omitted/, 'both limits work together');
};

# cdif --limit length: skip word diff for long lines
subtest 'cdif --limit length' => sub {
    my $long = "hello world " x 200;
    my $diff = make_diff("$long\n", uc($long) . "\n");
    my $out = run_cdif($diff, '--nocolor', '--limit', 'length=100');
    # word diff markers (_X_) should not be present
    unlike($out, qr/_[A-Z]_/, 'word diff skipped for long lines');
};

done_testing;
