#! perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Deep;
use Cwd;
use App::Smolder::Report;

my $sr = App::Smolder::Report->new({ run_as_api => 1 });
ok(!defined($sr->server));
ok(!defined($sr->project_id));
ok(!defined($sr->username));
ok(!defined($sr->password));

my $cfg;
lives_ok sub {
  $cfg = $sr->_read_cfg_file('t/data/cfg/smolder_1.conf');
};
cmp_deeply($cfg, {
  server     => 'server1',
  project_id => 1,
  username   => 'user1',
  password   => 'pass1',
  delete     => 1,
});

throws_ok sub {
  $sr->_read_cfg_file('t/data/cfg/bad_smolder_1.conf')
}, qr/Could not parse line \d+ of /;

throws_ok sub {
  $sr->_merge_cfg_file('t/data/cfg/bad_smolder_2.conf')
}, qr/Invalid configuration keys in .+pass/s;

$sr->_merge_cfg_hash($cfg);
cmp_deeply($cfg, {});
is($sr->server,     'server1');
is($sr->project_id, 1);
is($sr->username,   'user1');
is($sr->password,   'pass1');

SKIP: {
  my $cwd = getcwd();
  my $base = 't/data/cfg';
  my $dir = "$base/cwd";
  chdir($dir) || skip "Could not chdir to $dir: $!", 4;
  
  $ENV{HOME} = "$cwd/$base/home";
  
  $sr = App::Smolder::Report->new;
  $sr->_load_configs;
  is($sr->server,     'smolder.example.com');
  is($sr->project_id, 45);
  is($sr->username,   'superme');
  is($sr->password,   'supersecret');
  
  
  $sr = App::Smolder::Report->new;
  $ENV{APP_SMOLDER_REPORT_CONF} = 'tweak.conf';
  $sr->_load_configs;
  
  is($sr->server,     'smolder.example.com');
  is($sr->project_id, 45);
  is($sr->username,   'superme');
  is($sr->password,   'omfg');
  
  $sr = App::Smolder::Report->new({
    load_config => 1,
    username    => 'keep_me',
  });
  is($sr->server,     'smolder.example.com');
  is($sr->project_id, 45);
  is($sr->username,   'keep_me');
  is($sr->password,   'omfg');
  
  $ENV{APP_SMOLDER_REPORT_CONF} = 'empty.conf';
  $sr = App::Smolder::Report->new;
  local @ARGV = (
    "--username=userc",
    "--password=passc",
    "--server=serverc",
    "--project-id=25",
    "--delete",
  );
  $sr->process_args;
  is($sr->server,     'serverc');
  is($sr->project_id, 25);
  is($sr->username,   'userc');
  is($sr->password,   'passc');
  ok($sr->delete);
  ok(!$sr->dry_run);
  ok(!$sr->quiet);
  
  $sr = App::Smolder::Report->new;
  local @ARGV = (
    '--delete',
    '--password=pass',
    '--quiet',
    '--dry-run'
  );
  $sr->process_args;
  is($sr->server,     'empty');
  is($sr->project_id, 0);
  is($sr->username,   'empty');
  is($sr->password,   'pass');
  ok($sr->delete);
  ok($sr->dry_run);
  ok($sr->quiet);
}
