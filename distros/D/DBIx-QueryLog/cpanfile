requires 'DBI';
requires 'Term::ANSIColor';
requires 'Text::ASCIITable';
requires 'Time::HiRes';
requires 'Data::Dumper';
requires 'perl', '5.008001';
recommends 'DBD::mysql';
recommends 'DBD::SQLite';
recommends 'DBD::Pg';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
};

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Requires';
    recommends 'Test::mysqld', '0.17';
    recommends 'Test::PostgreSQL', '0.10';
};
