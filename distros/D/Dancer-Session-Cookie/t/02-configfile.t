use Test::More import => ['!pass'];
use Test::Exception;
#use Test::NoWarnings;

use strict;
use warnings;
use Dancer;
use Dancer::ModuleLoader;
use Dancer::Session::Cookie;
use FindBin;
use File::Spec;

use Test::Requires 'YAML';

plan tests => 3;

my $session;

throws_ok { $session = Dancer::Session::Cookie->create }
    qr/session_cookie_key must be defined/, 'still requires session_cookie_key';

set confdir => "$FindBin::Bin/data";
ok(-r File::Spec->catfile(setting('confdir'), 'config.yml'),
    'config.yml is available');

Dancer::Config::load();

lives_and { $session = Dancer::Session::Cookie->create }
    'session key loaded from config.yml';
is $@, '', "Cookie session created";
