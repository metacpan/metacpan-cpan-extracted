requires 'DBI';
requires 'DBD::Pg';
requires 'Date::Utility';
requires 'JSON';
requires 'Moose';
requires 'Test::PostgreSQL';
requires 'Test::Mock::Redis';
requires 'perl', '5.014';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::NoWarnings';
};
