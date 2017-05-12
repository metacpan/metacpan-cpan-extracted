use inc::Module::Install;

name     'Business-OnlinePayment-Iridium';
all_from 'lib/Business/OnlinePayment/Iridium.pm';

requires 'Test::More'              => 0;
requires 'Business::OnlinePayment' => 2.01;
requires 'Moose'                   => 0.93;
requires 'Template'                => 2.19;
requires 'aliased'                 => 0.22;
requires 'LWP::UserAgent'          => 5.810;
requires 'HTTP::Request'           => 5.811;
requires 'XML::Simple'             => 2.18;

auto_install;

WriteAll;
