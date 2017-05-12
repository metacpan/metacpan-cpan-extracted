use strict;
use v5.10;
use Test::More;
use App::PAIA::Tester;

new_paia_test;

paia 'config';
is stdout, "{}\n", "empty configuration";
is error, undef;

paia qw(config --ini);
is stdout, "", "empty configuration (ini)";
is error, undef;

paia qw(config -c x.json --verbose);
is error, "failed to open config file x.json\n", "missing config file";
ok exit_code;

# add and get configuration values

paia qw(config --config x.json --verbose foo bar);
is output, "# saved config file x.json\n", "created config file";

paia qw(config foo bar);
paia qw(config base http://example.org/);
is exit_code, 0, "set config value";
is output, '';

paia qw(config base --verbose);
is stdout, "# loaded config file paia.json\nhttp://example.org/\n", "get config value";

paia qw(config);
is_deeply stdout_json, { 
    base => 'http://example.org/',
    foo => 'bar',
}, "get full config";

paia qw(config -i);
is output, "base=http://example.org/\nfoo=bar\n", "full config (ini)";

# unset configuration value

paia qw(config -d foo);
is output, '', 'unset config value';

paia qw(config foo);
is exit_code, 1, "config value not found";

# override base with command line option

paia qw(login -u alice -p 1234 -b http://example.com/ -v);

is output, <<OUT;
# loaded config file paia.json
# POST http://example.com/auth/login
OUT

done_paia_test;
