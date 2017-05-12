use inc::Module::Install;
name 'App-HistHub';
all_from 'lib/App/HistHub.pm';

requires 'Catalyst::Runtime' => '5.70';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::View::Template::Declare';
requires 'Catalyst::View::JSON';
requires 'JSON::XS';
requires 'Moose';
requires 'POE';
requires 'POE::Wheel::FollowTail';
requires 'POE::Component::Client::HTTPDeferred';
requires 'HTTP::Request::Common';

test_requires 'Test::More';

use_test_base;
auto_include;

install_script('script/histhub_server.pl');
install_script('script/histhubd.pl');

tests 't/*.t t/*/*.t';

WriteAll;
