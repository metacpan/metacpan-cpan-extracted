#?/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t = Data::Transfigure->bare();
$t->add_transfigurators(qw(Data::Transfigure::HashFilter::Undef));

my $h = {a => 1, b => 2, c => 3};

is($t->transfigure($h), {a => 1, b => 2, c => 3}, 'no change');

$h = {"a?" => 1};

is($t->transfigure($h), {a => 1}, 'remove bang from defined');

$h = {a => undef};

is($t->transfigure($h), {a => undef}, 'no change with non-match undef');

$h = {"a?" => undef};

is($t->transfigure($h), {}, 'remove key/value');

$h = {a => 1, b => [{c => 3, "d?" => 4}], e => {f => [{"g?" => undef, h => "i"}]}};

is($t->transfigure($h), {a => 1, b => [{c => 3, d => 4}], e => {f => [{h => "i"}]}}, 'check recursive');

$t = Data::Transfigure->bare();
$t->add_transfigurators(Data::Transfigure::HashFilter::Undef->new(key_pattern => qr/(.*)[*]$/));

$h = {a => 1, b => [{c => 3, "d?" => 4}], e => {f => [{"g*" => undef, h => "i"}]}};

is($t->transfigure($h), {a => 1, b => [{c => 3, 'd?' => 4}], e => {f => [{h => "i"}]}}, 'check recursive with custom pattern');

$t = Data::Transfigure->bare();
$t->add_transfigurators(Data::Transfigure::HashFilter::Undef->new(key_pattern => qr/.*[*]$/));

$h = {a => 1, b => [{c => 3, "d*" => 4}], e => {f => [{"g*" => undef, h => "i"}]}};

is(
  $t->transfigure($h),
  {a => 1, b => [{c => 3, 'd*' => 4}], e => {f => [{h => "i"}]}},
  'check recursive with custom pattern without key remapping'
);

done_testing;
