requires 'perl',                  '5.010';
requires 'Bot::ChatBots',         '0.006';
requires 'IO::Socket::SSL',       '2.038';
requires 'Log::Any',              '1.042';
requires 'Mojolicious',           '7.08';
requires 'Ouch',                  '0.0409';
requires 'Try::Tiny',             '0.27';
requires 'WWW::Telegram::BotAPI', '0.10';
requires 'Moo',                   '2.002005';
requires 'namespace::clean',      '0.27';

on test => sub {
   requires 'Test::More',  '0.88';
   requires 'Path::Tiny',  '0.096';
   requires 'Mock::Quick', '1.111';
   requires 'Test::Trap';    # for Ouch, apparently
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
