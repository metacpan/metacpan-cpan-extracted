requires 'List::MoreUtils';
requires 'Moo';
requires 'Path::Tiny';
requires 'Text::CSV';
requires 'namespace::clean';
requires 'perl', '5.010000';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Warnings';
};
