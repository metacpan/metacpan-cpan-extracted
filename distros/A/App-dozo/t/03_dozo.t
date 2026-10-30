use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

# Skip tests on platforms without bash or with old bash
BEGIN {
    my $bash_check = `bash --version 2>&1`;
    if ($? != 0) {
        plan skip_all => 'bash is not available on this system';
    }
    if ($bash_check =~ /version (\d+)\.(\d+)/) {
        my ($major, $minor) = ($1, $2);
        if ($major < 4 || ($major == 4 && $minor < 3)) {
            plan skip_all => "bash 4.3+ required (found $major.$minor)";
        }
    }
}

# Skip if getoptlong.sh is not available
BEGIN {
    my $check = `command -v getoptlong.sh 2>/dev/null`;
    if ($? != 0) {
        plan skip_all => 'getoptlong.sh is not available in PATH';
    }
}

my $dozo = File::Spec->rel2abs('script/dozo');

# Use empty temp dir to avoid reading any .dozorc (HOME, git top, cwd)
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;
chdir $empty_home or die "Cannot chdir to $empty_home: $!";

# Check if dozo exists
ok(-x $dozo, 'dozo is executable');

# Test: help option
subtest 'help option' => sub {
    my $out = `$dozo --help 2>&1`;
    like($out, qr/dozo.*Docker.*Zero Overhead/i, '--help shows description');
    like($out, qr/--image/, '--help shows --image option');
    like($out, qr/--live/, '--help shows --live option');
    like($out, qr/--kill/, '--help shows --kill option');
};

# Test: missing image error
subtest 'missing image error' => sub {
    my $out = `$dozo echo hello 2>&1`;
    my $status = $? >> 8;
    isnt($status, 0, 'exits with error when no image specified');
    like($out, qr/image.*must be specified/i, 'error message mentions image');
};

# Test: option parsing (valid options should reach "image must be specified" error)
subtest 'option parsing' => sub {
    my $out = `$dozo -W -B -R 2>&1`;
    unlike($out, qr/no such option/i, 'options -W -B -R are recognized');
    like($out, qr/image.*must be specified/i, 'reaches image check (options parsed successfully)');
};

# Test: combined options like -KL
subtest 'combined options' => sub {
    my $out = `$dozo --help 2>&1`;
    like($out, qr/--kill/, '-K option documented');
    like($out, qr/--live/, '-L option documented');
};

# Test: .dozorc parsing with quoted arguments
subtest '.dozorc parsing' => sub {
    my $test_dir = tempdir(CLEANUP => 1);
    my $rc_file = "$test_dir/.dozorc";

    local $ENV{HOME} = $test_dir;
    chdir $test_dir or die "Cannot chdir to $test_dir: $!";

    # Test simple option: -I should set the image
    open my $fh, '>', $rc_file or die "Cannot create $rc_file: $!";
    print $fh "-I testimage:latest\n";
    close $fh;

    # With -I set in .dozorc, should not get "image must be specified" error
    my $out = `$dozo -n echo test 2>&1`;
    unlike($out, qr/image.*must be specified/i, '.dozorc -I option is parsed');

    # Test quoted argument with spaces
    open $fh, '>', $rc_file or die "Cannot create $rc_file: $!";
    print $fh qq{-E "TEST_VAR=hello world"\n};
    close $fh;

    # Should still get "image must be specified" (no -I), but no parse error
    $out = `$dozo echo test 2>&1`;
    like($out, qr/image.*must be specified/i, '.dozorc with quoted args is parsed without error');
    unlike($out, qr/xargs|error|unterminated/i, 'no parsing error for quoted args');
};

# Test: -V option without colon (same path mount)
subtest '-V option without colon' => sub {
    my $test_dir = tempdir(CLEANUP => 1);
    my $rc_file = "$test_dir/.dozorc";

    local $ENV{HOME} = $test_dir;
    chdir $test_dir or die "Cannot chdir to $test_dir: $!";

    # Test single path without colon in .dozorc
    open my $fh, '>', $rc_file or die "Cannot create $rc_file: $!";
    print $fh "-I alpine\n";
    print $fh "-V /var/run/docker.sock\n";
    close $fh;

    # Should parse without error (use -n to avoid running docker)
    my $out = `$dozo -n echo test 2>&1`;
    unlike($out, qr/no such option|invalid.*option|getoptlong/i, '-V without colon is parsed without error');

    # Test multiple paths (comma-separated)
    open $fh, '>', $rc_file or die "Cannot create $rc_file: $!";
    print $fh "-I alpine\n";
    print $fh "-V /tmp,/var/tmp\n";
    close $fh;

    $out = `$dozo -n echo test 2>&1`;
    unlike($out, qr/no such option|invalid.*option|getoptlong/i, '-V with comma-separated paths is parsed without error');

    # Test path with colon (explicit mount) using existing paths
    open $fh, '>', $rc_file or die "Cannot create $rc_file: $!";
    print $fh "-I alpine\n";
    print $fh "-V /tmp:/container/tmp\n";
    close $fh;

    $out = `$dozo -n echo test 2>&1`;
    unlike($out, qr/no such option|invalid.*option|getoptlong/i, '-V with explicit colon mount has no parsing error');
};

# Test: -B passes piped input but does not wait for a terminal
subtest '-B with piped input' => sub {
    my $out = `echo x | $dozo -B -n -I alpine true 2>&1`;
    like($out, qr/--interactive/, '-B with a pipe keeps --interactive');
    unlike($out, qr/--tty/, '-B with a pipe gives no --tty');
    $out = `$dozo -n -I alpine true </dev/null 2>&1`;
    like($out, qr/--interactive/, 'without -B --interactive is given');
};

# Test: --bundle prints a single file that runs without getoptlong.sh
subtest '--bundle' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $bundled = "$dir/dozo";
    system("$dozo -q --bundle > $bundled") == 0 or die "--bundle failed";
    chmod 0755, $bundled;
    open my $fh, '<', $bundled or die;
    my $text = do { local $/; <$fh> };
    close $fh;
    like($text, qr/\A#!.*\n# getoptlong\.sh embedded by dozo --bundle\n(?s:.*)^gol_parse \(\)(?s:.*)^# end of getoptlong\.sh\n/m,
         'getoptlong.sh is inserted after the first line');
    my ($orig) = do { local(@ARGV, $/) = ($dozo); <> };
    my $body = $orig =~ s/\A.*\n//r;
    like($text, qr/\Q$body\E\z/, 'the rest of dozo follows unchanged');

    # a PATH with bash but without getoptlong.sh
    my $bin = "$dir/bin";
    mkdir $bin;
    my ($bash) = grep { -x } map { "$_/bash" } split /:/, $ENV{PATH};
    symlink $bash, "$bin/bash" or die "bash not found in PATH";
    local $ENV{PATH} = "$bin:/usr/bin:/bin";
    my $out = `$bundled -n -I alpine echo test 2>&1`;
    like($out, qr/docker run .* alpine echo test/, 'bundled dozo runs without getoptlong.sh');
    $out = `$bundled --no-such-option 2>&1`;
    like($out, qr/no such option/, 'bundled dozo parses options');
    is(`$bundled -q --bundle`, $text, 'bundling a bundled dozo gives the same file');
};

done_testing;
