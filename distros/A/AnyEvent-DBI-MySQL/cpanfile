requires 'perl', '5.010001';

requires 'AnyEvent';
requires 'DBD::mysql';
requires 'DBI';
requires 'Scalar::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::Database';
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Time::HiRes';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
