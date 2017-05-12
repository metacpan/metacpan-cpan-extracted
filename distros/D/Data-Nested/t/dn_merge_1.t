#!/usr/bin/perl -w

require 5.001;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
  $dir="./lib";
  $tdir="t";
} elsif ( -f "test.pl" ) {
  require "test.pl";
  $dir="../lib";
  $tdir=".";
} else {
  die "ERROR: cannot find test.pl\n";
}

unshift(@INC,$dir);
use Data::Nested;

sub test {
  (@test)=@_;
  return ($obj->keys("ele",@test),$obj->values("ele",@test));
}

$obj = new Data::Nested;

$obj->set_structure("type", "hash",   "/h_keep");
$obj->set_merge    ("merge","/h_keep","keep");

$obj->set_structure("type", "hash",   "/h_replace");
$obj->set_merge    ("merge","/h_replace","replace");

$obj->set_structure("type", "hash",   "/h_merge");
$obj->set_merge    ("merge","/h_merge","merge");

$obj->set_structure("type",    "list",  "/ol_keep");
$obj->set_structure("ordered", "1", "/ol_keep");
$obj->set_merge    ("merge","/ol_keep","keep");

$obj->set_structure("type",    "list",  "/ol_replace");
$obj->set_structure("ordered", "1", "/ol_replace");
$obj->set_merge    ("merge","/ol_replace","replace");

$obj->set_structure("type",    "list",  "/ol_merge");
$obj->set_structure("ordered", "1", "/ol_merge");
$obj->set_merge    ("merge","/ol_merge","merge");

$obj->set_structure("type",    "list",  "/ul_keep");
$obj->set_structure("ordered", "0", "/ul_keep");
$obj->set_merge    ("merge","/ul_keep","keep");

$obj->set_structure("type",    "list",  "/ul_replace");
$obj->set_structure("ordered", "0", "/ul_replace");
$obj->set_merge    ("merge","/ul_replace","replace");

$obj->set_structure("type",    "list",  "/ul_append");
$obj->set_structure("ordered", "0", "/ul_append");
$obj->set_merge    ("merge","/ul_append","append");

$obj->set_structure("type",    "list",  "/ol_keep2");
$obj->set_structure("ordered", "1", "/ol_keep2");
$obj->set_merge    ("merge","/ol_keep2","keep");

$obj->set_structure("type",    "list",  "/ol_replace2");
$obj->set_structure("ordered", "1", "/ol_replace2");
$obj->set_merge    ("merge","/ol_replace2","replace");

$obj->set_structure("type",    "list",  "/ol_merge2");
$obj->set_structure("ordered", "1", "/ol_merge2");
$obj->set_merge    ("merge","/ol_merge2","merge");

$obj->set_structure("type",    "list",  "/ul_keep2");
$obj->set_structure("ordered", "0", "/ul_keep2");
$obj->set_merge    ("merge","/ul_keep2","keep");

$obj->set_structure("type",    "list",  "/ul_replace2");
$obj->set_structure("ordered", "0", "/ul_replace2");
$obj->set_merge    ("merge","/ul_replace2","replace");

$obj->set_structure("type",    "list",  "/ul_append2");
$obj->set_structure("ordered", "0", "/ul_append2");
$obj->set_merge    ("merge","/ul_append2","append");

$nds = { 
        "h_keep"     => { "a"  => { "a1"  => "val_a1a",
                                    "a2"  => "val_a2a" },
                          "b"  => { "b1"  => "val_b1a",
                                    "b2"  => "val_b2a" }
                        },
        "h_replace"  => { "a"  => { "a1"  => "val_a1a",
                                    "a2"  => "val_a2a" },
                          "b"  => { "b1"  => "val_b1a",
                                    "b2"  => "val_b2a" }
                        },
        "h_merge"    => { "a"  => { "a1"  => "val_a1a",
                                    "a2"  => "val_a2a" },
                          "b"  => { "b1"  => "val_b1a",
                                    "b2"  => "val_b2a" }
                        },
        "ol_keep"    => [ "val_1a", "", "val_3a" ],
        "ol_replace" => [ "val_1a", "", "val_3a" ],
        "ol_merge"   => [ "val_1a", "", "val_3a" ],
        "ul_keep"    => [ "val_1a", "", "val_3a" ],
        "ul_replace" => [ "val_1a", "", "val_3a" ],
        "ul_append"  => [ "val_1a", "", "val_3a" ],

        "ol_keep2"    => [ "val_1a", undef, "val_3a" ],
        "ol_replace2" => [ "val_1a", undef, "val_3a" ],
        "ol_merge2"   => [ "val_1a", undef, "val_3a" ],
        "ul_keep2"    => [ "val_1a", undef, "val_3a" ],
        "ul_replace2" => [ "val_1a", undef, "val_3a" ],
        "ul_append2"  => [ "val_1a", undef, "val_3a" ],
       };

$obj->nds("ele",$nds,1);

$nds = { 
        "h_keep"     => { "c"  => { "c1"  => "val_c1b",
                                    "c2"  => "val_c2b" },
                          "b"  => { "b1"  => "val_b1b",
                                    "b2"  => "val_b2b" }
                        },
        "h_replace"  => { "c"  => { "c1"  => "val_c1b",
                                    "c2"  => "val_c2b" },
                          "b"  => { "b1"  => "val_b1b",
                                    "b2"  => "val_b2b" }
                        },
        "h_merge"    => { "c"  => { "c1"  => "val_c1b",
                                    "c2"  => "val_c2b" },
                          "b"  => { "b1"  => "val_b1b",
                                    "b2"  => "val_b2b" }
                        },
        "ol_keep"    => [ "val_1b", "val_2b", "" ],
        "ol_replace" => [ "val_1b", "val_2b", "" ],
        "ol_merge"   => [ "val_1b", "val_2b", "" ],
        "ul_keep"    => [ "val_1b", "val_2b", "" ],
        "ul_replace" => [ "val_1b", "val_2b", "" ],
        "ul_append"  => [ "val_1b", "val_2b", "" ],

        "ol_keep2"    => [ "val_1b", "val_2b", undef ],
        "ol_replace2" => [ "val_1b", "val_2b", undef ],
        "ol_merge2"   => [ "val_1b", "val_2b", undef ],
        "ul_keep2"    => [ "val_1b", "val_2b", undef ],
        "ul_replace2" => [ "val_1b", "val_2b", undef ],
        "ul_append2"  => [ "val_1b", "val_2b", undef ],
       };

$obj->merge("ele",$nds,1);

$tests =
[
  [
    [ qw(/h_keep/a) ],
    [ qw(a1 a2 val_a1a val_a2a) ]
  ],

  [
    [ qw(/h_keep/b) ],
    [ qw(b1 b2 val_b1a val_b2a) ]
  ],

  [
    [ qw(/h_keep/c) ],
    [ "_undef_","_undef_" ]
  ],

  [
    [ qw(/h_replace/a) ],
    [ "_undef_","_undef_" ]
  ],

  [
    [ qw(/h_replace/b) ],
    [ qw(b1 b2 val_b1b val_b2b) ]
  ],

  [
    [ qw(/h_replace/c) ],
    [ qw(c1 c2 val_c1b val_c2b) ]
  ],

  [
    [ qw(/h_merge/a) ],
    [ qw(a1 a2 val_a1a val_a2a) ]
  ],

  [
    [ qw(/h_merge/b) ],
    [ qw(b1 b2 val_b1a val_b2a) ]
  ],

  [
    [ qw(/h_merge/c) ],
    [ qw(c1 c2 val_c1b val_c2b) ]
  ],

  [
    [ qw(/ol_keep) ],
    [ qw(0 2 val_1a val_3a) ]
  ],

  [
    [ qw(/ol_replace) ],
    [ qw(0 1 val_1b val_2b) ]
  ],

  [
    [ qw(/ol_merge) ],
    [ qw(0 1 2 val_1a val_2b val_3a) ]
  ],

  [
    [ qw(/ul_keep) ],
    [ qw(0 2 val_1a val_3a) ]
  ],

  [
    [ qw(/ul_replace) ],
    [ qw(0 1 val_1b val_2b) ]
  ],

  [
    [ qw(/ul_append) ],
    [ qw(0 2 3 4 val_1a val_3a val_1b val_2b) ]
  ],

  [
    [ qw(/ol_keep2) ],
    [ qw(0 2 val_1a val_3a) ]
  ],

  [
    [ qw(/ol_replace2) ],
    [ qw(0 1 val_1b val_2b) ]
  ],

  [
    [ qw(/ol_merge2) ],
    [ qw(0 1 2 val_1a val_2b val_3a) ]
  ],

  [
    [ qw(/ul_keep2) ],
    [ qw(0 2 val_1a val_3a) ]
  ],

  [
    [ qw(/ul_replace2) ],
    [ qw(0 1 val_1b val_2b) ]
  ],

  [
    [ qw(/ul_append2) ],
    [ qw(0 2 3 4 val_1a val_3a val_1b val_2b) ]
  ],

];

print "merge...\n";
test_Func(\&test,$tests,$runtests);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

