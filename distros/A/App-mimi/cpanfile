requires 'perl', '5.008001';

requires 'Docopt';
requires 'DBI';

recommends 'DBD::SQLite';
recommends 'DBD::Pg';

on 'test' => sub {
    requires 'DBD::SQLite';
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
    requires 'Test::TempDir::Tiny';
};

