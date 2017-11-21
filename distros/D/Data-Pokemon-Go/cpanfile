requires 'List::Util';
requires 'Moose';
requires 'Moose::Role';
requires 'Moose::Util::TypeConstraints';
requires 'Path::Tiny';
requires 'YAML::XS';
requires 'perl', '5.008001';
requires 'Text::CSV_XS', '1.34';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '1.302';
    requires 'Text::CSV_XS';
};
