requires 'perl',          '5.010';
requires 'Mojolicious',   '7.08';
requires 'Minion',        '6.0';
requires 'Ouch',          '0.0409';
requires 'Log::Any',      '1.042';
requires 'Bot::ChatBots', '0.006';
requires 'Data::Tubes',   '0.736';

on test => sub {
   requires 'Test::More',              '0.88';
   requires 'Path::Tiny',              '0.096';
   requires 'Minion::Backend::SQLite', '0.007';
   requires 'Mock::Quick',             '1.111';
   requires 'Test::Trap';    # for Ouch, apparently
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
