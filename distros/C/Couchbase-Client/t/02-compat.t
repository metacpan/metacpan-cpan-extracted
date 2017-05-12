#!perl
use strict;
use warnings;
use Test::More;
use Couchbase::Client;
use Couchbase::Client::Errors;
use Couchbase::Client::Compat
    qw(return_for_multi_wrap return_for_op);
use Couchbase::Client::Return;
use Couchbase::Client::IDXConst;
use Data::Dumper;

# Here we craft responses:

sub new_response {
    my ($value,$err,$cas) = @_;
    my $ret = [ ];
    bless $ret, 'Couchbase::Client::Return';
    $ret->[RETIDX_ERRNUM] = $err;
    $ret->[RETIDX_CAS] = $cas;
    $ret->[RETIDX_VALUE] = $value;
    return $ret;
}

my $Ret;
my $CompatVal;


#Try with a successful GET command
$Ret = new_response("foo", 0, 42);
is(return_for_op($Ret, 'get'), 'foo', "Got expected return for OK get");

$Ret = new_response(undef, COUCHBASE_KEY_ENOENT, 0);
ok(!return_for_op($Ret, 'get'), "Got non-true value for error response (GET)");


#try with SET
$Ret = new_response(undef, 0, 42);
ok(return_for_op($Ret, 'set'), "Got OK for SET");

$Ret = new_response(undef, COUCHBASE_KEY_ENOENT);
$CompatVal = return_for_op($Ret, 'set');

ok(defined $CompatVal, "Set ENOENT is defined");
ok(!$CompatVal, "But it's false..");

$Ret = new_response(undef, COUCHBASE_ETMPFAIL);
ok(!defined return_for_op($Ret, 'set'), "TMPFAIL is undef");

#try with GETS
$Ret = new_response('foo', 0, 42);
$CompatVal = return_for_op($Ret, 'gets');

ok(ref $CompatVal eq 'ARRAY', "Got array for gets");
ok($CompatVal->[0] == 42 && $CompatVal->[1] eq 'foo',
   "Got expected [cas,value]");

#try with incr/decr
$Ret = new_response(0, 0, 0);
$CompatVal = return_for_op($Ret, 'decr');
ok(defined $CompatVal, "Value is defined for 0 arithmetic value");

$Ret = new_response(undef, COUCHBASE_KEY_ENOENT, 0);
ok(!defined return_for_op($Ret, 'incr'), "undefined for error result");

#Try with delete/remove/whatever:

$Ret = new_response(undef, 0);
ok(return_for_op($Ret, 'remove'), "OK for delete without error");
$Ret = new_response(undef, COUCHBASE_KEY_ENOENT);
is(return_for_op($Ret, 'remove'), 0, "Got false reply for DELETE with ENOENT");


#Try the multi interface:
my $RetMulti_base = {
    'foo' => new_response('foo_value', 0, 42),
    'bar' => new_response('bar_value', 0, 43),
    'baz' => new_response('baz_value', 0, 44)
};

my $RetMulti = { %$RetMulti_base };

my $ReqMulti = [qw(bar foo baz)];
$CompatVal = return_for_multi_wrap($ReqMulti, $RetMulti, 'get');

ok(ref $CompatVal eq 'HASH', "Got hash return");
ok(scalar keys %$CompatVal == 3, "Got expected key count");

ok(
    $CompatVal->{foo} eq 'foo_value' &&
    $CompatVal->{bar} eq 'bar_value' &&
    $CompatVal->{baz} eq 'baz_value',
    "Got all expected values");

$RetMulti = { %$RetMulti_base };

$CompatVal = [ (return_for_multi_wrap($ReqMulti, $RetMulti, 'get')) ];
ok(ref $CompatVal eq 'ARRAY', "Have array for list context");

my $ok = 1;
foreach my $i (0..$#{$ReqMulti}) {
    my $k = $ReqMulti->[$i];
    my $v = $CompatVal->[$i];
    if ($v ne "$k\_value") {
        $ok = 0;
        diag "Found unexpected $k => $v";
    }
}

ok($ok, "Found no errors for list context");

done_testing();