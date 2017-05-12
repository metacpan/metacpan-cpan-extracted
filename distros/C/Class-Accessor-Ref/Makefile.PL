use inc::Module::Install;

require 5.00502;

name          ('Class-Accessor-Ref');
license       ('MIT');
all_from      ('lib/Class/Accessor/Ref.pm');
requires      ('Class::Accessor' => '0.10');
build_requires('Test::More'      => 0,);

sign;

auto_install;
WriteAll;

