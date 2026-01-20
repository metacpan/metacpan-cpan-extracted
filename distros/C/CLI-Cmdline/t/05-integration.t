# t/05-integration.t - Real-world integration tests using executable scripts
use strict;
use warnings;
use Test::More tests => 25;
use Test::NoWarnings 'had_no_warnings';

use File::Temp qw(tempdir);
use Cwd qw(getcwd);

my $orig_dir = getcwd;
my $temp_dir = tempdir( CLEANUP => 1 );
chdir $temp_dir or die "Cannot chdir to $temp_dir: $!";

# Simple and robust script runner
sub run_script {
    my ($name, $code, @user_args) = @_;

    my $filename = "$name.pl";

    # Write script with shebang
    open my $fh, '>', $filename or die "Cannot write $filename: $!";
    print $fh "#!/usr/bin/perl\n";   # <-- important shebang
    print $fh $code;
    close $fh;

    # Make executable
    chmod 0755, $filename or die "Cannot chmod +x $filename: $!";

    # Run directly
    my $output = `./$filename @user_args 2>&1`;
    my $exit   = $? >> 8;

    return ($output, $exit);
}

sub script_ok {
    my ($desc, $code, $expected_output, $expected_exit, @user_args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($output, $exit) = run_script('script', $code, @user_args);

    # Normalize line endings
    $output =~ s/\r\n/\n/g;

    if (defined $expected_output) {
        is($output, $expected_output, "$desc - correct output");
    } else {
        note("Got output:\n$output");
    }

    is($exit, $expected_exit // 0, "$desc - correct exit code");
}

# ===========================================================================
# 01 - Simple switch counting with aliases
# ===========================================================================
my $code1 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( verbose => 0 );

parse(\%opt, 'verbose|v', '') or exit 1;   # <-- removed |vvv

print "V:", $opt{verbose}, "\n";
print "ARGS:@ARGV\n";
END

script_ok('01 - -vvv counts as 3', $code1, "V:3\nARGS:\n", 0, '-vvv');
script_ok('01 - --verbose used twice', $code1, "V:2\nARGS:\n", 0, '--verbose', '--verbose');

# ===========================================================================
# 02 - Required option with aliases
# ===========================================================================
my $code2 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( input => '', output => '' );

parse(\%opt, '', 'input|i output|o') or exit 2;

if ($opt{input} eq '') {
    print "MISSING\n";
    exit 3;
}

print "IN:$opt{input} OUT:$opt{output}\n";
print "POS:@ARGV\n";
END

script_ok('02 - required input via short -i', $code2, "IN:data.txt OUT:\nPOS:\n", 0, '-i', 'data.txt');
script_ok('02 - required input via attached =', $code2, "IN:hello OUT:\nPOS:\n", 0, '--input=hello');
script_ok('02 - missing required input → exit 3', $code2, "MISSING\n", 3);

# ===========================================================================
# 03 - Array collection with aliases
# ===========================================================================
my $code3 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( include => [] );

parse(\%opt, '', 'include|I|inc') or exit 1;

print "INCLUDES:", join(',', @{$opt{include}}), "\n";
print "REST:@ARGV\n";
END

script_ok('03 - multiple includes via mixed aliases', $code3,
    "INCLUDES:lib1,lib2,extra\nREST:file.pl\n", 0,
    '--include', 'lib1', '-I', 'lib2', '--inc=extra', 'file.pl'
);

# ===========================================================================
# 04 - -- stops option processing
# ===========================================================================
my $code4 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( verbose => 0 );

parse(\%opt, 'verbose|v', '') or exit 1;

print "V:$opt{verbose}\n";
print "ARGS:@ARGV\n";
END

script_ok('04 - -- stops option processing', $code4,
    "V:1\nARGS:--debug -hidden.pl\n", 0,
    '-v', '--', '--debug', '-hidden.pl'
);

# ===========================================================================
# 05 - Bundling with aliased short switches
# ===========================================================================
my $code5 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( x => 0, v => 0, quiet => 0 );

parse(\%opt, 'x|extract v|verbose quiet|q', '') or exit 1;

print "X:$opt{x} V:$opt{v} Q:$opt{quiet}\n";
END

script_ok('05 - bundling -xvq works', $code5, "X:1 V:1 Q:1\n", 0, '-xvq');

# ===========================================================================
# 06 - Unknown options cause failure
# ===========================================================================
my $code6 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = ( verbose => 0 );

parse(\%opt, 'verbose|v', '') or exit 2;

print "OK\n";
END

script_ok('06 - unknown long option --debug → exit 2', $code6, '', 2, '--debug');
script_ok('06 - unknown short option -z → exit 2', $code6, '', 2, '-z');

# ===========================================================================
# 07 - Full realistic script
# ===========================================================================
my $code7 = <<'END';
use strict;
use warnings;
use CLI::Cmdline qw(parse);

my %opt = (
    verbose => 0,
    quiet   => 0,
    dryrun  => 0,
    input   => '',
    output  => '',
    define  => [],
);

parse(\%opt,
    'verbose|v quiet|q dryrun|n|dry-run',
    'input|i output|o define|D'
) or die "Usage: $0 [options] files...\n";

die "Error: --input required\n" if $opt{input} eq '';

my $level = $opt{verbose} - $opt{quiet};
print "Level: $level Dry: $opt{dryrun}\n";
print "In: $opt{input} Out: $opt{output}\n";
print "Defines: ", join(';', @{$opt{define}}), "\n";
print "Files: @ARGV\n";
END

script_ok('07 - full script success', $code7,
    "Level: 2 Dry: 1\nIn: in.txt Out: out.log\nDefines: DEBUG;TEST=1\nFiles: a.pl b.pl\n", 0,
    '-vv', '--dry-run', '--input=in.txt', '-o', 'out.log', '-D', 'DEBUG', '--define=TEST=1', 'a.pl', 'b.pl'
);

script_ok('07 - full script missing required input → die', $code7,
    "Error: --input required\n", 255,
    '-vv'
);

# Return to original directory
chdir $orig_dir;

had_no_warnings();
done_testing();

