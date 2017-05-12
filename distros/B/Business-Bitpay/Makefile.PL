use inc::Module::Install;

all_from 'lib/Business/Bitpay.pm';

requires 'Carp';
requires 'HTTP::Request';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'URI';
test_requires 'Test::More' => '0.88';

tests 't/*.t';

resources
  bugtracker => 'https://github.com/und3f/bitpay/issues',
  repository => 'https://github.com/und3f/bitpay';

WriteAll;
