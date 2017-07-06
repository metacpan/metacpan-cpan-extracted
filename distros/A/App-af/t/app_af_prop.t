use Test2::V0;
use App::af;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest;
use YAML qw( Load );
do './bin/af';

subtest 'yaml' => sub {

  run('prop', -c => 'foo');
  
  is last_exit, 0, 'exit';
  
  my $prop = eval { Load(last_stdout) };
  
  is $@, '', 'proper yaml';
  
  is(
    $prop,
    hash {
      field arbitrary => 'one';
      field legacy => hash {
        field install_type => 'share';
        etc;
      };
      etc;
    },
  );
};

subtest '--class' => sub {

  run('prop', '--class'  => 'foo');
  
  is last_exit, 0, 'exit';
  
  my $prop = eval { Load(last_stdout) };
  
  is $@, '', 'proper yaml';
  
  is(
    $prop,
    hash {
      field arbitrary => 'one';
      field legacy => hash {
        field install_type => 'share';
        etc;
      };
      etc;
    },
  );
};

subtest '--cflags' => sub {

  run('prop', -c => 'foo', '--cflags');
  
  is last_exit, 0, 'exit';
  
  is last_stdout, "-DFOO=1\n";
};

subtest '--cflags --static' => sub {

  run('prop', -c => 'foo', '--cflags', '--static');
  
  is last_exit, 0, 'exit';
  
  is last_stdout, "-DFOO=1 -DFOO_STATIC=1\n";
};

subtest '--libs' => sub {

  run('prop', -c => 'foo', '--libs');
  
  is last_exit, 0, 'exit';
  
  is last_stdout, "-lfoo\n";
};

subtest '--libs --static' => sub {

  run('prop', -c => 'foo', '--libs', '--static');
  
  is last_exit, 0, 'exit';
  
  is last_stdout, "-lfoo -lbar -lbaz\n";
};

subtest '--modversion' => sub {
  run('prop', -c => 'foo', '--modversion');
  
  is last_exit, 0, 'exit';
  
  is last_stdout, "1.2.3\n";
};

subtest '--bin-dir' => sub {
  run('prop', -c => 'foo', '--bin-dir');
  
  is last_exit, 0, 'exit';
  
  my($dir) = split /\n/, last_stdout;
  
  ok( -d $dir, "directory exists" );
  note "dir = $dir";
  ok( -f "$dir/foo", "directory has foo executable" );
};

done_testing;
