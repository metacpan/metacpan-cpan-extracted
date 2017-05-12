package App::HistHub::Schema::Peer;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("ResultSetManager", "UTF8Columns", "Core");
__PACKAGE__->table("peer");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "uid",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "access_time",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


package App::HistHub::Schema::Peer;
use strict;
use warnings;

use DateTime;
use Data::UUID;
use Digest::SHA1 qw/sha1_hex/;

__PACKAGE__->has_many( queue => 'App::HistHub::Schema::HistQueue', 'peer', { order_by => 'timestamp' } );

__PACKAGE__->inflate_column(
    access_time => {
        inflate => sub { DateTime->from_epoch( epoch => shift ) },
        deflate => sub { shift->epoch },
    },
);

sub insert {
    my $self = shift;
    $self->uid( sha1_hex( Data::UUID->new->create ) );
    $self->access_time( DateTime->now ) unless $self->access_time;
    $self->next::method(@_);
}

sub push_queue {
    my ($self, $cmd) = @_;
    $self->add_to_queue({ data => $cmd });
}

sub pop_queue {
    my $self = shift;
    my $data = join '', map { $_->data . "\n" } $self->queue;
    $self->queue->delete_all;
    $data;
}

1;
