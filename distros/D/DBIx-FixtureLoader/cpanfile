requires 'DBI';
requires 'DBIx::TransactionManager';
requires 'Moo';
requires 'SQL::Maker', '1.09';
requires 'parent';
requires 'perl', '5.008001';
requires 'Text::CSV';
requires 'JSON';
requires 'YAML::Tiny';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};

on develop => sub {
    requires 'Test::mysqld';
    requires 'DBD::SQLite';
};
