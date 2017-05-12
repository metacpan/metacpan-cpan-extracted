#!/usr/local/bin/perl
use Test::More qw[no_plan];
use strict;
use warnings;

use base qw[Class::DBI];
use_ok 'Class::DBI::UUID';

__PACKAGE__->uuid_columns('id', 'test2');
__PACKAGE__->columns(All => qw[id foo test2]);

sub create {
    my ($class, $args) = @_;
    my $self = bless $args, $class;
    $self->call_trigger('before_create');
    return $self;
}

use Data::Dumper;
my $obj = __PACKAGE__->create({foo => "bar"});

isnt $obj->id, undef;
isnt $obj->test2, undef;
is $obj->foo, "bar";

isnt $obj->id, $obj->test2;
is $obj->uuid_columns_type, 'str';

is $obj->uuid_columns_type('hex'), 'hex';
__PACKAGE__->uuid_columns('id', 'test2');
my $obj2 = __PACKAGE__->create({foo => "bar"});

isnt $obj2->id, undef;
isnt $obj2->test2, undef;
is $obj2->foo, "bar";

isnt $obj2->id, $obj2->test2;
like $obj2->id, qr/^0x[0-9A-F]+$/;
