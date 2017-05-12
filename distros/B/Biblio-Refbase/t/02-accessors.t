#!perl -T

use strict;
use warnings;

use Test::More;

use Biblio::Refbase;
use LWP::UserAgent;

my @accessors = qw'url user password relogin order rows records';

plan tests => @accessors * 6 + 22;

my $refbase = Biblio::Refbase->new;
my ($set, $obj, $gotten);



#
#  url user password relogin order rows records
#

$set = 'foo';

for (@accessors) {
  can_ok $refbase, $_;

  $obj = $refbase->$_($set);
  ok     defined $obj, "$_ (setter) returned something";
  is     $obj, $refbase, "$_ can be chained";

  $gotten = $refbase->$_;
  ok     defined $gotten, "$_ (getter) returned something";
  is     $gotten, $set, "$_ returned initial value";

  ok     !defined $refbase->$_(undef)->$_, "$_ can undef";
}



#
#  format
#

can_ok $refbase, 'format';
eval { $refbase->format('foo') };
like   $@, qr/^Format .* not available./, 'format (setter) failed as expected due to invalid parameter';

$set = 'mods';
$obj = $refbase->format($set);
ok     defined $obj, 'format (setter) returned something';
is     $obj, $refbase, 'format can be chained';

$gotten = $refbase->format;
ok     defined $gotten, 'format (getter) returned something';
is     $gotten, $set, 'format returned initial object';

ok     !defined $refbase->format(undef)->format, 'format can undef';



#
#  style
#

can_ok $refbase, 'style';
eval { $refbase->style('foo') };
like   $@, qr/^Citation style .* not available./, 'style (setter) failed as expected due to invalid parameter';

$set = 'deepseares';
$obj = $refbase->style($set);
ok     defined $obj, 'style (setter) returned something';
is     $obj, $refbase, 'style can be chained';

$gotten = $refbase->style;
ok     defined $gotten, 'style (getter) returned something';
is     $gotten, $set, 'style returned initial object';

ok     !defined $refbase->style(undef)->style, 'style can undef';



#
#  ua
#

can_ok $refbase, 'ua';

# check if constructor has auto-generated the ua object
isa_ok $refbase->ua, 'LWP::UserAgent';

eval { $refbase->ua('foo') };
like   $@, qr/requires an object based on/, 'ua (setter) failed as expected due to invalid parameter';
eval { $refbase->ua(undef) };
ok     $@, q{ua can't undef};

$set = LWP::UserAgent->new;
$obj = $refbase->ua($set);
ok     defined $obj, 'ua (setter) returned something';
is     $obj, $refbase, 'ua can be chained';

$gotten = $refbase->ua;
ok     defined $gotten, 'ua (getter) returned something';
is     $gotten, $set, 'ua returned initial object';
