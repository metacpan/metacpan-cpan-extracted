use lib 't/lib';
use strict;
use warnings;

use Config::Plugin::Tiny::Test;

use Test::More;

# ------------------------------------------------

my($count)  = 0;
my($app)    = Config::Plugin::Tiny::Test -> new;
my($config) = $app -> marine;

ok(ref $config eq 'Config::Tiny', 'Called Config::Plugin::Tiny::config() from setup()');              $count++;
ok($$config{production}{template_path} =~ m|/dev/shm/|, 'config() returned the prod template path');  $count++;
ok($$config{testing}{template_path} =~ m|/home/ron/|, 'config() returned the testing template path'); $count++;

done_testing($count);
