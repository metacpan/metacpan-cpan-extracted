requires 'perl', '5.012';

requires 'List::Util', '1.33';
requires 'Scalar::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'AE';
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
