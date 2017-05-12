package TestUsers;

use base 'Class::DBI';

__PACKAGE__->connection('dbi:SQLite:t/db/users.db');
__PACKAGE__->table('users');
__PACKAGE__->columns( All => qw[user passphrase] );

sub setuptables {
  my $dbh=DBI->connect('dbi:SQLite:t/db/users.db');
  {
    local $/="\n\n";
    $dbh->do($_) for <DATA>
  }
}

1;

__DATA__
CREATE TABLE users (
  user varchar(16) PRIMARY KEY,
  passphrase varchar(25)
);

INSERT INTO users VALUES ('user1','123');

INSERT INTO users VALUES ('usermd5','e16b2ab8d12314bf4efbd6203906ea6c');

INSERT INTO users VALUES ('usercrypt','111ukgxvMW4Lw');

