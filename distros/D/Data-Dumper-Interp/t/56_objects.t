#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug/; # Test2::V0 etc.

use Data::Dumper::Interp;

package main::StrObj;
sub new { bless [42], shift }
use overload '""'  => sub { "stringified value" };

# Verify evaluation of overloaded deref operators.

package main::HVObj;
sub new { bless \[ [0..9], {a => 111, b => 222, c => 333} ], shift }
use overload  '@{}' => sub { ${ shift() }->[0] },
              '%{}' => sub { ${ shift() }->[1] },
              "fallback" => 1,
              ;

package main::HObj;

# With Perl 5.18.4 "bless \\42" throws "Modification of read-only value"
#sub new { bless \\42, shift }
sub new { bless \(my $o = \42), shift } # emulate later Perls

use overload  '%{}' => sub { \%{ main::HVObj->new() } },
              "fallback" => 1,
              ;

package main::SObj;
sub new { bless {}, shift }
use overload  '${}' => sub { state $v = "virtual value"; \$v },
              "fallback" => 1,
              ;

package main::CObj;
sub new { bless {}, shift }
use overload  '&{}' => sub { sub{"from virtual coderef"} },
              "fallback" => 1,
              ;

package main::GObj;
our $Global = "scalar via virtual glob";
our %Global = (hash_via_virtual_glob => 123);
our @Global = ("array","via","virtual","glob");
sub new { bless {}, shift }
use overload  '*{}' => sub { \*{Global} },
              "fallback" => 1,
              ;


######################### MAIN IS HERE #####################3

package main;

$Data::Dumper::Interp::Foldwidth = 0; # disable wrap

my $strobj = main::StrObj->new();
my $hvobj = main::HVObj->new();
my $hobj = main::HObj->new();
my $sobj = main::SObj->new();
my $cobj = main::CObj->new();
my $gobj = main::GObj->new();

is($strobj, "stringified value", "StrObj basic test");
is(\@$hvobj, [0..9], "\\\@Hvobj basic test");
is(\%$hvobj, {c => 333 , a => 111,b => 222}, "\\\%HVobj basic test");
is(\%$hobj, {a => 111,b => 222,c => 333}, "Hobj basic test");
is(\$$sobj, \"virtual value", "\$Sobj basic test");
is (&$cobj, q<from virtual coderef>, "Cobj basic test");
is (${ *{ $gobj }{SCALAR} }, "scalar via virtual glob", "Gobj basic test");
is (*{ $gobj }{SCALAR},\"scalar via virtual glob" , "*{Gobj}{SCALAR} basic test");
is (*{ $gobj }{ARRAY},[qw/array via virtual glob/] , "*{Gobj}{ARRAY} basic test");
is (*{ $gobj }{HASH},{hash_via_virtual_glob => 123}, "*{Gobj}{HASH} basic test");

$Data::Dumper::Interp::Objects = 0;
is (vis \@$hvobj, '[0,1,2,3,4,5,6,7,8,9]', "\@{HVObj}");
is (vis \%$hvobj, '{a => 111,b => 222,c => 333}', "\%{HVObj}");
is (vis $hvobj, q!bless(do{\(my $o = [[0,1,2,3,4,5,6,7,8,9],{a => 111,b => 222,c => 333}])},'main::HVObj')!, "HVObj: Objects handling disabled");
is (vis $strobj, q!bless([42],'main::StrObj')!, "strobj: Objects handling disabled");

is (vis $hobj, q<bless(do{\(my $o = \42)},'main::HObj')>, "HObj: Objects handling disabled");
is (vis \%$hobj, '{a => 111,b => 222,c => 333}', "\%{HObj}");
is (vis $sobj, q<bless({},'main::SObj')>, "SObj: Objects handling disabled");
is (vis $$sobj, q<"virtual value">, "\$SObj: Objects handling disabled");
is (vis $cobj, q!bless({},'main::CObj')!, "Cobj: Objects handling disabled ");
is(vis $gobj,q!bless({},'main::GObj')! , "Gobj: Objects handling disabled");
#is(vis *{ $gobj }{ARRAY},q!["array","via","virtual","glob"]! , "*{Gobj}{ARRAY} basic test");
#is(vis *{ $gobj }{HASH},q!{hash_via_virtual_glob => 123}!, "*{Gobj}{HASH} basic test");

foreach (0,1) {
  local $Data::Dumper::Interp::Objects;
  my ($desc, $STcn, $HVcn, $Hcn, $Ccn, $Scn, $Gcn);
  if ($_ == 0) {
    $Data::Dumper::Interp::Objects
      #= {show_classname => 0, objects => 1};
      = {overloads => "transparent", objects => 1};
    $STcn = $HVcn = $Hcn = $Ccn = $Scn = $Gcn = "";
    $desc = "Objects enabled but not showing overloaded classnames";
  }
  elsif ($_ == 1) {
    $Data::Dumper::Interp::Objects = 1;
    $STcn = '(main::StrObj)';
    $HVcn = '(main::HVObj)';
    $Hcn  = '(main::HObj)';
    $Ccn  = '(main::CObj)';
    $Scn  = '(main::SObj)';
    $Gcn  = '(main::GObj)';
    $desc = "Objects enabled";
  }
  else { oops }
  is (vis $strobj, "\"${STcn}stringified value\"", "StrObj: $desc");
  is (vis \@$hvobj, '[0,1,2,3,4,5,6,7,8,9]', "\@{HVObj} again");
  is (vis \%$hvobj, '{a => 111,b => 222,c => 333}', "\%{HVObj} again");
  is (vis $hvobj, $HVcn.'[0,1,2,3,4,5,6,7,8,9]', "HVObj: $desc");
  is (vis $hobj, $Hcn.'{a => 111,b => 222,c => 333}', "HObj: $desc");
  is (hvis(%$hobj), '(a => 111,b => 222,c => 333)', "\%HObj: $desc");
  is (vis $sobj, $Scn.q<\\"virtual value">, "SObj: $desc");
  is (vis $$sobj, q<"virtual value">, "\$SObj: $desc");
  like(Data::Dumper::Interp->new()->Deparse(1)->vis($cobj),
       qr/^\Q${Ccn}\Esub\s*{.*['"]from virtual coderef['"]\s*;?\s*}$/,
       "Cobj: $desc");
  is(vis $gobj, $Gcn.q!\*::GObj::Global! , "Gobj: $desc");
}

{
  local $Data::Dumper::Interp::Objects = {overloads => "ignore", objects => 1};
  my $desc = "(overloads => \"ignore\")";
  like (vis $strobj, qr/^main::StrObj<[\da-f:]*>$/, "StrObj: $desc");
  like (vis $hvobj, qr/^main::HVObj<[\da-f:]*>$/, "HVObj: $desc");
  like (vis $hobj, qr/^main::HObj<[\da-f:]*>$/, "HObj: $desc");
  like (vis $sobj, qr/^main::SObj<[\da-f:]*>$/, "SObj: $desc");
  like(Data::Dumper::Interp->new()->Deparse(1)->vis($cobj),
       qr/^main::CObj<[\da-f:]*>$/,
       "Cobj: $desc");
  like(vis $gobj, qr/^main::GObj<[\da-f:]*>$/ , "Gobj: $desc");
}

done_testing();
exit 0;

