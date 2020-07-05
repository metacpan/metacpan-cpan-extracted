requires 'DBI';
requires 'DBI::Const::GetInfoType';
requires 'Encode';
requires 'Log::Dispatch';
requires 'Scalar::Util';
requires 'Term::Encoding';
requires 'parent';
requires 'perl', '5.008001';
requires 'version', '0.77';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'DBD::SQLite', '1.62';
    requires 'FindBin::libs';
    requires 'Test::Exception';
    requires 'Test::More', '0.98';
    requires 'Test::More::UTF8';
    requires 'YAML::Syck';
};
