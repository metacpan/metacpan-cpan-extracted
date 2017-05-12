#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 70;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    note "************* DBIx::DR *************";
    use_ok 'DBIx::DR::Iterator';
}

my $aref = [ { id => 1 }, { id => 2 }, { id => 3 } ];
my $href = {
    a => {id => 'a', value => 1 },
    b => {id => 'b', value => 2 },
    c => {id => 'c', value => 3 },
    d => {id => 'd', value => 4 },
    e => {id => 'e', value => 3 },
};

my $item;
my $hiter = new DBIx::DR::Iterator $href;
my $aiter = new DBIx::DR::Iterator $aref;

isa_ok $hiter => 'DBIx::DR::Iterator', 'HASH iterator has been created';
ok $hiter->{is_hash} && !$hiter->{is_array}, 'HASH detected properly';
ok $hiter->count == keys %$href, 'HASH size detected properly';

isa_ok $aiter => 'DBIx::DR::Iterator', 'ARRAY iterator has been created';
ok $aiter->{is_array} && !$aiter->{is_hash}, 'ARRAY detected properly';
ok $aiter->count == @$aref, 'ARRAY size detected properly';

my $no = 0;
while(my $i = $aiter->next) {

    if ($no >= $aiter->count) {
        fail 'Array bound exceeded';
        last;
    }

    is $i->id, $aref->[ $no++ ]{id}, "$no element of array was checked";
}

$no = 0;
while(my $i = $hiter->next) {
    if ($no++ >= $hiter->count) {
        fail 'Hash bound exceeded';
        last;
    }
    is $i->value, $href->{ $i->id }{value},
        "$no element of hash was checked";
}

ok $aiter->next, 'array element was autoreseted';
$no = 1;
$no++ while $aiter->next;
ok $no == $aiter->count, 'array was autoreseted properly';

ok $hiter->next, 'hash element was autoreseted';
$no = 1;
$no++ while $hiter->next;
ok $no == $hiter->count, 'hash was autoreseted properly';

$aiter->next;
$hiter->next;
$aiter->reset;
$hiter->reset;

$no = 0;
$no++ while $aiter->next;
ok $no == $aiter->count, 'array was reseted properly';

$no = 0;
$no++ while $hiter->next;
ok $no == $hiter->count, 'hash was reseted properly';

$item = $hiter->next;

# note explain $hiter;

for my $ss ($hiter->grep(value => 3), $hiter->grep(sub{ $_[0]->value == 3 })) {
    isa_ok $ss => 'DBIx::DR::Iterator', 'Hash subset';
    cmp_ok $ss->count, '==', 2, 'count of elements';
    ok $ss->exists('c'), 'element was grepped properly';
    ok $ss->exists('e'), 'element was grepped properly';
    cmp_ok $ss->get('c')->id, 'eq', 'c', 'id';
    cmp_ok $ss->get('c')->value, 'eq', '3', 'value';
    cmp_ok $ss->get('e')->id, 'eq', 'e', 'id';
    cmp_ok $ss->get('e')->value, 'eq', '3', 'value';
    cmp_ok $ss->{item_class}, 'eq', $aiter->{item_class}, 'Item class';
    cmp_ok $ss->{item_constructor}, 'eq', $aiter->{item_constructor},
        'Item constructor';
}

{

    my ($ss1) = $hiter->grep(value => 3)->all;
    my $ss2 = $hiter->find(value => 3);
    is $ss1->value, $ss2->value, 'find';
}

for my $ss($aiter->grep(id => 2), $aiter->grep(sub { $_[0]->id == 2 })) {
    isa_ok $ss => 'DBIx::DR::Iterator', 'Array subset';
    cmp_ok $ss->count, '==', 1, 'count of elements';
    ok $ss->exists(0), 'element was grepped properly';
    cmp_ok $ss->get(0)->id, '==', 2, 'id';
    cmp_ok $ss->{item_class}, 'eq', $aiter->{item_class}, 'Item class';
    cmp_ok $ss->{item_constructor}, 'eq', $aiter->{item_constructor},
        'Item constructor';
}


ok $item, 'Item extracted';
ok $item->iterator, 'Item has iterator link';
undef $hiter;
ok !$item->iterator,
    'Item has undefined iterator link after iterator was destroyed';

$item = $aiter->next;
ok !$item->is_changed, "Item wasn't changed";
ok !$item->iterator->is_changed, "Iterator wasn't changed";
ok !eval { $item->value; 1 }, 'Unknown method';
ok $item->id(123) == 123, 'Change field';
ok $item->is_changed, 'Field was changed';
ok $item->iterator->is_changed, 'Iterator was changed, too';

my $o = { 1 => 2 };
$item->id($o);
$item->iterator->is_changed(0);
$item->is_changed(0);

# the same object
$item->id($o);
ok !$item->is_changed, "Item wasn't changed";
ok !$item->iterator->is_changed, "Iterator wasn't changed";

$item->id([]);
ok $item->is_changed, 'Field was changed';
ok $item->iterator->is_changed, 'Iterator was changed, too';


{
    {
        package TestItem;
        sub new {
            my ($class, $item) = @_;
            return bless { %$item } => $class;
        }

        package TestItemD;
        sub new {
            my ($class, $item) = @_;
            return undef if @_ > 2;
            goto \&TestItem::new;
        }
    }

    my @items = (
        { a => 'b' },
        { c => 'd' },
        { d => 'e' }
    );

    my $l1 = DBIx::DR::Iterator->new(\@items, -item => 'test_item#new');
    my $l2 = DBIx::DR::Iterator->new(\@items, -item => 'test_item_d#new');
    my $l3 = DBIx::DR::Iterator->new(\@items, -item =>
        'test_item_d#new', -noitem_iter => 1);

    is_deeply [ $l2->all ], [ (undef) x 3 ], 'list2 contains only undef';
    is_deeply [ $l1->all ], [ $l3->all ],
        'Third list did not received iterator';
}

subtest 'iterator push, pop', sub {
    plan tests => 6;
    {
        package TestPushItem;
        sub new {
            my ($class, $item) = @_;
            return bless { %$item } => $class;
        }
    }
    my @items = (
        { a => 'b' },
        { c => 'd' },
        { d => 'e' }
    );

    my $list = DBIx::DR::Iterator->new(
        [@items],
        -item           => 'test_push_item#new',
        -noitem_iter    => 1,
    );

    is_deeply $list->push({ f => 'h' }), TestPushItem->new({ f => 'h' }), 'iterator push';
    is_deeply $list->get(-1), TestPushItem->new({ f => 'h' }), 'added element';
    is $list->count, 4, 'count';

    
    is_deeply $list->pop, TestPushItem->new({ f => 'h' }), 'iterator pop';
    is_deeply $list->get(-1), TestPushItem->new({ d => 'e' }), 'last element';
    is $list->count, 3, 'count';
};

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut
