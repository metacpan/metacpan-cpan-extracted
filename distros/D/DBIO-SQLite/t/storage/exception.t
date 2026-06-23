use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
use DBIO::Test::Schema;

# make sure nothing eats the exceptions (an unchecked eval in Storage::DESTROY used to be a problem)

{
  package Dying::Storage;

  use warnings;
  use strict;

  use base 'DBIO::Storage::DBI';

  sub _populate_dbh {
    my $self = shift;

    my $death = $self->_dbi_connect_info->[3]{die};

    die "storage test died: $death" if $death eq 'before_populate';
    my $ret = $self->next::method (@_);
    die "storage test died: $death" if $death eq 'after_populate';

    return $ret;
  }
}

for (qw/before_populate after_populate/) {
  throws_ok (sub {
    my $schema = DBIO::Test::Schema->clone;
    $schema->storage_type ('Dying::Storage');
    $schema->connection (DBIO::SQLite::Test->_database, { die => $_ });
    $schema->storage->ensure_connected;
  }, qr/$_/, "$_ exception found");
}

done_testing;
