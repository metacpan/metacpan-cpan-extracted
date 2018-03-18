requires 'perl',            '5.010';
requires 'Log::Any',        '1.042';
requires 'Moo',             '2.002005';
requires 'Module::Runtime', '0.014';
requires 'Ouch',            '0.0500';
requires 'Try::Tiny',       '0.27';
requires 'Mojolicious',     '7.10';
requires 'IO::Socket::SSL', '2.056';
requires 'namespace::clean', '0.27';

on test => sub {
   requires 'Test::More',      '0.88';
   requires 'Path::Tiny',      '0.096';
   requires 'Mock::Quick',     '1.111';
   requires 'Test::Exception', '0.43';
   requires 'Test::Trap';    # for Ouch, apparently
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
