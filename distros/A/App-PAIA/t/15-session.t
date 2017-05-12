use strict;
use v5.10;
use Test::More;
use App::PAIA::Tester;

new_paia_test;

# no session
paia 'session';
is error, "no session file found.\n", "no session file";

# auto-login
paia_response 200, [ ], {
  access_token => "2YotnFZFEjr1zCsicMWpAA",
  token_type => "Bearer",
  expires_in => 3600,
  patron => "8362432",
  scope => "read_patron read_fees read_items write_items"
};

paia qw(patron -b https://example.org/ -u alice -p 1234 -v -q);
is output, <<OUT, 'auto-login with session';
# auto-login with scope 'read_patron'
# POST https://example.org/auth/login
# saved session file paia-session.json
# GET https://example.org/core/8362432
OUT

paia qw(session);
is output, "session looks fine.\n", "session looks fine";

paia qw(config base http://example.com/paia);
paia qw(session -v);
is_deeply [ (output =~ /^# .... URL: .+/mg) ],
    [ '# auth URL: https://example.org/auth',
      '# core URL: https://example.org/core' ],
    'session overrides config file';

paia qw(patron -b https://example.com/ -v -q);
is output, <<OUT, 'command line arguments override session file';
# loaded config file paia.json
# loaded session file paia-session.json
# saved session file paia-session.json
# GET https://example.com/core/8362432
OUT

paia qw(config -c test.json base http://example.com/paia);
paia qw(config -c test.json);
my $output = output;
$output =~ s/[\n\t ]+//gm;
is $output, '{"base":"http://example.com/paia"}', 'config';

done_paia_test;
