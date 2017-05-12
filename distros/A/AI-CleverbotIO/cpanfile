requires 'perl',            '5.010';
requires 'HTTP::Tiny',      '0.070';
requires 'IO::Socket::SSL', '1.56';    # from HTTP::Tiny 0.070 docs
requires 'JSON::PP';                   # core from 5.14, any should do
requires 'Log::Any',    '1.045';
requires 'Moo',         '2.003000';
requires 'Net::SSLeay', '1.49';        # from HTTP::Tiny 0.070 docs
requires 'Ouch',        '0.0410';

on test => sub {
   requires 'Test::More',      '0.88';
   requires 'Path::Tiny',      '0.096';
   requires 'Test::Exception', '0.43';
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
