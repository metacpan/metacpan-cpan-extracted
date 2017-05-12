use strict;
use warnings;
use inc::Module::Install;

name           ('Class-TransparentFactory');
license        ('MIT');
perl_version   ('5.006');
all_from       ('lib/Class/TransparentFactory.pm');

sign;

auto_install;
WriteAll;
