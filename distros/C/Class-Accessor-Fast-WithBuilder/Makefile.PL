use inc::Module::Install;

name q(Class-Accessor-Fast-WithBuilder);
all_from q(lib/Class/Accessor/Fast/WithBuilder.pm);

requires q(Class::Accessor) => 0.32;
requires q(base) => 2.10;

test_requires q(Test::More) => 0.90;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Accessor-Fast-WithBuilder);
homepage q(http://search.cpan.org/dist/Class-Accessor-Fast-WithBuilder);
repository q(https://github.com/jhthorsen/class-accessor-fast-withbuilder.git);

# install_script glob('bin/*');
auto_install;
WriteAll;
