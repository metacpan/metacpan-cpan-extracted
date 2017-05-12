#!/opt/csw/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Most tests => 18;

use Data::FetchPath 'path';

sub srt ($) { 
    no warnings 'uninitialized';
    @$_[0] = sort @$_[0]; 
    shift;
};

my $data = [ 'foo', 'bar', 3, undef, 3 ];
ok my $paths = path( $data, 3 ),
  'Fetching paths for matching data should succeed';
is_deeply srt $paths, srt [ '[2]', '[4]' ],
  '... and it should return the correct paths for a simple array';

$data->[4] = [ 0, 3 ];
ok $paths = path( $data, 3 ), 'Fetching paths for matching data should succeed';
is_deeply srt $paths, srt [ '[2]', '[4][1]' ], '... or for a complex array';

$data = [ 3, 7, 9, [ 3, 1, 3, [ 3, 5, 2 ] ] ];
ok $paths = path( $data, 3 ), 'Fetching paths for matching data should succeed';
is_deeply srt $paths, srt [ '[0]', '[3][0]', '[3][2]', '[3][3][0]' ],
  '... or for a complex array';

$data = { foo => 'bar' };
ok $paths = path( $data, 'bar' ),
  'Fetching paths for matching data should succeed';
is_deeply srt $paths, srt ['{foo}'], '... we should be able to match simple keys';

$data = {
    foo => 3,
    bar => [qw/ this that 3 /],
    3   => undef,
    baz => {
        trois  => 3,
        quatre => [qw/ 1 2 3 4 /],
        cinq   => 'theoretical',
    }
};
ok $paths = path( $data, 3 ), 'Fetching paths for matching data should succeed';
my @expected = sort qw(
  {bar}[2]
  {baz}{trois}
  {baz}{quatre}[2]
  {foo}
);

$paths = [ sort @$paths ];
is_deeply srt $paths, srt \@expected,
  '... and we should be able to match complex data structures';

foreach my $path (@$paths) {
    is eval "\$data->$path", 3,
      '... and each element should have the correct value';
}

ok $paths = path( $data, qr/th/ ), 'Searching with regexes should succeed';
@expected = qw(
  {bar}[0]
  {bar}[1]
  {baz}{cinq}
);
eq_or_diff srt $paths, srt \@expected, '... and should return the correct paths';

$data = [ 1, 3 ];
$data->[2] = $data;
ok $paths = path( $data, 3 ),
  'Fetching paths for circular structures should succeed';
is_deeply $paths, ['[1]'], '... and only return the top level path';
