use inc::Module::Install;

name 'Catalyst-Model-Net-Amazon';
all_from 'lib/Catalyst/Model/Net/Amazon.pm';

requires 'perl'        => '5.8.1';
requires 'Catalyst'    => 0;
requires 'Net::Amazon' => 0;

no_index directory => 't/lib';

auto_install;
&WriteAll;
