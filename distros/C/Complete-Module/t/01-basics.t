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
my $dir = tempdir(CLEANUP => 1);
{
    local $CWD = $dir;

    mkdir($prefix);

    $CWD = $prefix;

    write_file("Foo.pm", "");
    mkdir("Foo");
    mkdir("Bar");
    mkdir("Bar/M1");
    mkdir("Bar/M2");
    write_file("Bar/Mod3.pm", "");
    write_file("Baz.pm", "");

    mkdir("Type");
    write_file("Type/T1.pm", "");
    write_file("Type/T1.pmc", "");
    write_file("Type/T1.pod", "");
    write_file("Type/T2.pm", "");
    write_file("Type/T3.pmc", "");
    write_file("Type/T4.pod", "");
    mkdir("Type/T5");
}

{
    local @INC = ($dir, @INC);
    no warnings 'once';
    local $Complete::Setting::OPT_FUZZY = 0;
    subtest "basics" => sub {
        test_complete(args=>{word=>"$prefix"},
                      result=>[
                          "$prefix/",
                      ]);
        test_complete(args=>{word=>"$prefix/"},
                      result=>[
                          "$prefix/Bar/",
                          "$prefix/Baz",
                          "$prefix/Foo",
                          "$prefix/Foo/",
                          "$prefix/Type/",
                      ]);
        test_complete(args=>{word=>"$prefix/c"},
                      result=>[]);
        test_complete(args=>{word=>"$prefix/Foo"},
                      result=>[
                          "$prefix/Foo",
                          "$prefix/Foo/",
                      ]);
        test_complete(args=>{word=>"$prefix/Bar"},
                      result=>[
                          "$prefix/Bar/",
                      ]);
        test_complete(args=>{word=>"$prefix\::Bar::"},
                      result=>[
                          "$prefix\::Bar::M1::",
                          "$prefix\::Bar::M2::",
                          "$prefix\::Bar::Mod3",
                      ]);
        test_complete(args=>{word=>"$prefix\::Bar::Mod3"},
                      result=>[
                          "$prefix\::Bar::Mod3",
                      ]);
        test_complete(args=>{word=>"$prefix\::Bar::Mod3::"},
                      result=>[]);
        test_complete(args=>{word=>"$prefix\::Bar::c"},
                      result=>[]);
        test_complete(args=>{word=>"$prefix\::Type::T"},
                      result=>[
                          "$prefix\::Type::T1",
                          "$prefix\::Type::T2",
                          "$prefix\::Type::T3",
                          "$prefix\::Type::T4",
                          "$prefix\::Type::T5::",
                      ]);
    };

    subtest "shortcut prefixes" => sub {
        no warnings 'once';
        local $Complete::Module::OPT_SHORTCUT_PREFIXES = {
            'abc' => "$prefix/Bar/",
        };
        test_complete(args=>{word=>"abc"},
                      result=>[
                          "$prefix/Bar/M1/",
                          "$prefix/Bar/M2/",
                          "$prefix/Bar/Mod3",
                      ]);
    };

    subtest "opt: exp_im_path" => sub {
        test_complete(args=>{word=>"$prefix\::B::M", exp_im_path=>1},
                      result=>[
                          "$prefix\::Bar::M1::",
                          "$prefix\::Bar::M2::",
                          "$prefix\::Bar::Mod3",
                      ]);
    };
    subtest "opt: find_pm" => sub {
        test_complete(args=>{word=>"$prefix\::Type::T", find_pm=>0},
                      result=>[
                          "$prefix\::Type::T1",
                          "$prefix\::Type::T3",
                          "$prefix\::Type::T4",
                          "$prefix\::Type::T5::",
                      ]);
    };
    subtest "opt: find_pmc" => sub {
        test_complete(args=>{word=>"$prefix\::Type::T", find_pmc=>0},
                      result=>[
                          "$prefix\::Type::T1",
                          "$prefix\::Type::T2",
                          "$prefix\::Type::T4",
                          "$prefix\::Type::T5::",
                      ]);
    };
    subtest "opt: find_pod" => sub {
        test_complete(args=>{word=>"$prefix\::Type::T", find_pod=>0},
                      result=>[
                          "$prefix\::Type::T1",
                          "$prefix\::Type::T2",
                          "$prefix\::Type::T3",
                          "$prefix\::Type::T5::",
                      ]);
    };
    subtest "opt: find_prefix" => sub {
        test_complete(args=>{word=>"$prefix\::Type::T", find_prefix=>0},
                      result=>[
                          "$prefix\::Type::T1",
                          "$prefix\::Type::T2",
                          "$prefix\::Type::T3",
                          "$prefix\::Type::T4",
                      ]);
    };
    # XXX opt map_case is mostly irrelevant
}

DONE_TESTING:
done_testing;
