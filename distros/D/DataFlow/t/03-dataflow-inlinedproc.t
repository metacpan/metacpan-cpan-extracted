
use Test::More tests => 2;

package DataFlow::Proc::UCFirst;

use Moose;
extends 'DataFlow::Proc';

sub _build_p {
    return sub { ucfirst };
}

package Some::Other::Package::Rev;

use Moose;
extends 'DataFlow::Proc';

sub _build_p {
    return sub { scalar reverse };
}

package main;

use DataFlow;

my $flow = DataFlow->new( [ 'UCFirst', 'Some::Other::Package::Rev', ] );
ok($flow);

$flow->input(qw/abc def ghi/);

is( $flow->output, 'cbA' );
