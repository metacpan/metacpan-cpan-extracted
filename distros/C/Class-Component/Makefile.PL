use inc::Module::Install;
name 'Class-Component';
all_from 'lib/Class/Component.pm';

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

requires $_ for (qw/
    Carp::Clan
    Class::Accessor::Fast
    Class::Data::Inheritable
    Class::Inspector
    UNIVERSAL::require
/);

features(
    'Plaggerize' => [
        -default => 0,
        recommends_hack('Encode'),
        recommends_hack('YAML'),
    ],
    'ANSI Color Logging for Plaggerize' => [
        -default => 0,
        recommends_hack('Term::ANSIColor'),
    ],
);

build_requires 'Test::More';
#use_test_base;
auto_include;
auto_install;
WriteAll;
