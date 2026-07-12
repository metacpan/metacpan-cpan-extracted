use strict;
use warnings;

use Test::More;

# Exercises the DBIO::Candy::Exports SYNOPSIS: a component registers sugar
# subs (export_methods / export_method_aliases) so that DBIO::Candy exports
# them into any result class that loads the component. No storage/DB is
# involved at all -- this is a pure class-registry mechanism, so there is
# nothing to mock.
#
# This test doubles as the "verification" pointed to by the comment in
# lib/DBIO/Candy/Exports.pm (the comment itself only concerns naming the
# generated `import` sub for t/55namespaces_cleaned.t -- it never claimed
# to cover export_methods/export_method_aliases; see that file's comment
# for the corrected wording).

use DBIO::Candy::Exports;

subtest 'export_methods / export_method_aliases register per-caller, not globally' => sub {
  package TestDBIO::CandyExports::CompA;
  DBIO::Candy::Exports->import;
  export_methods(['foo_method']);
  export_method_aliases({ foo => 'foo_method' });

  package TestDBIO::CandyExports::CompB;
  DBIO::Candy::Exports->import;
  export_methods(['bar_method']);

  package main;

  is_deeply(
    DBIO::Candy::Exports::get_methods_for('TestDBIO::CandyExports::CompA'),
    ['foo_method'],
    'get_methods_for returns only what CompA registered'
  );
  is_deeply(
    DBIO::Candy::Exports::get_aliases_for('TestDBIO::CandyExports::CompA'),
    { foo => 'foo_method' },
    'get_aliases_for returns only what CompA registered'
  );
  is_deeply(
    DBIO::Candy::Exports::get_methods_for('TestDBIO::CandyExports::CompB'),
    ['bar_method'],
    'CompB registered its own method list, independent of CompA'
  );
  ok !defined(DBIO::Candy::Exports::get_aliases_for('TestDBIO::CandyExports::CompB')),
    'CompB never called export_method_aliases, so it has none registered';
  ok !defined(DBIO::Candy::Exports::get_methods_for('TestDBIO::CandyExports::NeverCalled')),
    'a package that never called export_methods has nothing registered';
};

subtest 'SYNOPSIS: DBIO::Candy actually consumes a registered component\'s sugar' => sub {
  # The component must be require()-able as a real module (that's how
  # DBIO::Candy's -components loads it via load_components), so it is
  # declared inside a BEGIN block and pre-registered in %INC -- same
  # trick used elsewhere in this suite (e.g. t/datetime_format.t) to keep
  # an inline test fixture off disk.
  BEGIN {
    package TestDBIO::CandyExports::Widget;
    eval {
      require DBIO::Candy::Exports;
      DBIO::Candy::Exports->import;
      export_methods(['create_widget']);
      export_method_aliases({ widget => 'create_widget' });
    };
    die $@ if $@;
    sub create_widget {
      my $self = shift;
      $self->add_columns(@_);
    }
    $INC{'TestDBIO/CandyExports/Widget.pm'} = __FILE__;
  }

  package TestDBIO::CandyExports::Schema::Result::Thing;
  use DBIO::Candy -components => ['+TestDBIO::CandyExports::Widget'];

  table('things');
  primary_column(id => { data_type => 'integer', is_auto_increment => 1 });
  widget(foo => { data_type => 'varchar', size => 10 });

  package main;

  is_deeply(
    [ sort TestDBIO::CandyExports::Schema::Result::Thing->columns ],
    [ qw/foo id/ ],
    'the "widget" alias for the component-registered create_widget sugar reached add_columns'
  );
};

done_testing;
