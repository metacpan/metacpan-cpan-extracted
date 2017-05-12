#!perl -T

use Test::More tests => 49;

BEGIN {
	use_ok( 'Algorithm::SixDegrees' );
}

my $sd = new Algorithm::SixDegrees;
isa_ok($sd,'Algorithm::SixDegrees');

eval '$sd->forward_data_source()';
isnt($@,"",'forward_data_source dies with no args');
eval '$sd->forward_data_source(undef,\&one)';
like($@,qr/name/,'forward_data_source dies without a name');
eval '$sd->forward_data_source("t")';
like($@,qr/code/,'forward_data_source dies without a sub');
eval '$sd->forward_data_source("t","t")';
like($@,qr/coderef/,'forward_data_source dies without a coderef');
eval '$sd->forward_data_source("t",{t=>1})';
like($@,qr/coderef/,'forward_data_source dies without a coderef');

eval '$sd->reverse_data_source()';
isnt($@,"",'reverse_data_source dies with no args');
eval '$sd->reverse_data_source(undef,\&one)';
like($@,qr/name/,'reverse_data_source dies without a name');
eval '$sd->reverse_data_source("t")';
like($@,qr/code/,'reverse_data_source dies without a sub');
eval '$sd->reverse_data_source("t","t")';
like($@,qr/coderef/,'reverse_data_source dies without a coderef');
eval '$sd->reverse_data_source("t",{t=>1})';
like($@,qr/coderef/,'reverse_data_source dies without a coderef');

eval '$sd->data_source()';
isnt($@,"",'data_source dies with no args');
eval '$sd->data_source(undef,\&one)';
like($@,qr/name/,'data_source dies without a name');
eval '$sd->data_source("t")';
like($@,qr/code/,'data_source dies without a sub');
eval '$sd->data_source("t","t")';
like($@,qr/coderef/,'data_source dies without a coderef');
eval '$sd->data_source("t",{t=>1})';
like($@,qr/coderef/,'data_source dies without a coderef');

is(Algorithm::SixDegrees->make_link("Actor","Bob","Tom"),undef,'make_link without object fails');
like(Algorithm::SixDegrees->error,qr/object/,'make link errors if not called on object');
is(Algorithm::SixDegrees->make_link({},"Actor","Bob","Tom"),undef,'make_link with bad object fails');
like(Algorithm::SixDegrees->error,qr/object/,'make link errors if not called on object');
is($sd->make_link(undef,"Bob","Tom"),undef,'make_link w/o source');
like(Algorithm::SixDegrees->error,qr/name/,'make link errors if called without a source');
is($sd->make_link("Actor",undef,"Tom"),undef,'make_link w/o start');
like(Algorithm::SixDegrees->error,qr/identifier/,'make link errors if called without starting element');
is($sd->make_link("Bob","Tom"),undef,'make_link w/o end');
like(Algorithm::SixDegrees->error,qr/identifier/,'make link errors if called with only two identifiers');
is($sd->make_link("Actor","Bob","Tom"),undef,'make_link without any source');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if called without any source');

$sd->data_source("t",\&one);
is($sd->make_link("Actor","Bob","Tom"),undef,'make_link without valid source');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if called without valid source');

$sd->data_source("u",\&one);
$sd->data_source("v",\&one);
is($sd->make_link("t","Bob","Tom"),undef,'make_link with three sources');
like(Algorithm::SixDegrees->error,qr/sources/,'make link errors if called with too many sources');

# Object corruption
my $bad_sd = Algorithm::SixDegrees->new();
delete $bad_sd->{'_sources'};
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/missing _sources');
like(Algorithm::SixDegrees->error,qr/sources/,'make link errors if sources in object missing');
$bad_sd->{'_sources'}{'Actor'} = '';
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/corrupt _sources');
like(Algorithm::SixDegrees->error,qr/sources/,'make link errors if sources in object corrupt');

$bad_sd = new Algorithm::SixDegrees;
$bad_sd->data_source("Actor",\&one);
my $temp = $bad_sd->{'_source_left'};
$bad_sd->{'_source_left'} = '';
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/missing _source_left');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if sources in object corrupt');
$bad_sd->{'_source_left'} = $temp;
$bad_sd->{'_source_right'} = '';
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/missing _source_right');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if sources in object corrupt');
$temp = $bad_sd->{'_source_left'}{'Actor'};
$bad_sd->{'_source_left'}{'Actor'} = '';
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/missing _source_left/Actor');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if sources in object corrupt');
$bad_sd->{'_source_left'}{'Actor'} = $temp;
$bad_sd->{'_source_right'} = {'Actor' => ''};
is($bad_sd->make_link("Actor","Bob","Tom"),undef,'make_link w/missing _source_right/Actor');
like(Algorithm::SixDegrees->error,qr/Source/,'make link errors if sources in object corrupt');

$bad_sd = new Algorithm::SixDegrees;
$bad_sd->data_source("Actor",\&two);
is_deeply([$bad_sd->make_link("Actor","Bob","Tom")],[],'make_link w/error in sub');
is(Algorithm::SixDegrees->error,'testing error','make link puts the error in the object');

$bad_sd = new Algorithm::SixDegrees;
$bad_sd->forward_data_source("Actor",\&one);
$bad_sd->reverse_data_source("Actor",\&two);
is_deeply([$bad_sd->make_link("Actor","Bob","Tom")],[],'make_link w/error in right sub');
is(Algorithm::SixDegrees->error,'testing error','make link puts the error in the object');

exit;

sub one { return ("Mark","John","Seth"); };
sub two { $Algorithm::SixDegrees::ERROR = 'testing error'; return };
