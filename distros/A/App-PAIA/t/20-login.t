use strict;
use v5.10;
use Test::More;
use App::PAIA::Tester;

new_paia_test;

paia qw(config base http://example.org);
paia qw(login -u alice -p 1234 -v);

is output, <<OUT;
# loaded config file paia.json
# POST http://example.org/auth/login
OUT

is error, "PAIA requires HTTPS unless insecure (got http://example.org/auth/login)\n";
ok exit_code;

done_paia_test;
