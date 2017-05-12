package App::HistHub::Schema::HistQueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("ResultSetManager", "UTF8Columns", "Core");
__PACKAGE__->table("hist_queue");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "peer",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "data",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "timestamp",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


package App::HistHub::Schema::HistQueue;
use strict;
use warnings;

use DateTime;

__PACKAGE__->belongs_to( peer => 'App::HistHub::Schema::Peer' );

__PACKAGE__->inflate_column(
    timestamp => {
        inflate => sub { DateTime->from_epoch( epoch => shift ) },
        deflate => sub { shift->epoch },
    },
);

sub insert {
    my $self = shift;
    $self->timestamp( DateTime->now ) unless $self->timestamp;
    $self->next::method(@_);
}

1;
