use strict ;
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 27 ;
use Data::Dumper ;

use Array::IntSpan::Fields ;

my $trace = shift || 0 ;

my @expect= (['0.0.1','0.1.0','ab'],
             ['1.0.0','1.0.3','cd'],
             ['1.0.4','1.1.0','ef']) ;
my $r = Array::IntSpan::Fields->new('1.2.4',@expect) ;

ok ( defined($r) , 'Array::IntSpan::Fields new() works') ;

is_deeply([$r->get_element(1)], ['1.0.0','1.0.3','cd'], 'get_element' );

foreach my $t (qw/0.0.10 0.3.0 1.0.0 1.2.3 0.1.0/)
  {
    my $int = $r-> field_to_int($t);
    ok ($int, "field_to_int test $t -> $int") ;
    is($r-> int_to_field($int), $t,
       "int_to_field test $int -> $t") ;
  }

eval{$r-> field_to_int('2.0.0')} ;
like($@, qr/Field value 2 too great/, 'test field check') ;

eval{$r-> field_to_int('1.0.17')} ;
like($@, qr/Field value 17 too great/, 'test field check') ;


$r->set_range('1.1.1','1.2.1','gh') ;
is($r->lookup('1.2.0'),'gh',"lookup test") ;

my $res = $r->get_range('1.0.0','1.3.15') ;

isa_ok($res,'Array::IntSpan::Fields') ;
is($res->lookup('1.0.0'),'cd','get range test 1') ;
is($res->lookup('1.0.5'),'ef','get range test 2') ;

$r->set_range('1.1.5','1.2.5','sub',sub{"@_"});
is($r->lookup('1.2.4'),'sub','set_range with sub') ;
is($r->lookup('1.1.4'),'1.1.1 1.1.4 gh','set_range with sub') ;


my $regular  = Array::IntSpan::Fields->new([1,3,'ab'],[5, 7, 'cd']);
isa_ok($regular,'Array::IntSpan') ;

my $int32  = Array::IntSpan::Fields->new('32',[1,3,'ab'],[5, 7, 'cd']);
isa_ok($int32,'Array::IntSpan::Fields') ;

foreach my $t (qw/1 100/)
  {
    my $int = $int32-> field_to_int($t);
    ok ($int, "field_to_int int 32 test $t -> $int") ;
    is($int32-> int_to_field($int), $t,
       "int_to_field int 32 test $int -> $t") ;
  }

eval{my $int2  = Array::IntSpan::Fields->new('2',[1,3,'ab'],[5, 7, 'cd']);};
like($@, qr/Field value 5 too great. Max is 3/, 
     'test field check') ;


