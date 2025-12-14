use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

my $dozo = File::Spec->rel2abs('script/dozo');
my $getoptlong = File::Spec->rel2abs('share/getoptlong/getoptlong.sh');

# Use empty temp dir to avoid reading any .dozorc (HOME, git top, cwd)
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;
chdir $empty_home or die "Cannot chdir to $empty_home: $!";

# Check if dozo exists
ok(-x $dozo, 'dozo is executable');

# Check if getoptlong.sh exists
ok(-f $getoptlong, 'getoptlong.sh exists');

# Test: help option
subtest 'help option' => sub {
    my $out = `$dozo --help 2>&1`;
    like($out, qr/dozo.*Docker Runner/i, '--help shows description');
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
    my $out = `$dozo echo test 2>&1`;
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

done_testing;
