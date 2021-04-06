#!perl

use 5.010001;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin;
require "testlib.pl";

use File::chdir;
use Test::More 0.98;

my $prefix  = "Prefix" . int(rand()*900_000+100_000);
my $prefix2;
while (1) {
    $prefix2 = "Prefix" . int(rand()*900_000+100_000);
    last unless $prefix2 eq $prefix;
}
my $prefix3;
while (1) {
    $prefix3 = "Prefix" . int(rand()*900_000+100_000);
    last unless $prefix3 eq $prefix || $prefix3 eq $prefix2;
}

my $dir = tempdir(CLEANUP => 0);
{
    local $CWD = $dir;

    mkdir($prefix);
    mkdir($prefix2);
    mkdir($prefix3);

    $CWD = $prefix;

    mkdir("Foo");
    mkdir("Foo/Bar");
    write_text("Foo/Bar/Baz.pm", "");

    $CWD = "../$prefix2";
    mkdir("Foo");
    write_text("Foo/Bar.pm", "");

    $CWD = "../$prefix3";
    mkdir("Foo");
    write_text("Foo/Baz.pm", "");
}

{
    no warnings 'once';

    local @INC = ($dir, @INC);
    local $Complete::Common::OPT_FUZZY = 0;
    local $Complete::Common::OPT_DIG_LEAF = 0;
    test_complete(args=>{word=>"", ns_prefix=>"$prefix/Foo"},
                  result=>[sort +(
                      "Bar/",
                  )]);
    test_complete(args=>{word=>"", ns_prefix=>"$prefix/Foo/"},
                  result=>[sort +(
                      "Bar/",
                  )]);
    test_complete(args=>{word=>"", ns_prefix=>"$prefix/Foo/Bar"},
                  result=>[sort +(
                      "Baz",
                  )]);
    test_complete(args=>{word=>"", ns_prefix=>"$prefix/Foo/Bar/"},
                  result=>[sort +(
                      "Baz",
                 )]);

    test_complete(args=>{word=>"", ns_prefixes=>[$prefix,$prefix2,$prefix3]},
                  result=>[sort +(
                      "Foo/",
                  )]);
    test_complete(args=>{word=>"", ns_prefixes=>["$prefix/Foo","$prefix2/Foo","$prefix3/Foo"]},
                  result=>[
                      "Bar/",
                      "Bar",
                      "Baz",
                  ]);
}

DONE_TESTING:
done_testing;
