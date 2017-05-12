package Test::DB;

use DBIx::Mint;
use DBI;
use v5.10;

sub connection_params{
    return ( 'dbi:SQLite:dbname=t/bloodbowl.db', '', '',
        { AutoCommit => 1, RaiseError => 1 });
}

sub remove_db {
    if (-e 't/bloodbowl.db') {
        unlink 't/bloodbowl.db';
    }
}

sub init {
    my $dbh = shift;
    local $/ = ';';
    while (<DATA>) {
        next if /^\s*$/;
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
    my $mint = DBIx::Mint->connect( connection_params() );
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

INSERT INTO coaches (name, email, password) VALUES ('julio_f', 'julio.fraire@gmail.com', 'xxxx');
INSERT INTO coaches (name, email, password) VALUES ('user_a',  'user_a@gmail.com',       'wwww');
INSERT INTO coaches (name, email, password) VALUES ('user_b',  'user_b@gmail.com',       'yyyy');
INSERT INTO coaches (name, email, password) VALUES ('user_c',  'user_c@gmail.com',       'zzzz');

CREATE TABLE teams (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    coach     INTEGER,
    FOREIGN KEY (coach) REFERENCES coaches (id)
);

INSERT INTO teams (name, coach) VALUES ('Tinieblas', 1);

CREATE TABLE players (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    position  TEXT NOT NULL,
    team      INTEGER,
    FOREIGN KEY (team) REFERENCES teams (id)
);

INSERT INTO players (name, position, team) VALUES ('player1', 'trois-quarts', 1);
INSERT INTO players (name, position, team) VALUES ('player2', 'trois-quarts', 1);
INSERT INTO players (name, position, team) VALUES ('player3', 'blitzeur',     1);
INSERT INTO players (name, position, team) VALUES ('player4', 'recepteur',    1);
INSERT INTO players (name, position, team) VALUES ('player5', 'lanceur',      1);

CREATE TABLE skills (
    name     TEXT PRIMARY KEY,
    category TEXT NOT NULL
);

INSERT INTO skills (name, category) VALUES ('skill name', 'category name');
INSERT INTO skills (name, category) VALUES ('skill a',    'category a'   );
INSERT INTO skills (name, category) VALUES ('skill b',    'category b'   );
INSERT INTO skills (name, category) VALUES ('skill c',    'category c'   );

CREATE TABLE player_skills (
    player    INTEGER,
    skill     TEXT,
    FOREIGN KEY (player) REFERENCES players (id),
    FOREIGN KEY (skill)  REFERENCES skills  (name)
);

INSERT INTO player_skills (player, skill) VALUES (1, 'skill a');
INSERT INTO player_skills (player, skill) VALUES (1, 'skill b');
