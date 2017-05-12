#!perl -w

use strict;

use Test::More tests => 7;
#use Test::More qw/no_plan/;

my $Output;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $Output = 'Data::XML::Variant::Output';
    use_ok($Output) or die;
}

can_ok $Output, 'new';
ok my $output = $Output->new('foo'), '... and calling it should succeed';
isa_ok $output, $Output;

can_ok $output, 'output';
is $output->output, 'foo',
  '... and it should return the string we passed to the constructor';
is "$output", 'foo',
  '... and it should stringify to the string we passed to the constructor';
