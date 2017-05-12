#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Moo::Role qw/apply_roles_to_object/;

require_ok 'Data::BitStream';

can_ok('Data::BitStream' => 'new');
my $stream = new_ok('Data::BitStream');

my @methods = qw(read write put_unary get_unary put_gamma get_gamma);
can_ok($stream, @methods);

ok(!$stream->can('has'));

require_ok 'Data::BitStream::Code::Escape';

# This works if you have Moose:
#Data::BitStream::Code::Escape->meta->apply($stream);
# This works with little old Moo::Role:
#Moo::Role->apply_roles_to_object($stream, qw/Data::BitStream::Code::Escape/);
Moo::Role->apply_roles_to_package('Data::BitStream', qw/Data::BitStream::Code::Escape/);

can_ok($stream, 'get_escape', 'put_escape');

done_testing;
