use inc::Module::Install;
name 'Bot-BasicBot-Pluggable-Module-Collection';
all_from 'lib/Bot/BasicBot/Pluggable/Module/Collection.pm';

requires 'Bot::BasicBot::Pluggable';
requires 'Bot::BasicBot::Pluggable::WithConfig' => '0.03';
requires 'WWW::HatenaStar';
requires 'Jcode';
requires 'Encode';
requires 'URI::Escape';
requires 'WWW::Google::Calculator';
requires 'Readonly';
requires 'Web::Scraper';
requires 'WebService::Livedoor::Weather';
requires 'WWW::Alexa::TrafficRank';
requires 'URI';
requires 'URI::QueryParam';
requires 'LWP::UserAgent';
requires 'JSON';
requires 'HTTP::Request::Common';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
