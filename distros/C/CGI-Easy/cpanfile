requires 'perl', '5.010001';

requires 'Data::UUID';
requires 'Export::Attrs';
requires 'MIME::Base64';
requires 'URI::Escape';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
