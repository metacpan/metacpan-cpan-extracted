#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
use Array::Each;

# Testing attribute validations

my $obj = Array::Each->new();

eval { $obj->_set_each('') }; # should croak
ok( $@ =~ /^Invalid _each:/, "validate _each" );

eval { $obj->set_set('') }; # should croak
ok( $@ =~ /^Invalid set:/, "validate set" );

eval { $obj->set_iterator('') }; # should croak
ok( $@ =~ /^Invalid iterator:/, "validate iterator" );

eval { $obj->set_rewind('') }; # should croak
ok( $@ =~ /^Invalid rewind:/, "validate rewind" );

eval { $obj->set_bound('') }; # should croak
ok( $@ =~ /^Invalid bound:/, "validate bound" );

$obj->set_undef(''); # shouldn't croak
is( $obj->get_undef(), '', "validate undef" );

eval { $obj->set_stop('') }; # should croak
ok( $@ =~ /^Invalid stop:/, "validate stop" );

eval { $obj->set_group('') }; # should croak
ok( $@ =~ /^Invalid group:/, "validate group" );

eval { $obj->set_count('') }; # should croak
ok( $@ =~ /^Invalid count:/, "validate count" );

__END__
