package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_components(qw/+DBIx::Class::Schema::Journal/);

__PACKAGE__->journal_component("Journal::EvalWrap");

no warnings qw/qw/;
DBICTest::Schema->load_classes(
qw/
  Artist
  CD
  Track
/
);

1;
