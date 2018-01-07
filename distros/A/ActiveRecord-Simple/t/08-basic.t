#!/usr/bin/perl

use strict;
use warnings;
no warnings 'redefine';
use 5.010;
use Data::Dumper;

use FindBin '$Bin';
use lib "$Bin/../lib";

package t::class;

use base 'ActiveRecord::Simple';

__PACKAGE__->table_name('t');
__PACKAGE__->columns('foo', 'bar');
__PACKAGE__->primary_key('foo');

#__PACKAGE__->belongs_to(class2 => 't::class2');

1;

package t::class2;

use base 'ActiveRecord::Simple';

__PACKAGE__->table_name('t');
__PACKAGE__->columns('foo', 'bar');
__PACKAGE__->primary_key('foo');

#__PACKAGE__->belongs_to(class => 't::class');


1;

package t::ClaSs3;

use base 'ActiveRecord::Simple';


package MockDBI;

sub selectrow_array { 1 }
sub do { 1 }
sub selectrow_hashref { { DUMMY => 'hash' } }
sub fetchrow_hashref { { DUMMY => 'hash' } }
sub prepare { bless {}, 'MockDBI' }
sub execute { 1 }
sub last_insert_id { 1 }
sub selectall_arrayref { [{ foo => 1  }, { bar => 2 }] }

1;

*ActiveRecord::Simple::dbh = sub {
    return bless { Driver => { Name => 'mysql' } }, 'MockDBI';
};

package main;

use Test::More;

ok my $c = t::class->new({
    foo => 1,
    bar => 2,
});

ok $c->save(), 'save';
ok $c->foo(100);
is $c->foo, 100, 'update in memory ok';
ok $c->save(), 'update in database ok';

ok my $c2 = t::class->find(1), 'find, primary key';
isa_ok $c2, 'ActiveRecord::Simple::Find';

ok my $c21 = t::class->get(1), 'get';
isa_ok $c21, 't::class';

ok my $c3 = t::class->find({ foo => 'bar' }), 'find, params';
isa_ok $c3, 'ActiveRecord::Simple::Find';

ok my $c4 = t::class->find([1, 2, 3]), 'find, primary keys';
isa_ok $c4, 'ActiveRecord::Simple::Find';

ok my $c5 = t::class->find('foo = ?', 'bar'), 'find, binded params';
isa_ok $c5, 'ActiveRecord::Simple::Find';

is ref $c->to_hash, 'HASH', 'to_hash';

my $order_find = t::class->find()->order_by('foo');
$order_find->fetch;
ok $order_find->{SQL} =~ m/order by/i, 'order by';
$order_find = t::class->find()->order_by('foo')->desc;
$order_find->fetch;
ok $order_find->{SQL} =~ m/order by/i, 'order by';
ok $order_find->{SQL} =~ m/desc/i, 'order by, desc';

my $limit_find = t::class->find->limit(1);
$limit_find->fetch;
ok $limit_find->{SQL} =~ m/limit\s+1/i, 'limit 1';

my $offset_find = t::class->find->offset(2);
$offset_find->fetch();
ok $offset_find->{SQL} =~ m/offset\s+2/i, 'offset 2';

my $total_sql = t::class->find->limit(1)->offset(2)->order_by('foo')->desc;
$total_sql->fetch;
ok $total_sql->{SQL} =~ /limit\s+1/i, 'use all predicats, find "limit 1"';
ok $total_sql->{SQL} =~ /offset\s+2/i, 'use all predicats, find "offset 2"';
ok $total_sql->{SQL} =~ /order\s+by/i, 'use all predicats, find "order by"';
ok $total_sql->{SQL} =~ /desc/i, 'use all predicats, find "desc"';

ok $c->delete(), 'delete';

ok my $c6 = t::class->find->only('foo', 'bar'), 'find only "foo"';

my $r;
ok $r = t::class->find->first, 'first';

ok $r = t::class->find->first(10), 'first 10';

ok $r = t::class->find->last, 'last';

#is(t::ClaSs3->_table_name, 'cla_ss3');
#is(t::class->_table_name, 't');

my $cs1 = t::class->new();
my $cs2 = t::ClaSs3->new();


done_testing();