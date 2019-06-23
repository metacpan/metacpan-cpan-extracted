requires 'AnyEvent';
requires 'Class::Accessor::Lite', '0.04';
requires 'List::Util';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'perl', '5.008_001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::SharedFork', '0.31';
    requires 'Test::SharedObject';
};
