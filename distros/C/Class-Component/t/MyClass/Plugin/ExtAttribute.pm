package MyClass::Plugin::ExtAttribute;

use strict;
use warnings;
use base 'Class::Component::Plugin';


sub args_0 :Method Dump {}
sub args_1 :Method Dump('hoge') {}
sub args_1_2 :Method Dump("hoge") {}
sub args_2 :Method Dump('hoge1', 'hoge2') {}
sub args_2_2 :Method Dump('hoge1', "hoge2") {}
sub args_2_3 :Method Dump("hoge1", 'hoge2') {}
sub args_2_4 :Method Dump("hoge1", "hoge2") {}
sub args_2_5 :Method Dump(qw(hoge1 hoge2)) {}
sub args_2_6 :Method Dump(qw/hoge1 hoge2/) {}

sub ref_array_1 :Method Dump([1,2,3,4]) {}
sub ref_array_2 :Method Dump([qw/1 2 3 4/]) {}
sub ref_array_3 :Method Dump([qw(1 2 3 4)]) {}
sub ref_array_4 :Method Dump(["1",'2','3',"4"]) {}
sub ref_array_5 :Method Dump(['1', '2', '3', '4']) {}
sub ref_array_6 :Method Dump(["1", "2", "3", "4"]) {}

sub hash_1 :Method Dump(key=>'value') {}

sub ref_hash_1 :Method Dump({ key => 'value' }) {}
sub ref_hash_2 :Method Dump({ key => { key => 'value' } }) {}

sub ref_hash_array :Method Dump({ key => [qw/ foo bar baz /] }) {}

sub ref_array_hash_1 :Method Dump([ 'foo', { key => 'value' }, 'baz' ]);
sub ref_array_hash_2 :Method Dump('foo', { key => 'value' }, 'baz');

sub ref_code_1 :Method Dump(sub { return 'code' }->()) {}
sub ref_code_2 :Method Dump(sub { _code }->()) {}
sub ref_code_3 :Method Dump(sub { _code2 4, 5 }->()) {}

sub run_code_1 :Method DumpRun(sub { return 'code' }) {}
sub run_code_2 :Method DumpRun(sub { _code }) {}
sub run_code_3 :Method DumpRun(sub { _code2 4, 5 }) {}

sub _code {
    '_code';
}

sub _code2 {
    $_[0] * $_[1]
}

1;
