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
  @val = $obj->get_structure(@test);
  $err = $obj->err();
  return (@val,$err);
}

$obj = new Data::Nested;
$$obj{"struct"} = { "/"    => { "type"    => "hash",
                              },
                    "/hn"  => { "type"    => "hash",
                                "uniform" => 0,
                              },
                    "/hu"  => { "type"    => "hash",
                                "uniform" => 1,
                              },
                    "/auu" => { "type"    => "list",
                                "ordered" => 0,
                                "uniform" => 1,
                              },
                    "/aou" => { "type"    => "list",
                                "ordered" => 1,
                                "uniform" => 1,
                              },
                    "/aon" => { "type"    => "list",
                                "ordered" => 1,
                                "uniform" => 0,
                              },
                    "/s" =>   { "type"    => "scalar",
                              },

                    "/auu/*" => { "type"    => "scalar" },
                    "/aou/*" => { "type"    => "other" },
                    "/aon/0" => { "type"    => "scalar" },
                    "/aon/1" => { "type"    => "other" },

                    "/hn/a"  => { "type"    => "scalar" },
                    "/hn/b"  => { "type"    => "other" },
                    "/hu/*"  => { "type"    => "scalar" },

                    "/h"     => { "type"    => "hash" },
                    "/a"     => { "type"    => "list" },

                    "/h2"     => { "type"    => "hash",
                                   "uniform" => 1 },
                    "/h2/*"   => { "type"    => "hash",
                                   "uniform" => 1 },
                    "/h2/*/*" => { "type"    => "hash",
                                   "uniform" => 1 },

                    "/h3"     => { },
                  };

$tests = "

/z ~ _blank_ ndschk04

/z type ~ _blank_ ndschk04

/z valid ~ 0 _blank_

/hn type ~ hash _blank_

/hn ~ hash _blank_

/hn valid ~ 1 _blank_

/h3 ~ _blank_ ndschk05

/auu/1 ~ scalar _blank_

/auu/* ~ scalar _blank_

/aou/1 ~ other _blank_

/aou/* ~ other _blank_

/aon/0 ~ scalar _blank_

/aon/1 ~ other _blank_

/aon/2 ~ _blank_ ndschk04

/aon/* ~ _blank_ ndschk04

/hn/a ~ scalar _blank_

/hn/b ~ other _blank_

/hn/c ~ _blank_ ndschk04

/hn/* ~ _blank_ ndschk04

/hn keys ~ a b _blank_

/hu/a ~ scalar _blank_

/hu/* ~ scalar _blank_

/auu ordered ~ 0 _blank_

/aon ordered ~ 1 _blank_

/auu uniform ~ 1 _blank_

/aon uniform ~ 0 _blank_

/hn ordered ~ _blank_ ndschk06

/hn uniform ~ 0 _blank_

/hu uniform ~ 1 _blank_

/a uniform ~ 1 _blank_

/a ordered ~ 0 _blank_

/h2/*/foo type ~ hash _blank_

/h2/a/foo type ~ hash _blank_

/hn/a uniform ~ _blank_ ndschk07

/hn/a keys ~ _blank_ ndschk08

/h2 keys ~ _blank_ ndschk09

/h2 foo ~ _blank_ ndschk99

";

print "get_structure...\n";
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

