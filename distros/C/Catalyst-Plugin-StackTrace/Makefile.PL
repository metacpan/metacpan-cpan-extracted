use inc::Module::Install 0.87;

name('Catalyst-Plugin-StackTrace');
all_from('lib/Catalyst/Plugin/StackTrace.pm');

requires 'Catalyst' => '5.70';
requires 'Devel::StackTrace';
requires 'MRO::Compat' => '0.10';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-StackTrace/';

WriteAll;
