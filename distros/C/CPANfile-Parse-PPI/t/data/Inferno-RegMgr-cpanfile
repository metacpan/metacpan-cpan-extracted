requires 'perl', '5.010001';

requires 'EV';
requires 'Export::Attrs';
requires 'IO::Stream';
requires 'Scalar::Util';
requires 'version';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::Perl::Critic';
};
