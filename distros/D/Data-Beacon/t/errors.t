#!perl -Tw

use strict;
use warnings;

use Test::More qw(no_plan);
use_ok('Data::Beacon');

my $b = beacon();
isa_ok($b,'Data::Beacon');
is( $b->errors, 0 );

eval { $b = beacon( errors => 'xxx' ); };
ok( $@, 'invalid handler' );

my ($warn, $die, $sub);
$SIG{__WARN__} = sub { $warn = $_[0]; };
$SIG{__DIE__} = sub { $die = $_[0]; };

foreach my $noerrors (('', undef, 0)) {
    $b = beacon( errors => $noerrors );
    $b->appendlink('|');
    is( $b->errors, 1, 'no errors' );
    is( $warn, undef );
    is( $die, undef );
}

$b = beacon( errors => 'WaRn' );
$b->appendlink('|');
is( $b->errors, 1, 'warn' );
ok( $warn =~ /link fields must not contain '\|' at .*errors.t/ );

eval {
  $b = beacon( errors => 'die' );
  $b->appendlink('|');
};
ok( $@ =~ /link fields must not contain '\|' at .*errors.t/, 'die' );

# TODO: test code as handler

