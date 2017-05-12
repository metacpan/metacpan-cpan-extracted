#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose', 'Test::Moose';
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('moose-metaclasses');
push @INC, $dir->dirname;

our %reloaded;

require Foo;
require Bar;

Class::Refresh->refresh;

my $metaclass = Scalar::Util::blessed(Foo->meta);

does_ok(Foo->meta, 'Foo::Meta::Class');
ok(!Moose::Util::does_role(Bar->meta, 'Foo::Meta::Class'),
   "!Bar->meta->does('Foo::Meta::Class')");
ok(Foo->meta->meta->find_attribute_by_name('meta_attr'),
   "has meta attribute");
ok(!Foo->meta->meta->find_attribute_by_name('meta_attr2'),
   "doesn't have other meta attribute");
is_deeply(\%reloaded,
          { foo => 1, foo_meta_class => 1, bar => 1 },
          "everything loaded");


sleep 2;
update_temp_dir_for('moose-metaclasses', $dir);

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    Class::Refresh->refresh;
    like($warnings, qr/Not reloading Moose::Meta::Class::__ANON__::SERIAL::/);
}

does_ok(Foo->meta, 'Foo::Meta::Class');
ok(!Moose::Util::does_role(Bar->meta, 'Foo::Meta::Class'),
   "!Bar->meta->does('Foo::Meta::Class')");
{ local $TODO = "moose needs a way to clear out its anon class cache";
ok(!Foo->meta->meta->find_attribute_by_name('meta_attr'),
   "doesn't have meta attribute");
ok(Foo->meta->meta->find_attribute_by_name('meta_attr2'),
   "has other meta attribute");
isnt(Scalar::Util::blessed(Foo->meta), $metaclass, "Foo got a new metaclass");
}
is_deeply(\%reloaded,
          { foo => 2, foo_meta_class => 2, bar => 1 },
          "everything loaded");

done_testing;
