requires 'Redis';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Amon2';
    requires 'Test::More', '0.98';
    requires 'Test::RedisServer';
    requires 'parent';
};
