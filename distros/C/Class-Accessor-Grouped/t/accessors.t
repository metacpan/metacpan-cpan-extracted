use Test::More;
use strict;
use warnings;
no warnings 'once';
use lib 't/lib';
use B qw/svref_2object/;

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

require AccessorGroupsSubclass;

my $test_accessors = {
  singlefield => {
    is_simple => 1,
    has_extra => 1,
  },
  runtime_around => {
    # even though this accessor is declared as simple it will *not* be
    # reinstalled due to the runtime 'around'
    forced_class => 'AccessorGroups',
    is_simple => 1,
    has_extra => 1,
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
    is_simple => 1,
    custom_field => join ('', map { chr($_) } (0..255) ),
  },
};

for my $class (qw(
  AccessorGroupsSubclass
  AccessorGroups
  AccessorGroupsParent
)) {
  my $obj = $class->new;

  for my $name (sort keys %$test_accessors) {
    my $alias = "_${name}_accessor";
    my $field = $test_accessors->{$name}{custom_field} || $name;
    my $extra = $test_accessors->{$name}{has_extra};
    my $origin_class = 'AccessorGroupsParent';

    if ( $class eq 'AccessorGroupsParent' ) {
      next if $name eq 'runtime_around';  # implemented in the AG subclass
      $extra = 0;
    }
    elsif ($name eq 'fieldname_torture') {
      $field = reverse $field;
      $origin_class = 'AccessorGroups';
    }

    can_ok($obj, $name, $alias);
    ok(!$obj->can($field), "field for $name is not a method on $class")
      if $field ne $name;

    my $init_shims;

    # initial method name
    for my $meth ($name, $alias) {
      my $cv = svref_2object( $init_shims->{$meth} = $obj->can($meth) );
      is($cv->GV->NAME, $meth, "initial ${class}::$meth accessor is named");
      is(
        $cv->GV->STASH->NAME,
        $test_accessors->{$name}{forced_class} || $origin_class,
        "initial ${class}::$meth origin class correct",
      );
    }

    is($obj->$name, undef, "${class}::$name begins undef");
    is($obj->$alias, undef, "${class}::$alias begins undef");

    # get/set via name
    is($obj->$name('a'), 'a', "${class}::$name setter RV correct");
    is($obj->$name, 'a', "${class}::$name getter correct");
    is($obj->{$field}, $extra ? 'a Extra tackled on' : 'a', "${class}::$name corresponding field correct");

    # alias gets same as name
    is($obj->$alias, 'a', "${class}::$alias getter correct after ${class}::$name setter");

    # get/set via alias
    is($obj->$alias('b'), 'b', "${class}::$alias setter RV correct");
    is($obj->$alias, 'b', "${class}::$alias getter correct");
    is($obj->{$field}, $extra ? 'b Extra tackled on' : 'b', "${class}::$alias corresponding field still correct");

    # alias gets same as name
    is($obj->$name, 'b', "${class}::$name getter correct after ${class}::$alias setter");

    for my $meth ($name, $alias) {
      my $resolved = $obj->can($meth);

      my $cv = svref_2object($resolved);
      is($cv->GV->NAME, $meth, "$meth accessor is named after operations");
      is(
        $cv->GV->STASH->NAME,
        # XS deferred subs install into each caller, not into the original parent
        $test_accessors->{$name}{forced_class} || (
          ($use_xs and $test_accessors->{$name}{is_simple})
            ? (ref $obj)
            : $origin_class
        ),
        "${class}::$meth origin class correct after operations",
      );

      # just simple for now
      if ($use_xs and $test_accessors->{$name}{is_simple} and ! $test_accessors->{$name}{forced_class}) {
        ok ($resolved != $init_shims->{$meth}, "$meth was replaced with a resolved version");
        if ($class eq 'AccessorGroupsParent') {
          ok ($cv->XSUB, "${class}::$meth is an XSUB");
        }
        else {
          ok (!$cv->XSUB, "${class}::$meth is *not* an XSUB (due to get_simple overrides)");
        }
      }
    }
  }
}

done_testing unless $::SUBTESTING;
