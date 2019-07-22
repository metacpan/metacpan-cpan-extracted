#!/bin/perl

use strict;
use warnings;
use v5.16;
use utf8;

use Test::More tests => 9;
use Cwd;
use File::Temp qw(tempdir);
use IPC::Run 'run';

my $pft = getcwd . '/bin/pft';
my ($in, $out, $err);

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "Could not chdir $dir: $!";

run ["$pft", '--version'], \undef, \$out, \$err;
diag("$pft --version says: ");
diag($_) foreach split /\n/, $err;

run ["$pft-init", qw(--site-home test)];
ok $? == 0 => 'Could construct';

# Creation of test page
run ["$pft-edit", qw(--stdin -P test)], \<<IN, \$out, \$err;
This is a test page.
Hello world!
IN
ok $? == 0 => 'Edit command 1 successful';
ok $out eq '' && $err eq '' => "Edit command 1 is silent (out=$out, err=$err)";

# Adding a blog page referencing the (hopefully!) missing welcome page.
run ["$pft-edit", qw(--stdin -B Pointer to test page)], \<<IN, \$out, \$err;
Hello, welcome to today's pointer to [the test page](:page:welcome)
Have a nice day!
IN
ok $? == 0 => 'Edit command 2 successful';
ok $out eq '' && $err eq '' => "Edit command 2 is silent (out=$out, err=$err)";

# A blog page referencing non-existing page should now result in a failure
# at compile time. We also test the `--site-home` flag to be working, since
# there won't be a 'welcome` page.
run ["$pft-make"], \undef, \$out, \$err;
ok $? != 1 => 'Cannot compile on broken link';
subtest 'Explicative error message' => sub {
    my($err1, $err2) = split /\n/, $err, 2;
    ok(
        $err1 =~
        /^Unresolved links in PFT::Map::Node\[id=b:\d{4}-\d{2}-\d{2}:pointer-to-test-page, virtual=no\]:$/,
        'Correct reference'
    );
    cmp_ok $err2 => eq => (<<'    EXPERR' =~ s/^    //rgm) => 'Explicative error message';
    - link: PFT::Text::Symbol[key:"page", args:["welcome"], start:49, len:13]
      reason: No matching item
    EXPERR
};

# Let's add that welcome page…
run ["$pft-edit", qw(--stdin -P welcome)], \<<IN, \$out, \$err;
Welcome! Yada yada.
IN

# Now compilation is expected to work.
run ["$pft-make"], \undef, \$out, \$err;
ok $? == 0 => 'Compilation works after link was fixed';
ok $out eq '' && $err eq '' => "Compilation command is silent (out=$out, err=$err)";
