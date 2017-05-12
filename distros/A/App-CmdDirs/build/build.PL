#!/usr/bin/env perl
# Thanks to App::cpanminus
# See: https://github.com/miyagawa/cpanminus.git:script/build.PL
use English;

my $baseDir = '.';
if (scalar(@ARGV) > 0) {
    $baseDir = $ARGV[0];
}

# build/cmddirs.PL is the command-line framework (option parsing, etc.)
open my $in,  "<", "build/cmddirs.PL" or die $!;
# The fatpacked binary we are building
open my $out, ">", "$baseDir/cmddirs.tmp" or die $!;

print STDERR "Generating cmddirs from script/cmddirs.PL\n";

# FatPacker wants it's lib
mkdir "fatlib";
while (<$in>) {
    # Remove & replace things from bin/cmddirs.PL
    next if /Auto-removed/;
    s/DEVELOPERS:.*/DO NOT EDIT -- this is an auto generated file/;
    s/.*__FATPACK__/`$EXECUTABLE_NAME -e "use App::FatPacker -run_script" file`/e;
    print $out $_;
}

close $out;

# Cleanup, make our fatpacked binary executable
unlink "$baseDir/cmddirs";
rename "$baseDir/cmddirs.tmp", "$baseDir/cmddirs";
chmod 0755, "$baseDir/cmddirs";

END { unlink "$baseDir/cmddirs.tmp" }
