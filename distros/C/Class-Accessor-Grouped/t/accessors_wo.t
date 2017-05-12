use Test::More;
use Test::Exception;
use strict;
use warnings;
no warnings 'once';
use lib 't/lib';

# we test the pure-perl versions only, but allow overrides
# from the accessor_xs test-umbrella
# Also make sure a rogue envvar will not interfere with
# things
my $use_xs;
BEGIN {
  $Class::Accessor::Grouped::USE_XS = 0
    unless defined $Class::Accessor::Grouped::USE_XS;
  $ENV{CAG_USE_XS} = 1;
  $use_xs = $Class::Accessor::Grouped::USE_XS;
};

use AccessorGroupsWO;

my $obj = AccessorGroupsWO->new;

{
  my $warned = 0;

  local $SIG{__WARN__} = sub {
    if  (shift =~ /DESTROY/i) {
      $warned++;
    };
  };

  no warnings qw/once/;
  local *AccessorGroupsWO::DESTROY = sub {};

  $obj->mk_group_wo_accessors('warnings', 'DESTROY');
  ok($warned);
};

my $test_accessors = {
  singlefield => {
    is_xs => $use_xs,
  },
  multiple1 => {
  },
  multiple2 => {
  },
  lr1name => {
    custom_field => 'lr1;field',
  },
  lr2name => {
    custom_field => "lr2'field",
  },
  fieldname_torture => {
    custom_field => join ('', map { chr($_) } (0..255) ),
    is_xs => $use_xs,
  },
};

for my $name (sort keys %$test_accessors) {

  my $alias = "_${name}_accessor";
  my $field = $test_accessors->{$name}{custom_field} || $name;

  can_ok($obj, $name, $alias);

  ok(!$obj->can($field))
    if $field ne $name;

  # set via name
  is($obj->$name('a'), 'a');
  is($obj->{$field}, 'a');

  # alias sets same as name
  is($obj->$alias('b'), 'b');
  is($obj->{$field}, 'b');

  my $wo_regex = $test_accessors->{$name}{is_xs}
    ? qr/Usage\:.+$name.*\(self, newvalue\)/
    : qr/$name(:?_accessor)?\Q' cannot access its value (write-only attribute of class AccessorGroupsWO)/
  ;

  # die on get via name/alias
  SKIP: {
    skip "Class::XSAccessor emits broken error messages on 5.10 and earlier", 1 if (
      $test_accessors->{$name}{is_xs}
        and
      $] < '5.011'
    );

    throws_ok {
      $obj->$name;
    } $wo_regex;

    throws_ok {
      $obj->$alias;
    } $wo_regex;
  }
};

done_testing unless $::SUBTESTING;
