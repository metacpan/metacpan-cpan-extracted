package Test::DB2;

use DBIx::Mint;
use DBI;
use v5.10;

sub connection_params{
    return ( 'dbi:SQLite:dbname=t/bloodbowl2.db', '', '',
        { AutoCommit => 1, RaiseError => 1 });
}

sub remove_db {
    if (-e 't/bloodbowl2.db') {
        unlink 't/bloodbowl2.db';
    }
}

sub init {
    my $dbh = shift;
    local $/ = ';';
    while (<DATA>) {
        next unless $_;
        s/^\s+|;|\s+$//g;
        $dbh->do($_);
    }
}

sub init_db {
    remove_db();
    my $dbh  = DBI->connect( connection_params() );
    init($dbh);
    return $dbh;
}

sub connect_db {
    remove_db();
    my $mint = DBIx::Mint->new( name => 'BB2');
    $mint->connect( connection_params() );
    init($mint->dbh);
    return $mint;
}

1;

__DATA__
CREATE TABLE coaches (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    email     TEXT NOT NULL,
    password  TEXT NOT NULL
);

INSERT INTO coaches (name, email, password) VALUES ('first',  'first@gmail.com',        'bbbb');
INSERT INTO coaches (name, email, password) VALUES ('bb2_a',  'user_a@gmail.com',       'aaaa');
INSERT INTO coaches (name, email, password) VALUES ('bb2_b',  'user_b@gmail.com',       'cccc');
INSERT INTO coaches (name, email, password) VALUES ('bb2_c',  'user_c@gmail.com',       'dddd');

CREATE TABLE teams (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    coach     INTEGER,
    FOREIGN KEY (coach) REFERENCES coaches (id)
);

INSERT INTO teams (name, coach) VALUES ('Tinieblax', 1);

CREATE TABLE players (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    position  TEXT NOT NULL,
    team      INTEGER,
    FOREIGN KEY (team) REFERENCES teams (id)
);

INSERT INTO players (name, position, team) VALUES ('player1_2', 'trois-quarts', 1);
INSERT INTO players (name, position, team) VALUES ('player2_2', 'trois-quarts', 1);
INSERT INTO players (name, position, team) VALUES ('player3_2', 'blitzeur',     1);
INSERT INTO players (name, position, team) VALUES ('player4_2', 'recepteur',    1);
INSERT INTO players (name, position, team) VALUES ('player5_2', 'lanceur',      1);

CREATE TABLE skills (
    name     TEXT PRIMARY KEY,
    category TEXT NOT NULL
);

INSERT INTO skills (name, category) VALUES ('skill name 2', 'category name');
INSERT INTO skills (name, category) VALUES ('skill a 2',    'category a'   );
INSERT INTO skills (name, category) VALUES ('skill b 2',    'category b'   );
INSERT INTO skills (name, category) VALUES ('skill c 2',    'category c'   );

CREATE TABLE player_skills (
    player    INTEGER,
    skill     TEXT,
    FOREIGN KEY (player) REFERENCES players (id),
    FOREIGN KEY (skill)  REFERENCES skills  (name)
);

INSERT INTO player_skills (player, skill) VALUES (1, 'skill a 2');
INSERT INTO player_skills (player, skill) VALUES (1, 'skill b 2');
