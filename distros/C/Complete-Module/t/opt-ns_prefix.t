#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin;
require "testlib.pl";

use File::chdir;
use Test::More 0.98;

my $prefix = "Prefix" . int(rand()*900_000+100_000);
my $dir = tempdir(CLEANUP => 0);
{
    local $CWD = $dir;

    mkdir($prefix);
    $CWD = $prefix;

    mkdir("Foo");
    mkdir("Foo/Bar");
    write_text("Foo/Bar/Baz.pm", "");
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
}

DONE_TESTING:
done_testing;
