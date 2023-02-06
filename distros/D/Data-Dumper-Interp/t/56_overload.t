#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
#use open IO => ':locale';
use open ':std', ':encoding(UTF-8)';
STDOUT->autoflush();
STDERR->autoflush();
select STDERR;

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

use Test::More;
use Data::Dumper::Interp;
use Carp;

$Data::Dumper::Interp::Foldwidth = 0; # disable wrap

my $hvobj = main::HVObj->new();
my $hobj = main::HObj->new();
my $sobj = main::SObj->new();
my $cobj = main::CObj->new();
my $gobj = main::GObj->new();

is_deeply(\@$hvobj, [0..9], "\\\@Hvobj basic test");
is_deeply(\%$hvobj, {c => 333 , a => 111,b => 222}, "\\\%HVobj basic test");
is_deeply(\%$hobj, {a => 111,b => 222,c => 333}, "Hobj basic test");
is_deeply(\$$sobj, \"virtual value", "\$Sobj basic test");
is (&$cobj, q<from virtual coderef>, "Cobj basic test");
is (${ *{ $gobj }{SCALAR} }, "scalar via virtual glob", "Gobj basic test");
is_deeply (*{ $gobj }{SCALAR},\"scalar via virtual glob" , "*{Gobj}{SCALAR} basic test");
is_deeply (*{ $gobj }{ARRAY},[qw/array via virtual glob/] , "*{Gobj}{ARRAY} basic test");
is_deeply (*{ $gobj }{HASH},{hash_via_virtual_glob => 123}, "*{Gobj}{HASH} basic test");

$Data::Dumper::Interp::Overloads = 0;
is (vis \@$hvobj, '[0,1,2,3,4,5,6,7,8,9]', "\@{HVObj}");
is (vis \%$hvobj, '{a => 111,b => 222,c => 333}', "\%{HVObj}");
is (vis $hvobj, q!bless(do{\(my $o = [[0,1,2,3,4,5,6,7,8,9],{a => 111,b => 222,c => 333}])},'main::HVObj')!, "HVObj: Overloads disabled");
is (vis $hobj, q<bless(do{\(my $o = \42)},'main::HObj')>, "HObj: Overloads disabled");
is (vis \%$hobj, '{a => 111,b => 222,c => 333}', "\%{HObj}");
is (vis $sobj, q<bless({},'main::SObj')>, "SObj: Overloads disabled");
is (vis $$sobj, q<"virtual value">, "\$SObj: Overloads disabled");
is (vis $cobj, q!bless({},'main::CObj')!, "Cobj: Overloads disabled ");
is(vis $gobj,q!bless({},'main::GObj')! , "Gobj: Overloads disabled");
#is(vis *{ $gobj }{ARRAY},q!["array","via","virtual","glob"]! , "*{Gobj}{ARRAY} basic test");
#is(vis *{ $gobj }{HASH},q!{hash_via_virtual_glob => 123}!, "*{Gobj}{HASH} basic test");

$Data::Dumper::Interp::Overloads = 1;
is (vis \@$hvobj, '[0,1,2,3,4,5,6,7,8,9]', "\@{HVObj} again");
is (vis \%$hvobj, '{a => 111,b => 222,c => 333}', "\%{HVObj} again");
is (vis $hvobj, '[0,1,2,3,4,5,6,7,8,9]', "HVObj: Overloads enabled");
is (vis $hobj, '{a => 111,b => 222,c => 333}', "HObj: Overloads enabled");
is (hvis(%$hobj), '(a => 111,b => 222,c => 333)', "\%HObj: Overloads enabled");
is (vis $sobj, q<\\"virtual value">, "SObj: Overloads enabled");
is (vis $$sobj, q<"virtual value">, "\$SObj: Overloads enabled");
like(Data::Dumper::Interp->new()->Deparse(1)->vis($cobj), 
     qr/^sub\s*{.*['"]from virtual coderef['"]\s*;?\s*}$/,
     "Cobj: Overloads enabled");
is(vis $gobj, q!\*::GObj::Global! , "Gobj: Overloads enabled");

done_testing();
exit 0;

