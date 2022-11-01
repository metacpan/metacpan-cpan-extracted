requires 'perl', '5.014';

requires 'Data::Chronicle', '>= 0.18';
requires 'Data::Hash::DotNotation';
requires 'JSON::MaybeXS';
requires 'Moose';
requires 'Time::HiRes';
requires 'List::Util', '>= 1.29';
requires 'Date::Utility';
requires 'YAML::XS';
requires 'namespace::autoclean';
requires 'Syntax::Keyword::Try';

on test => sub {
    requires 'Test::MockObject';
    requires 'Test::More', '>= 0.98';
    requires 'Test::NoWarnings';
    requires 'Test::MockTime';
};

on develop => sub {
    requires 'Devel::Cover',                  '>= 1.23';
    requires 'Devel::Cover::Report::Codecov', '>= 0.14';
};
