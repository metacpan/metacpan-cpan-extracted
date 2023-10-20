#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug/; # Test2::V0 etc.

use Data::Dumper::Interp;

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

my $hvobj = main::HVObj->new();
my $hobj = main::HObj->new();
my $sobj = main::SObj->new();
my $cobj = main::CObj->new();
my $gobj = main::GObj->new();

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

is (vis $hobj, q<bless(do{\(my $o = \42)},'main::HObj')>, "HObj: Objects handling disabled");
is (vis \%$hobj, '{a => 111,b => 222,c => 333}', "\%{HObj}");
is (vis $sobj, q<bless({},'main::SObj')>, "SObj: Objects handling disabled");
is (vis $$sobj, q<"virtual value">, "\$SObj: Objects handling disabled");
is (vis $cobj, q!bless({},'main::CObj')!, "Cobj: Objects handling disabled ");
is(vis $gobj,q!bless({},'main::GObj')! , "Gobj: Objects handling disabled");
#is(vis *{ $gobj }{ARRAY},q!["array","via","virtual","glob"]! , "*{Gobj}{ARRAY} basic test");
#is(vis *{ $gobj }{HASH},q!{hash_via_virtual_glob => 123}!, "*{Gobj}{HASH} basic test");

$Data::Dumper::Interp::Objects = 1;
is (vis \@$hvobj, '[0,1,2,3,4,5,6,7,8,9]', "\@{HVObj} again");
is (vis \%$hvobj, '{a => 111,b => 222,c => 333}', "\%{HVObj} again");
is (vis $hvobj, '(main::HVObj)[0,1,2,3,4,5,6,7,8,9]', "HVObj: Objects handling enabled");
is (vis $hobj, '(main::HObj){a => 111,b => 222,c => 333}', "HObj: Objects handling enabled");
is (hvis(%$hobj), '(a => 111,b => 222,c => 333)', "\%HObj: Objects handling enabled");
is (vis $sobj, q<(main::SObj)\\"virtual value">, "SObj: Objects handling enabled");
is (vis $$sobj, q<"virtual value">, "\$SObj: Objects handling enabled");
like(Data::Dumper::Interp->new()->Deparse(1)->vis($cobj),
     qr/^\(main::CObj\)sub\s*{.*['"]from virtual coderef['"]\s*;?\s*}$/,
     "Cobj: Objects handling enabled");
is(vis $gobj, q!(main::GObj)\*::GObj::Global! , "Gobj: Objects handling enabled");

done_testing();
exit 0;

