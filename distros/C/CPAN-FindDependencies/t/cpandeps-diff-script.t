use strict;
use warnings;

use CPAN::FindDependencies qw(finddeps);

use Test::More;
use Test::Differences;

use Devel::CheckOS;
use Capture::Tiny qw(capture);
use Config;
use File::Path qw(remove_tree);

$ENV{CPANDEPS_DIFF_DIR} = '.';
remove_tree('.cpandeps-diff');
END {
    remove_tree('.cpandeps-diff') if(Test::More->builder()->is_passing());
}

SKIP: {
    skip "Windows is just weird", 1
        if(Devel::CheckOS::os_is('MicrosoftWindows'));

my @default_cmd = (
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    'blib/script/cpandeps-diff',
    qw(perl 5.30.3)
);
my @mirror = qw(mirror t/mirrors/privatemirror);

my($stdout, $stderr) = capture { system( @default_cmd, 'help') };
like($stdout, qr/cpandeps-diff.*add.*Some::Module/, "Can spew out some help");

($stdout, $stderr) = capture { system( @default_cmd, 'list') };
eq_or_diff($stdout, '', "Starting with an empty db");

note("Try to add without saying what to add");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, 'add') };
eq_or_diff($stdout, '', "Nothing on STDOUT");
like($stderr, qr/You must provide an argument to 'add'/, "STDERR as expected");

note("Try to add properly");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Brewery)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");
note("Same again");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Brewery)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Test that args can be --args");
@default_cmd = (
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    'blib/script/cpandeps-diff',
    qw(--perl 5.30.3)
);
@mirror = qw(--mirror t/mirrors/privatemirror);

note("Add another module");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Fruit)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("List modules");
($stdout, $stderr) = capture { system( @default_cmd, qw(list)) };
eq_or_diff($stdout, join("\n", qw(Brewery Fruit))."\n", "Got expected list");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Report (nothing should have changed)");
($stdout, $stderr) = capture { system( @default_cmd, @mirror) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

open(my $fh, '>', ".cpandeps-diff/5.30.3/Brewery") || die("Can't fiddle with cached deps: $!\n");
print $fh join("\n",
    "F/FR/FRUITCO/Fruit-1.1.tar.gz",
    "P/PR/PROTEIN/Dead-Rat-94.tar.gz",
    "P/PR/PROTEIN/Human-Toe-1.5.tar.gz"
);
close($fh);

note("Report (there were changes)");
($stdout, $stderr) = capture { system( @default_cmd, @mirror) };
eq_or_diff($stdout,
"Differences found in dependencies for Brewery:
+--+-----------------------------------+--+---------------------------------------------+
* 1|F/FR/FRUITCO/Fruit-1.1.tar.gz      * 1|F/FR/FRUITCO/Fruit-1.0.tar.bz2               *
* 2|P/PR/PROTEIN/Dead-Rat-94.tar.gz\\n  * 2|F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.zip  *
* 3|P/PR/PROTEIN/Human-Toe-1.5.tar.gz  *  |                                             |
+--+-----------------------------------+--+---------------------------------------------+
", "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Remove module from db");
($stdout, $stderr) = capture { system( @default_cmd, qw(rm Fruit)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("List modules again");
($stdout, $stderr) = capture { system( @default_cmd, qw(list)) };
eq_or_diff($stdout, "Brewery\n", "Got expected list");

note("Now add a second mirror, and a module from it");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add CPAN::FindDependencies mirror DEFAULT)) };
ok((stat(".cpandeps-diff/5.30.3/CPAN::FindDependencies"))[7] > 100,
    "yay, we got that module's dependencies from the second mirror");
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("List modules again");
($stdout, $stderr) = capture { system( @default_cmd, qw(list)) };
eq_or_diff($stdout, join("\n", qw(Brewery CPAN::FindDependencies))."\n", "Got expected list");

note("Change the deps of the module on the second mirror and report the change");
open($fh, '>>', ".cpandeps-diff/5.30.3/CPAN::FindDependencies") || die("Can't fiddle with cached deps: $!\n");
print $fh "\nthis isn't a real dep, LOL";
close($fh);
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(mirror DEFAULT report CPAN::FindDependencies) ) };
like($stdout, qr{\|this isn't a real dep, LOL\s+\*\s+\|\s+\|}, "Differences found");
eq_or_diff($stderr, '', "Nothing on STDERR");

my $prev_size = (stat(".cpandeps-diff/5.30.3/Brewery"))[7];
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(mirror DEFAULT report Brewery) ) };
ok((stat(".cpandeps-diff/5.30.3/Brewery"))[7] != $prev_size,
    "And a module with deps on both mirrors got spotted too");

};

done_testing();
