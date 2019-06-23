requires 'Class::Load';
requires 'Data::Util';
requires 'parent';
requires 'perl', '5.008_001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'DBI';
    requires 'DBD::SQLite';
    requires 'Test::More';
};
