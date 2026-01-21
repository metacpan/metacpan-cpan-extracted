#!perl
use strict;
use warnings;
use Test::More 0.96;
use Encode qw(encode_utf8 decode_utf8 FB_CROAK LEAVE_SRC);
use File::Temp 0.19;

# Enable utf-8 encoding so we do not get Wide character in print
# warnings when reporting test failures
use open qw{:encoding(UTF-8) :std};

plan skip_all => "Skipped: $^O does not have proper utf-8 file system support"
    if ($^O =~ /MSWin32|cygwin|dos|os2/);

# Create test files
my $test_root     = File::Temp->newdir();
my $unicode_dir   = "\x{30c6}\x{30b9}\x{30c8}\x{30c6}\x{3099}\x{30a3}\x{30ec}\x{30af}\x{30c8}\x{30ea}";

mkdir "$test_root/$unicode_dir"
    or die "Unable to create directory $test_root/$unicode_dir: $!"
    unless -d "$test_root/$unicode_dir";

# Check utf8 and non-utf8 results
sub check_dirs {
    my ($test, $utf8, $non_utf8) = @_;
    my $utf8_encoded     = encode_utf8($utf8);
    my $non_utf8_decoded = decode_utf8($non_utf8, FB_CROAK | LEAVE_SRC);

    plan tests => 3;

    like $utf8 => qr/\/$unicode_dir$/, "$test found correct dir";
    is   $utf8_encoded => $non_utf8,   "$test encoded utf8 dir matches non-utf8";
    is   $utf8 => $non_utf8_decoded,   "$test utf8 dir matches decoded non-utf8";
}

plan tests => 9;

use Cwd;
my $currentdir = getcwd();

# Test getcwd, cwd, fastgetcwd, fastcwd
chdir("$test_root/$unicode_dir") or die "Couldn't chdir to $test_root/$unicode_dir: $!";
for my $test (qw(getcwd cwd fastgetcwd fastcwd)) {
    subtest "utf8$test" => sub {
        # To keep results in
        my $utf8;
        my $non_utf8;
        {
            use Cwd;
            $non_utf8 = (\&{$test})->();
        }

        {
            use Cwd::utf8;
            $utf8 = (\&{$test})->();
        }
        check_dirs($test, $utf8, $non_utf8);
    }
}

# Check no Cwd::utf8;
subtest no_cwd_utf8 => sub {
    my $test = "no Cwd::utf8";

    # To keep results in
    my $utf8;
    my $non_utf8;

    use Cwd::utf8;
    $utf8 = getcwd();

    no Cwd::utf8;
    $non_utf8 = getcwd();

    check_dirs($test, $utf8, $non_utf8);
};

chdir($currentdir) or die "Can't chdir back to original dir $currentdir: $!";

# Test abs_path, realpath, fast_abs_path, fast_realpath
for my $test (qw(abs_path realpath fast_abs_path fast_realpath)) {
    subtest "utf8$test" => sub {
        # To keep results in
        my $utf8;
        my $non_utf8;
        {
            use Cwd qw(abs_path realpath fast_abs_path fast_realpath);
            $non_utf8 = (\&{$test})->("$test_root/$unicode_dir");
        }

        {
            use Cwd::utf8 qw(abs_path realpath fast_abs_path fast_realpath);
            $utf8 = (\&{$test})->("$test_root/$unicode_dir");
        }
        check_dirs($test, $utf8, $non_utf8);
    }
}
