package AseNoFkActions;

# Takes the referential actions off a schema before it is deployed (karr k91).
#
# ASE has no declarative referential actions (Msg 156, NO ACTION included), and
# DBIO::Sybase::DDL refuses a relationship that becomes a foreign key
# constraint and declares one -- it used to drop it without a word. The shared
# DBIO::Test::Schema of core declares SET NULL, CASCADE and RESTRICT
# (CD.genre, Bookmark, ArtistUndirectedMap and others), so a live test that
# deploys it for some other claim -- a round trip, a column type, a log that
# runs full -- would stop at the refusal. Such a test calls strip() first; the
# refusal itself is pinned by t/76-ddl-fk-actions.t and t/77-fk-actions-live.t.
#
# Nothing of lib/ is used here.

use strict;
use warnings;

# AseNoFkActions::strip($schema_class_or_instance)
#
# Sets on_delete and on_update to undef on every relationship of every source
# and returns the schema. The relationship attributes are shared with the
# class, so the change holds for the rest of the process.
sub strip {
  my ($schema) = @_;
  for my $name ($schema->sources) {
    my $source = $schema->source($name);
    for my $rel ($source->relationships) {
      my $attrs = $source->relationship_info($rel)->{attrs} or next;
      $attrs->{$_} = undef for qw(on_delete on_update);
    }
  }
  return $schema;
}

1;
