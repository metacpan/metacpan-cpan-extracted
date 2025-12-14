use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

my $xlate = File::Spec->rel2abs('script/xlate');
my $dozo = File::Spec->rel2abs('script/dozo');

# Use empty temp dir to avoid reading any .dozorc (HOME, git top, cwd)
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;
chdir $empty_home or die "Cannot chdir to $empty_home: $!";

# Check if xlate script exists
ok(-x $xlate, 'xlate script is executable');

# Check if dozo exists (xlate depends on it for Docker operations)
ok(-x $dozo, 'dozo script is executable');

# Test: help option
subtest 'help option' => sub {
    my $out = `$xlate -h 2>&1`;
    like($out, qr/xlate.*TRANSlate/i, '-h shows description');
    like($out, qr/-t.*target language/, '-h shows -t option');
    like($out, qr/-e.*translation engine/, '-h shows -e option');
    like($out, qr/Docker options/, '-h shows Docker options section');
};

# Test: version option
subtest 'version option' => sub {
    my $out = `$xlate -v 2>&1`;
    like($out, qr/^\d+\.\d+/, '-v shows version number');
};

# Test: library file option
subtest 'library file option' => sub {
    my $out = `$xlate -l XLATE.mk 2>&1`;
    # Should output the content of XLATE.mk or list files
    ok(length($out) > 0, '-l option produces output');
};

# Test: options are recognized (without actually running translation)
subtest 'option parsing' => sub {
    # These should not cause "invalid option" errors
    my $out;

    $out = `$xlate -e deepl -h 2>&1`;
    unlike($out, qr/不正なオプション|invalid option/i, '-e option is recognized');

    $out = `$xlate -t JA -h 2>&1`;
    unlike($out, qr/不正なオプション|invalid option/i, '-t option is recognized');

    $out = `$xlate -o cm -h 2>&1`;
    unlike($out, qr/不正なオプション|invalid option/i, '-o option is recognized');
};

# Test: Docker options are passed to dozo
subtest 'Docker option delegation' => sub {
    # Set environment to simulate running on Docker (to prevent actual execution)
    local $ENV{XLATE_RUNNING_ON_DOCKER} = 1;

    # With XLATE_RUNNING_ON_DOCKER set, Docker options should be skipped
    my $out = `$xlate -h 2>&1`;
    like($out, qr/-D.*run xlate on the container/, '-D option is documented');
    like($out, qr/-C.*execute following command/, '-C option is documented');
    like($out, qr/-L.*live container/, '-L option is documented');
    like($out, qr/-K.*kill/, '-K option is documented');
};

done_testing;
