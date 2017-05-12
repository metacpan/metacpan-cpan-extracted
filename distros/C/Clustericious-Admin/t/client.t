use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 14;
use App::clad;
use File::HomeDir;
use Path::Class qw( dir file );
use Clustericious::Config;
use Capture::Tiny qw( capture );
use File::Temp qw( tempdir );

unshift @INC, sub {
  my(undef, $filename) = @_;
  die "do not use ConfigData.pm" if $filename eq 'Clustericious/Admin/ConfigData.pm';
  return;
};

my $dist_root = file( __FILE__)->parent->parent->absolute;

note "dist_root = $dist_root";

create_config_ok Clad => {
  env => {},
  cluster => {
    cluster1 => [ qw( host1 host2 host3 ) ],
    cluster2 => [ qw( host4 host5 host6 ) ],
    cluster3 => [ qw( host1 ) ],
  },
  server_command => 
    "$^X @{[ $dist_root->file('corpus', 'fake-server.pl') ]} --server",
  ssh_command =>
    [ $^X, $dist_root->file('corpus', 'fake-ssh.pl')->stringify ],
  ssh_options =>
    [ -o => "Foo=yes", -o => "Bar=no" ],
  script => {
    myscript =>
      qq{#!$^X
        use strict;
        use warnings;
        use 5.010;
        say STDOUT "+output";
        say STDERR "+error";
      },
  },
};

subtest basic => sub {
  plan tests => 7;

  my($out, $err, $exit) = capture {
    App::clad->new(
      'cluster1', 
      $^X, -E => 'say "host=$ENV{CLAD_HOST}"; say "cluster=$ENV{CLAD_CLUSTER}"',
    )->run;
  };
  
  is $exit, 0, 'exit = 0';
  my %out = map { $_ => 1 }split /\n/, $out;
  
  for(1..3)
  {
    ok $out{"[host$_ out ] cluster=cluster1"}, "host $_ cluster 1";
    ok $out{"[host$_ out ] host=host$_"},      "host $_ host $_";
  }
  
};

subtest 'basic single host cluster' => sub {
  plan tests => 3;

  my($out, $err, $exit) = capture {
    App::clad->new(
      'host7', 
      $^X, -E => 'say "host=$ENV{CLAD_HOST}"; say "cluster=$ENV{CLAD_CLUSTER}"',
    )->run;
  };
  
  is $exit, 0, 'exit = 0';
  my %out = map { $_ => 1 }split /\n/, $out;
  
  ok $out{"[host7 out ] cluster=host7"},    "host 7 host7";
  ok $out{"[host7 out ] host=host7"},       "host 7 host7";  
};

subtest 'basic with deprecated api' => sub {
  plan tests => 8;
  
  require_ok 'Clustericious::Admin';

  my($out, $err, $exit) = capture {
    Clustericious::Admin->run(
      {}, 'cluster1',
      $^X, -E => 'say "host=$ENV{CLAD_HOST}"; say "cluster=$ENV{CLAD_CLUSTER}"',
    );
  };
  
  is $exit, 0, 'exit = 0';
  my %out = map { $_ => 1 }split /\n/, $out;
  
  for(1..3)
  {
    ok $out{"[host$_ out ] cluster=cluster1"}, "host $_ cluster 1";
    ok $out{"[host$_ out ] host=host$_"},      "host $_ host $_";
  }
};

subtest 'with specified user' => sub {
  plan tests => 4;

  my($out, $err, $exit) = capture {
    App::clad->new(
      -l => 'foo',
      'cluster1', 
      $^X, -E => 'say "user=$ENV{USER}"',
    )->run;
  };
  
  is $exit, 0, 'exit = 0';
  
  my %out = map { $_ => 1 }split /\n/, $out;
  
  for(1..3)
  {
    ok $out{"[foo\@host$_ out ] user=foo"}, "host $_";
  }
};

subtest 'with two users' => sub {
  plan tests => 7;

  my($out, $err, $exit) = capture {
    App::clad->new(
      'foo@cluster1,bar@cluster2', 
      $^X, -E => 'say "user=$ENV{USER}"',
    )->run;
  };

  is $exit, 0, 'exit = 0';
  my %out = map { $_ => 1 }split /\n/, $out;

  for(1..3)
  {
    ok $out{"[foo\@host$_ out ] user=foo"}, "host $_";
  }
  for(4..6)
  {
    ok $out{"[bar\@host$_ out ] user=bar"}, "host $_";
  }
};

subtest 'failure' => sub {

  my($out, $err, $exit) = capture {
    App::clad->new(
      'cluster1',
      $^X, -E => 'exit 22',
    )->run;
  };
  
  is $exit, 2, 'exit = 2';
  
  my %out = map { $_ => 1 }split /\n/, $out;

  for(1..3)
  {
    ok $out{"[host$_ exit] 22"}, "host $_";
  }

};

subtest 'with files' => sub {
  my $file1 = file( tempdir( CLEANUP => 1 ), 'text1.txt' );
  my $file2 = file( tempdir( CLEANUP => 1 ), 'text2.txt' );
  
  $file1->spew('text1');
  $file2->spew('text2');

  my $dir = dir( tempdir( CLEANUP => 1 ) );

  my($out, $err, $exit) = capture {
    App::clad->new(
      '--file' => $file1,
      '--file' => $file2,
      'cluster3', 
      $^X,
      '-MFile::Copy=cp',
      '-MFile::Spec',
      -E => 
            "cp(\$ENV{FILE1}, File::Spec->catfile('$dir', 'text1.txt')) or die \"Copy failed: \$1\";" .
            "cp(\$ENV{FILE2}, File::Spec->catfile('$dir', 'text2.txt')) or die \"Copy failed: \$1\";",
    )->run;
  };

  note "[out]\n$out" if $out;
  note "[err]\n$err" if $err;
  is $exit, 0, 'exit = 0';
  is($dir->file('text1.txt')->slurp, 'text1', 'FILE1 content');
  is($dir->file('text2.txt')->slurp, 'text2', 'FILE2 content');  
};

subtest myscript => sub {
  plan tests => 7;

  my($out, $err, $exit) = capture {
    App::clad->new(
      'cluster1', 'myscript',
    )->run;
  };
  
  is $exit, 0, 'exit = 0';
  my %out = map { $_ => 1 }split /\n/, $out;
  
  for(1..3)
  {
    ok $out{"[host$_ out ] +output"}, "host $_ output";
    ok $out{"[host$_ err ] +error"},  "host $_ error";
  }
  
};

subtest '--dir' => sub {
  plan tests => 2;

  my $dir = file(__FILE__)->parent->parent->subdir('corpus')->subdir('dir')->absolute;
  
  ok -d "$dir", "dir = $dir";

  my($out, $err, $exit) = capture {
    App::clad->new(
      '--dir' => "$dir",
      'cluster3',
      $^X,
      -E => '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
        use strict;
        use warnings;
        #system 'ls', '-laR', $ENV{DIR};
        die "no 1.txt" unless -r "1.txt" && -s "1.txt" == 2;
        die "no sub1/2.txt" unless -r "$ENV{DIR}/sub1/2.txt" && (-s "$ENV{DIR}/sub1/2.txt") == 2;
        die "no sub1/sub2/3.txt" unless -r "$ENV{DIR}/sub1/sub2/3.txt" && -s "$ENV{DIR}/sub1/sub2/3.txt" == 2;
        die "no sub1/sub2/sub3/4.txt" unless -r "$ENV{DIR}/sub1/sub2/sub3/4.txt" && -s "$ENV{DIR}/sub1/sub2/sub3/4.txt" == 2;
        die "we did get sub1/.hidden/bogus.txt" if -e "$ENV{DIR}/sub1/.hidden/bogus.txt";
      },
    )->run;
  };
  
  is $exit, 0, 'exit = 0';
  diag "[out]\n$out" if $out;
  diag "[err]\n$err" if $err;
};

subtest 'stdin' => sub {
  plan skip_all => 'borked';

  open STDIN, '<', \"sometext";
  
  my($out, $err, $exit) = capture {
    App::clad->new(
      '--verbose',
      'cluster3',
      $^X,
      -E => '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
        use strict;
        use warnings;
        my $data = do { local $/; <STDIN> };
        die "data does not match: $data" unless $data eq 'sometext';
        print STDOUT scalar reverse $data;
      },
    )->run;
  };
  
  close STDIN;
  
  is $exit, 0, 'exit = 0';
  diag "[out]\n$out" if $out;
  diag "[err]\n$err" if $err;

};

subtest 'summary' => sub {

  my($out, $err, $exit) = capture {
  
    App::clad->new(
      '--summary',
      'cluster1',
      $^X,
      -E => '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
        use strict;
        use warnings;
        say "should not see stdout";
        say "should not see stderr";
        exit 2 if $ENV{CLAD_HOST} eq 'host2';
      },
    )->run;
  };

  is $exit, 2, 'exit = 2';
  
  unlike $out, qr{should not see stdout}, 'do not print stdout';
  unlike $out, qr{should not see stderr}, 'do not print stderr';
  
  is_deeply 
    [sort split /\r?\n/, $out], 
    [sort ('[host1 exit] 0', '[host2 exit] 2','[host3 exit] 0')],
    'printed exit values';

};

subtest 'log' => sub {

  my $dir = dir( tempdir( CLEANUP => 1 ) );
  
  my($out, $err, $exit) = capture {
  
    App::clad->new(
      '--log-dir' => "$dir",
      'cluster1',
      $^X,
      -E => '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
        use strict;
        use warnings;
        say "test output";
        say STDERR "test error";
      },
    )->run;
  
  };
  
  is $exit, 0, 'exit = 0';

  ok -f $dir->file('host1.log'), 'exists host1.log';
  ok -f $dir->file('host2.log'), 'exists host2.log';
  ok -f $dir->file('host3.log'), 'exists host3.log';

  ok( 
    (scalar grep /^\[err \] test error$/, $dir->file('host1.log')->slurp),
    'has error'
  );

  ok( 
    (scalar grep /^\[out \] test output$/, $dir->file('host1.log')->slurp),
    'has error'
  );

};

pass 'good';
