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
  @val = $obj->paths(@test);
  $err = $obj->err();
  return ($err,@val);
}

$obj = new Data::Nested;
$obj->set_structure("type","hash","/");
$obj->set_structure("uniform",0,"/");

$obj->set_structure("type","hash","/hu");
$obj->set_structure("uniform",1,"/hu");

$obj->set_structure("type","hash","/hu/*");
$obj->set_structure("uniform",0,"/hu/*");

$obj->set_structure("type","scalar","/hu/*/a");
$obj->set_structure("type","scalar","/hu/*/b");

$obj->set_structure("type","hash","/hn");
$obj->set_structure("uniform",0,"/hn");

$obj->set_structure("type","hash","/hn/a");
$obj->set_structure("uniform",1,"/hn/a");
$obj->set_structure("type","hash","/hn/b");
$obj->set_structure("uniform",0,"/hn/b");

$obj->set_structure("type","scalar","/hn/a/*");
$obj->set_structure("type","scalar","/hn/b/a");
$obj->set_structure("type","scalar","/hn/b/b");

$obj->set_structure("type","list","/lo1");
$obj->set_structure("ordered",1,"/lo1");
$obj->set_structure("uniform",1,"/lo1");

$obj->set_structure("type","scalar","/lo1/*");

$obj->set_structure("type","list","/lo2");
$obj->set_structure("ordered",1,"/lo2");
$obj->set_structure("uniform",0,"/lo2");

$obj->set_structure("type","scalar","/lo2/0");
$obj->set_structure("type","scalar","/lo2/1");

$obj->set_structure("type","list","/lu");
$obj->set_structure("ordered",0,"/lu");

$obj->set_structure("type","scalar","/lu/*");

$tests = "

foo
~
   ndsdat08
   _undef_

scalar
~
   _blank_
   /hn/a/*
   /hn/b/a
   /hn/b/b
   /hu/*/a
   /hu/*/b
   /lo1/*
   /lo2/0
   /lo2/1
   /lu/*

scalar
unordered
~
   ndsdat07
   _undef_

hash
ordered
~
   ndsdat07
   _undef_

hash
list
~
   ndsdat07
   _undef_

hash
uniform
~
   _blank_
   /hn/a
   /hu

hash
nonuniform
~
   _blank_
   /
   /hn
   /hn/b
   /hu/*

hash
~
   _blank_
   /
   /hn
   /hn/a
   /hn/b
   /hu
   /hu/*

list
~
   _blank_
   /lo1
   /lo2
   /lu

list
ordered
~
   _blank_
   /lo1
   /lo2

list
unordered
~
   _blank_
   /lu

list
uniform
~
   _blank_
   /lo1
   /lu

list
nonuniform
~
   _blank_
   /lo2

list
unordered
uniform
~
   _blank_
   /lu

list
ordered
nonuniform
~
   _blank_
   /lo2

list
ordered
uniform
~
   _blank_
   /lo1

";

print "paths...\n";
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

