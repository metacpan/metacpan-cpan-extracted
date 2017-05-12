use strict;
use warnings;
use 5.010;
use Test::Clustericious::Config;
use Test::More tests => 17;
use Capture::Tiny qw( capture );
use File::Temp qw( tempdir );
use Path::Class qw( file dir );
use YAML::XS qw( Dump Load );

do {
  no warnings;
  sub Sys::Hostname::hostname {
    'myfakehostname';
  }
};

require_ok 'App::clad';

create_config_ok 'Clad', {
  env => {
    FOO => "BAR",
  },
  clusters => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
  },
  alias => {
    alias1 => 'foo bar baz',
    alias2 => [qw( foo bar baz )],
  },
};

sub generate_stdin ($)
{
  my($data) = @_;
  my $fn = file( tempdir( CLEANUP => 1 ), "stdin.yml");
  $fn->spew(Dump($data));
  open STDIN, '<', $fn;
}

subtest 'exits' => sub {

  subtest 'exit 0' => sub {
    plan tests => 1;
    generate_stdin {
      env     => {},
      command => [ $^X, -E => "exit 0" ],
      version => 'dev',
    };
    my($out, $err, $exit) = capture { App::clad->new('--server')->run };
    is $exit, 0, 'returns 0';
  };

  subtest 'exit 22' => sub {
    plan tests => 1;
    generate_stdin {
      env     => {},
      command => [ $^X, -E => "exit 22" ],
      version => 'dev',
    };
    my($out, $err, $exit) = capture { App::clad->new('--server')->run };
    is $exit, 22, 'returns 22';
  };
  
  subtest 'kill 9' => sub {
    plan tests => 2;
    generate_stdin {
      env     => {},
      command => [ $^X, -E => "kill 9, \$\$" ],
      version => 'dev',
    };
    my($out, $err, $exit) = capture { App::clad->new('--server')->run };
    is $exit, 2, 'returns 2';
    note $err;
    like $err, qr{died with signal \d+ on myfakehostname};
  };

};

subtest 'io' => sub {
  plan tests => 3;

  generate_stdin {
    env => {},
    version => 'dev',
    command => [ $^X, -E => "say 'something to out'; say STDERR 'something to err'" ],
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 0, 'returns 0';
  like $out, qr{something to out}, 'out';
  like $err, qr{something to err}, 'err';
};

subtest 'env' => sub {
  plan tests => 2;

  generate_stdin {
    env => { FOO => 'bar' },
    version => 'dev',
    command => [ $^X, -E => 'say "env:FOO=$ENV{FOO}:"' ],
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 0, 'returns 0';
  like $out, qr{env:FOO=bar:}, 'environment passed';
};

subtest 'verbose' => sub {
  plan tests => 6;

  generate_stdin {
    verbose => 1,
    env     => { FOO => 1, BAR => 2 },
    command => [ $^X, -E => '' ],
    version => 'dev',
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 0, 'returns 0';
  my $data = Load($err);
  
  is $data->{command}->[1], '-E', 'command.1 = -E';
  is $data->{command}->[2], '', 'command.2 = ""';
  is $data->{env}->{FOO}, 1, 'env.FOO = 1';
  is $data->{env}->{BAR}, 2, 'env.BAR = 1';
  is $data->{verbose}, 1, 'verbose = 1';
  
  note $err;
};

subtest 'bad exe' => sub {

  generate_stdin {
    env => {},
    command => [ 'boguscommand', 'bogus arguments' ],
    version => 'dev',
  };
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{failed to execute on myfakehostname}, 'diagnostic';
};

subtest 'bad yaml' => sub {
  plan tests => 3;

  generate_stdin {
    env     => {},
    command => [ 'bogus' ],
    version => 'dev',
  };
  getc STDIN;
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';

  like $err, qr{Clad Server: unable to detect encoding.}, 'summary';
  like $err, qr{payload:}, 'payload header';

};

subtest 'no command' => sub {
  plan tests => 2;

  generate_stdin {
    version => 'dev',
  };
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{Clad Server: Unable to find command}, 'diagnostic';
};

subtest 'no command (2)' => sub {
  plan tests => 2;

  generate_stdin {
    command => [],
    version => 'dev',
  };
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{Clad Server: Unable to find command}, 'diagnostic';
};

subtest 'bad env' => sub {
  plan tests => 2;

  generate_stdin {
    env     => [],
    command => ['foo'],
    version => 'dev',
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{Clad Server: env is not hash}, 'diagnostic';

};

subtest 'client must send version' => sub {
  plan tests => 2;

  generate_stdin {
    command => ['foo'],
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{Clad Server: no client version}, 'diagnostic';
};

subtest 'server must check version (pass)' => sub {
  plan tests => 1;
  
  local $Clustericious::Admin::Server::VERSION = 1.00;
  
  generate_stdin {
    command => [$^X, -E => ''],
    version => 'dev',
    require => "0.22",
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 0, 'returns 0';
};

subtest 'server must check version (fail)' => sub {
  plan tests => 2;

  local $Clustericious::Admin::Server::VERSION = "1.00";
  
  generate_stdin {
    command => [$^X, -E => ''],
    version => 'dev',
    require => "2.00",
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  is $exit, 2, 'returns 2';
  like $err, qr{Clad Server: client requested version 2.00 but this is only 1.00}, 'diagnostic';
};

subtest 'pass file to server' => sub {
  plan tests => 5;

  local $Clustericious::Admin::Server::VERSION = "1.01";
  
  my $dir = dir( tempdir( CLEANUP => 1 ) );
  
  generate_stdin {
    command => [$^X, 
      '-MFile::Copy=cp', 
      '-MFile::Spec', 
      -E => "cp(\$ENV{FILE1}, File::Spec->catfile('$dir', 'text1.txt')) or die \"Copy failed: \$1\";"  .
            "cp(\$ENV{FILE2}, File::Spec->catfile('$dir', 'text2.txt')) or die \"Copy failed: \$1\";",
    ],
    require => '1.01',
    version => 'dev',
    files => [
      { name => 'text1.txt', content => 'text1', mode => '0644' },
      { name => 'text2.txt', content => 'text2', mode => '0755' },
    ],
  };
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  
  note "[out]\n$out" if $out;
  note "[err]\n$err" if $err;
  
  is $exit, 0, 'returns 0';
  is($dir->file('text1.txt')->slurp, 'text1', 'FILE1 content');
  is($dir->file('text2.txt')->slurp, 'text2', 'FILE2 content');
  SKIP: {
    skip 'File::Copy is too old', 2, unless $] >= 5.012;
    ok(! -x $dir->file('text1.txt'), 'FILE1 is NOT executable');
    ok(  -x $dir->file('text2.txt'), 'FILE2 IS executable');
  }
};

subtest 'pass file to server' => sub {
  plan tests => 5;

  local $Clustericious::Admin::Server::VERSION = "1.01";
  my $dir = dir( tempdir( CLEANUP => 1 ) );
  
  generate_stdin {
    command => [$^X, 
      '-MFile::Copy=cp', 
      '-MFile::Spec', 
      -E => "cp(\$ENV{ROGER}, File::Spec->catfile('$dir', 'text1.txt')) or die \"Copy failed: \$!\";"  .
            "cp(\$ENV{RAMJET}, File::Spec->catfile('$dir', 'text2.txt')) or die \"Copy failed: \$!\";",
    ],
    require => '1.01',
    version => 'dev',
    files => [
      { name => 'text1.txt', content => 'text1', mode => '0644', env => 'ROGER'  },
      { name => 'text2.txt', content => 'text2', mode => '0755', env => 'RAMJET' },
    ],
  };
  
  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  
  note "[out]\n$out" if $out;
  note "[err]\n$err" if $err;
  
  is $exit, 0, 'returns 0';
  is($dir->file('text1.txt')->slurp, 'text1', 'ROGER content');
  is($dir->file('text2.txt')->slurp, 'text2', 'RAMJET content');
  SKIP: {
    skip 'File::Copy is too old', 2, unless $] >= 5.012;
    ok(! -x $dir->file('text1.txt'), 'ROGER is NOT executable');
    ok(  -x $dir->file('text2.txt'), 'RAMJET IS executable');
  }

};

subtest 'pass dir to server' => sub {

  plan tests => 5;

  local $Clustericious::Admin::Server::VERSION = "1.02";
  my $dir = dir( tempdir( CLEANUP => 1 ) );

  generate_stdin {
    command => [$^X, 
      '-MFile::Copy=cp', 
      '-MFile::Spec', 
      -E => "cp(File::Spec->catfile(\$ENV{DIR}, 'subdir1', 'foo', 'text1.txt'), File::Spec->catfile('$dir', 'text1.txt')) or die \"Copy failed: \$!\";"  .
            "cp(File::Spec->catfile(\$ENV{DIR}, 'another', 'and', 'again', 'text2.txt'), File::Spec->catfile('$dir', 'text2.txt')) or die \"Copy failed: \$!\";",
    ],
    require => '1.02',
    version => 'dev',
    dir => {
      'subdir1' => { is_dir => 1, mode => '0700' },
      'subdir1/foo' => { is_dir => 1, mode => '0700' },
      'another' => { is_dir => 1 },
      'another/and' => { is_dir => 1 },
      'another/and/again' => { is_dir => 1 },
      
      'subdir1/foo/text1.txt' => { content => 'text1', mode => '0644' },
      'another/and/again/text2.txt' => { content => 'text2', mode => '0755' },
    },
  };

  my($out, $err, $exit) = capture { App::clad->new('--server')->run };
  
  note "[out]\n$out" if $out;
  note "[err]\n$err" if $err;
  
  is $exit, 0, 'returns 0';
  is($dir->file('text1.txt')->slurp, 'text1', 'ROGER content');
  is($dir->file('text2.txt')->slurp, 'text2', 'RAMJET content');
  SKIP: {
    skip 'File::Copy is too old', 2, unless $] >= 5.012;
    ok(! -x $dir->file('text1.txt'), 'ROGER is NOT executable');
    ok(  -x $dir->file('text2.txt'), 'RAMJET IS executable');
  }
};
