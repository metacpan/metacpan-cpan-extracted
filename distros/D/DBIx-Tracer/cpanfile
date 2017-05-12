requires 'DBI';
requires 'parent';

# This module doesn't work on `$DBD::SQLite::VERSION < 1.48`
requires 'DBD::SQLite', '1.48';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};
