use inc::Module::Install;

require 5.00502;

name('Class-Rebless');
license('MIT');
all_from('lib/Class/Rebless.pm');
requires('Scalar::Util' => '1.01');

sign;

auto_install;
WriteAll;

