use strict;
use warnings;
use Test::Exit;
use Test2::Plugin::FauxHomeDir;
use Test::Clustericious::Config;
use Test::More;
use App::clad;
use Capture::Tiny qw( capture );
use Path::Class qw( file dir );
use File::Temp qw( tempdir );

plan tests => 22;

create_config_ok 'Clad', {
  env => {
    FOO => "BAR",
  },
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
  alias => {
    alias1 => 'foo bar baz',
    alias2 => [qw( foo bar baz )],
  },
};

subtest 'dry run' => sub {
  plan tests => 2;

  is(App::clad->new('-n', 'cluster1', 'echo')->dry_run, 1, '-n on');
  is(App::clad->new('cluster1', 'echo')->dry_run,       0, '-n off');

};

subtest 'color' => sub {
  plan tests => 2;

  local $App::clad::_stdout_is_terminal = sub { 1 };

  is(App::clad->new('-a', 'cluster1', 'echo')->color, 0, '-a on');
  is(App::clad->new('cluster1', 'echo')->color,       1, '-a off');

};

subtest 'user' => sub {
  plan tests => 2;
  
  is(App::clad->new('-l' => 'foo', 'cluster1', 'echo')->user, 'foo', '-l foo');
  is(App::clad->new('cluster1', 'echo')->user,                undef, 'no user');
  
};

subtest 'max' => sub {
  plan tests => 2;
  
  # NOTE: the functionality is as of this writing not tested for this option
  # because it is hard to test what amounts to a race condition
  is(App::clad->new('--max' => '47', 'cluster1', 'echo')->max, '47', '--max 47');
  is(App::clad->new('cluster1', 'echo')->max,                   0,   'max = 0');
};

subtest 'help' => sub {
  eval {
    is exit_code { App::clad->new('--help') }, 1, "--help";
    is exit_code { App::clad->new('-h')     }, 1, "-h";
  };
  if(my $error = $@)
  {
    fail "unexpected exception: $error";
  }
};

subtest 'version' => sub {
  plan tests => 1;

  foreach my $arg (qw( --version ))
  {
    subtest $arg => sub {
      plan tests => 2;
      my($out, $err, $exit) = capture { exit_code { App::clad->new($arg) } };
      is $exit, 1, 'exit = 1';
      note "[out]\n$out\n" if $out;
      note "[err]\n$err\n" if $err;
      is $err, "App::clad version @{[ $App::clad::VERSION // 'dev' ]}\n", 'output';
    };
  }
};

subtest 'not enough arguments' => sub {
  plan tests => 2;

  is(App::clad->new->ret, 1, 'no args');
  is exit_code { App::clad->new('cluster1') }, 1, 'one args';

};

subtest 'single host as cluster' => sub {
  plan tests => 1;
  my($out, $err, $app) = capture { App::clad->new("foo", "bar") };
  isa_ok $app, 'App::clad';
};

subtest 'single host cluster with user' => sub {
  plan tests => 1;
  my($out, $err, $app) = capture { App::clad->new('bar@foo', "bar") };
  isa_ok $app, 'App::clad';
};

subtest 'server' => sub {

  is(App::clad->new('--server')->server, 1, 'clad.server = 1');
  is(App::clad->new('cluster1','uptime')->server, 0, 'clad.server = 0');
};

subtest 'verbose' => sub {
  plan tests => 2;

  is(App::clad->new('--verbose', 'cluster1', 'echo')->verbose, 1, '--verbose on');
  is(App::clad->new('cluster1', 'echo')->verbose,       0, '--verbose off');

};

subtest 'serial' => sub {
  plan tests => 2;

  is(App::clad->new('--serial', 'cluster1', 'echo')->serial, 1, '--serial on');
  is(App::clad->new('cluster1', 'echo')->serial,       0, '--serial off');

};

subtest 'illegal options as cluster' => sub {
  plan tests => 2;
  my($out, $err, $exit) = capture { exit_code { App::clad->new("--foo", "bar") } };
  is $exit, 1, 'exit = 1';
  like $out, qr{Unknown option: foo}, "diagnostic";
};

subtest 'illegal options as command' => sub {
  plan tests => 2;
  my($out, $err, $exit) = capture { exit_code { App::clad->new("cluster1", "--bar") } };
  is $exit, 1, 'exit = 1';
  like $out, qr{Unknown option: bar}, "diagnostic";
};

subtest 'file' => sub {
  plan tests => 2;

  my $temp = dir( tempdir( CLEANUP => 1 ) );
  
  my $file1 = $temp->file('file1.txt');  
  my $file2 = $temp->file('file2.txt');  
  my $file3 = $temp->file('bogus.txt');

  $file1->spew('data');
  $file2->spew('data');

  subtest 'files exist' => sub {
    plan tests => 2;
    my($out, $err, $clad) = capture { App::clad->new('--file' => $file1, "--file" => $file2, "cluster1", "uptime") };
    isa_ok $clad, 'App::clad';
    is_deeply [$clad->files], ["$file1","$file2"], 'files';
  };

  subtest 'file does not exist' => sub {
    my ($out, $err, $exit) = capture { exit_code { App::clad->new('--file' => $file1, "--file" => $file3, "cluster1", "uptime") } };
    is $exit, 2, 'exit = 2';
    like $err, qr{unable to find $file3}, 'diagnostic';
  };

};

subtest '--dir' => sub {

  plan tests => 2;

  my $temp = dir( tempdir( CLEANUP => 1 ) );
  my $bogus = $temp->subdir('foo');
  
  subtest 'dir exists' => sub {
    plan tests => 2;
    my($out, $err, $clad) = capture { App::clad->new('--dir' => $temp, "cluster1", "uptime") };
    isa_ok $clad, 'App::clad';
    is $clad->dir, "$temp", 'dir';
  };
  
  subtest 'dir does not exist' => sub {
    plan tests => 2;
    my ($out, $err, $exit) = capture { exit_code { App::clad->new("--dir" => $bogus, "cluster1", "uptime") } };
    is $exit, 2, 'exit = 2';
    like $err, qr{unable to find $bogus}, 'diagnostic';
  };

};

subtest '--summary' => sub {

  plan tests => 2;

  subtest with => sub {
    plan tests => 2;
  
    my($out, $err, $clad) = capture { App::clad->new('--summary', 'cluster1', 'uptime') };
    isa_ok $clad, 'App::clad';
    is $clad->summary, 1, 'with --summary';
  };

  subtest without => sub {
    plan tests => 2;

    my($out, $err, $clad) = capture { App::clad->new('cluster1', 'uptime') };
    isa_ok $clad, 'App::clad';
    is $clad->summary, 0, 'without --summary';
  };

};

subtest '--log-dir' => sub {
  plan tests => 3;

  my $dir = dir( tempdir( CLEANUP => 1 ) , 'foo' );
  
  my($out, $err, $clad) = capture { App::clad->new('--log-dir' => "$dir", 'cluster1', 'uptime') };
  isa_ok $clad, 'App::clad';
  is $clad->log_dir->stringify, "$dir", "dir = dir";
  ok -d $dir, 'created directory';

};

subtest '--log' => sub {
  plan tests => 2;

  my($out, $err, $clad) = capture { App::clad->new('--log', 'cluster1', 'uptime') };
  isa_ok $clad, 'App::clad';
  ok -d $clad->log_dir->stringify, "dir = @{[ $clad->log_dir ]}";

};

subtest '--purge' => sub {

  plan tests => 2;
  
  subtest with => sub {
    plan tests => 2;

    my($out, $err, $clad) = capture { App::clad->new('--purge') };
    isa_ok $clad, 'App::clad';
    is $clad->purge, 1, 'purge = 1';
  };

  subtest with => sub {
    plan tests => 2;

    my($out, $err, $clad) = capture { App::clad->new('cluster1', 'uptime') };
    isa_ok $clad, 'App::clad';
    is $clad->purge, 0, 'purge = 0';
  };

};

subtest '--list' => sub {

  subtest with => sub {
    plan tests => 2;

    my($out, $err, $clad) = capture { App::clad->new('--list') };
    isa_ok $clad, 'App::clad';
    is $clad->list, 1, 'list = 1';
  };

  subtest with => sub {
    plan tests => 2;

    my($out, $err, $clad) = capture { App::clad->new('cluster1', 'uptime') };
    isa_ok $clad, 'App::clad';
    is $clad->list, 0, 'list = 0';
  };
};
