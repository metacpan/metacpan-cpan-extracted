# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 53;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use lib qw(t/lib);
use t::util;
use t::model::derived;
use t::model::derived_status;
use t::model::status;

use_ok('ClearPress::model');

my $util = t::util->new();

{
  my $d = t::model::derived->new({
				  util       => $util,
				  id_derived => 1,
				 });
  my $c1 = t::model::derived_child->new({
					 util       => $util,
					 id_derived => 1,
					 text_dummy => 'child one',
					});
  ok($c1->create(), 'child one create');

  my $c2 = t::model::derived_child->new({
					 util       => $util,
					 id_derived => 1,
					 text_dummy => 'child two',
					});
  ok($c2->create(), 'child two create');

  ok($d->can('children'), 'can children()');
  my $children = $d->children();
  is((scalar @{$children}), 2, 'children ok');
}

{
  my $model = ClearPress::model->new({util=>$util});
  isa_ok($model, 'ClearPress::model');
  is((scalar $model->fields()), undef, 'default model has no fields');
}

{
  my $derived = t::model::derived->new({util => $util});
  my @fields = $derived->fields();
  is((scalar @fields), 7, 'derived class field number');
  is($derived->primary_key(), 'id_derived', 'derived class has correct primary key');
  is($derived->table(), 'derived', 'derived class has correct table name via object method');
  is(t::model::derived->table(), 'derived', 'derived class has correct table name via class method');
  is(ClearPress::model::table(), undef, 'base class has no name via procedural call');
}

{
  isa_ok(t::model::derived->util(), 'ClearPress::util', 'util() class method returns a new util');
}

{
  my $derived = {};
  bless $derived, q[testfoo];
  @testfoo::ISA = qw(ClearPress::model);

  local $trap;
  trap {
    $derived->util();
  };

  like($trap->die, qr/No\ such\ file/mx, 'die if config.ini unavailable');
}

{
  my $d = t::model::derived->new({
				  util       => $util,
				  text_dummy => 'some text',
				  char_dummy => 'some chars',
				  id_derived_status => 1,
				 });
  ok($d->create(), 'object create');
  is($d->id_derived(), 1, 'autoinc id 1');
}

{
  my $d = t::model::derived->new({
				  util       => $util,
				  text_dummy => 'some more text',
				  char_dummy => 'some more chars',
				 });
  ok($d->create(), 'object create');
  is($d->id_derived(), 2, 'autoinc id 2');
}

{
  my $d    = t::model::derived->new({util => $util});
  my $list = $d->deriveds();
  is((scalar @{$list}), 2, 'list yields 2');
}

{
  my $d    = t::model::derived->new({
				     util       => $util,
				     id_derived => 1,
				    });
  is($d->id_derived, 1, 'id_derived');
  is($d->text_dummy, 'some text',  'text_dummy');
  is($d->char_dummy, 'some chars', 'char_dummy');
  is($d->int_dummy,  undef,        'int_dummy');
}

#{
#  my $ref = t::model::derived->gen_getarray('t::model::derived',
#				     q[SELECT id_derived FROM derived]);
#  is($ref, undef, 'failed config load for class method');
#}

{
  my $d = t::model::derived->new({
				  util       => $util,
				  id_derived => 2,
				 });
  $d->text_dummy('changed text');
  ok($d->update(), 'update');
  is($d->text_dummy(), 'changed text', 'text dummy changed in same obj');
  is($d->int_dummy(), undef, 'int dummy unchanged in same obj');
  is($d->char_dummy(), 'some more chars', 'char_dummy unchanged in same obj');

  my $d2 = t::model::derived->new({
				   util => $util,
				   id_derived => 2,
				  });
  for my $f ($d->fields()) {
    is($d2->$f(), $d->$f(), "$f matches");
  }
}

{
  my $d = t::model::derived->new({
				  util       => $util,
				  id_derived => 2,
				 });
  ok($d->delete(), 'delete');

  my $d2 = t::model::derived->new({
				   util       => $util,
				   id_derived => 2,
				  });
  is($d2->read(), undef, 'entity not in database');
}

{
  my $d = t::model::derived->new({
				  util => $util,
				  id_derived => 1,
				 });
  my $s = t::model::status->new({
				 util => $util,
				 description => 'status desc',
				});
  ok($s->create(), 'status create');

  my $ds = t::model::derived_status->new({
					  util => $util,
					  id_status => $s->id_status(),
					 });
  ok($ds->create(), 'derived_status create');

  ok($d->can('status'), 'can status()');
  isa_ok($d->status(), 't::model::status');
  is($d->status->id_status(), $s->id_status(), 'status ids match');
}

{
  my $d = t::model::derived->new({
				  util => $util,
				  id_derived => 1,
				 });
  my $a1 = t::model::attribute->new({
				     util => $util,
				     description => 'attr one',
				    });
  ok($a1->create(), 'attribute create');

  my $a2 = t::model::attribute->new({
				     util => $util,
				     description => 'attr two',
				    });
  ok($a2->create(), 'attribute create');

  my $da1 = t::model::derived_attr->new({
					 util => $util,
					 id_derived => $d->id_derived(),
					 id_attribute => $a1->id_attribute(),
					});
  ok($da1->create(), 'derived_attr 1 create');

  my $da2 = t::model::derived_attr->new({
					 util => $util,
					 id_derived => $d->id_derived(),
					 id_attribute => $a2->id_attribute(),
					});
  ok($da2->create(), 'derived_attr 2 create');

  ok($d->can('attributes'), 'can attributes()');
  isa_ok($d->attributes(), 'ARRAY');
  is((scalar @{$d->attributes}), 2, 'attribute set size');
  isa_ok($d->attributes->[0], 't::model::attribute', 'first el isa_ok');

  is($d->attributes->[0]->id_attribute(), $a1->id_attribute(), 'attr 1 id matches');
}

{
  my $d = t::model::derived->new({
				  util => $util,
				  id_derived => 1,
				 });
  my $ds = $d->gen_getobj('t::model::derived_status');
  isa_ok($ds, 't::model::derived_status');
}

{
  my $d = t::model::derived->new();
  like($d->zdate(), qr/\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}Z/mx);
}

{
  my $d = t::model::derived->new(1);
  $d->util($util);
  is($d->id_derived(), 1, 'construction with only a primary key');
}
