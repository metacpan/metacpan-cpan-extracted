use lib 't/lib';
use strict;
use warnings;

use Config::Plugin::TinyManifold::Test;

use Test::More;

# ------------------------------------------------

my($count)  = 0;
my($app)    = Config::Plugin::TinyManifold::Test -> new;
my($config) = $app -> marine;

ok(ref $config eq 'HASH', 'Called Config::Plugin::TinyManifold::config() from setup()');       $count++;
ok($$config{template_path} =~ m|/home/ron/|, 'config() returned the localhost template path'); $count++;

done_testing($count);
