package Blog::DataBase;
use strict;
use warnings;
use base qw(DBIx::MoCo::DataBase);

my $DB;
use File::Temp qw/tempfile/;
(undef, $DB) = tempfile( UNLINK => 1 );

__PACKAGE__->dsn("dbi:SQLite:dbname=$DB");

__PACKAGE__->execute(<<EOF);
CREATE TABLE user (
  user_id INTEGER PRIMARY KEY,
  name varchar(255) UNIQUE
)
EOF

my @users = (
    [qw(1 jkondo)],
    [qw(2 reikon)],
    [qw(3 cinnamon)],
);
__PACKAGE__->execute('insert into user values (?,?)',undef,$_) for @users;

__PACKAGE__->execute(<<EOF);
CREATE TABLE entry (
  entry_id INTEGER PRIMARY KEY,
  user_id INTEGER,
  uri text,
  title text,
  body text
)
EOF

my @entries = (
    [qw(1 1 http://test.com/entry-1 jkondo-1 hello)],
    [qw(2 1 http://test.com/entry-2 jkondo-2 world)],
    [qw(3 2 http://test.com/entry-3 reikon-1 hello)],
    [qw(4 3 http://test.com/entry-4 cinnamon-1 dog)],
);
__PACKAGE__->execute('insert into entry values (?,?,?,?,?)',undef,$_)
    for @entries;

__PACKAGE__->execute(<<EOF);
ALTER TABLE entry ADD created DATETIME
EOF
__PACKAGE__->execute('update entry set created = ?',undef,['2007-03-04 12:34:56']);

__PACKAGE__->execute(<<EOF);
CREATE TABLE bookmark (
  user_id INTEGER,
  entry_id INETEGER,
  PRIMARY KEY(user_id,entry_id)
)
EOF

my @bookmarks = ([1,3], [1,4], [2,1], [2,2], [3,2]);
__PACKAGE__->execute('insert into bookmark values (?,?)',undef,$_)
    for @bookmarks;

sub DESTROY {
    my $class = shift;
    $class->dbh->disconnect;
    unlink $DB if -e $DB;
}

1;
