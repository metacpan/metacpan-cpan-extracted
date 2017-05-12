package TestDB::Users;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('users');
#__PACKAGE__->add_columns( All => qw[user passphrase] );
__PACKAGE__->add_columns(qw[ user passphrase ]);

sub setuptable {
    my ($self, $dbh) = @_;
    
    local $/ = "\n\n";
    $dbh->do($_) for <DATA>;
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

