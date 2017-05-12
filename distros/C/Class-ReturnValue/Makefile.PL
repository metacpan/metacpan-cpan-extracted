use inc::Module::Install;

name('Class-ReturnValue');
abstract('A smart return value object');
author('Jesse Vincent <jesse@bestpractical.com>');
version_from('lib/Class/ReturnValue.pm');
license('perl');
requires('Test::More');
requires('Devel::StackTrace');
WriteAll();
