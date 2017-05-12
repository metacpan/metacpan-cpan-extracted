use inc::Module::Install;

name 'Catalyst-View-MobileJpFilter';
all_from 'lib/Catalyst/View/MobileJpFilter.pm';

requires 'Catalyst::Runtime' => '5.70';
requires 'Catalyst::Plugin::MobileAgent';
requires 'HTML::MobileJp::Filter';
requires 'Data::Visitor::Callback';

build_requires 'Test::More';
build_requires 'Encode::JP::Mobile';

auto_include;

WriteAll;
