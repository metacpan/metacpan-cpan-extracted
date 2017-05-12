use strict;
use Test::More tests => 1;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
}


BEGIN { use_ok('Catalyst::Plugin::Log::Message') }
