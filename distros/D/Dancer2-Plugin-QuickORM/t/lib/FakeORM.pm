package FakeORM;
use strict;
use warnings;
use Carp qw/croak/;

# A minimal stand-in for a real DBIx::QuickORM-style backend, implementing
# only the interface Dancer2::Plugin::QuickORM actually calls:
#
#   $class->orm($name)                    -> connection object
#   $orm->schema($name)->tables           -> list of table objects
#   $table->name                          -> table name string
#   $orm->handle($table_name)             -> handle object
#   $handle->by_id($id)                   -> single row (hashref) or undef
#   $handle->where($hashref)->all         -> list of matching rows
#   $handle->all                          -> list of every row

use FakeORM::Connection;
use FakeORM::Table;
use FakeORM::Handle;

our %FIXTURE_TABLES = (
   widget => {
      pk   => 'id',
      rows => [
         { id => 1, name => 'left widget',  color => 'blue' },
         { id => 2, name => 'right widget', color => 'red' },
         { id => 3, name => 'top widget',   color => 'blue' },
      ],
   },
   moose => {
      pk   => 'id',
      rows => [
         { id => 1, name => 'Bullwinkle', herd => 'north' },
         { id => 2, name => 'Boris',      herd => 'north' },
         { id => 3, name => 'Rocky',      herd => 'south' },
      ],
   },
   session => {
      pk   => 'id',
      rows => [
         { id => 1, token => 'abc123' },
         { id => 2, token => 'def456' },
      ],
   },
   headers => {
      pk   => 'id',
      rows => [
         { id => 1, label => 'X-Test' },
      ],
   },

   # singularises/pluralises to 'orm'/'orms', which collides with the bare
   # 'orm' keyword this plugin always registers for itself (plugin_keywords
   # qw/orm/). The bare keyword should be left alone; only the
   # schema-prefixed form should reach this table.
   orm => {
      pk   => 'id',
      rows => [
         { id => 1, note => 'not the orm() keyword' },
      ],
   },
);

sub orm {
   my ( $class, $name ) = @_;
   return bless { name => $name }, 'FakeORM::Connection';
}

1;
