use Test2::Bundle::Extended;
use Test::Clustericious::Config;

subtest exports => sub {

  imported_ok $_ for qw(
    create_config_ok
    create_directory_ok
    home_directory_ok
    create_config_helper_ok
  );
  
};

subtest create_config_ok => sub {

  use Clustericious::Config;

  my $r;
  
  is(
    intercept { $r = create_config_ok 'Foo' => { foo => 1 } },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr{^create config for Foo at .*/etc/Foo.conf$};
      };
      end;
    },
    'create_config_ok Foo, { foo => 1 }',
  );
  
  my $foo = Clustericious::Config->new('Foo');
  is $foo->foo, 1, 'foo.foo = 1';
  ok $r, "r = $r";

  is(
    intercept { $r = create_config_ok 'Bar' },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr{^create config for Bar at .*/etc/Bar.conf$};
      };
      end;
    },
    'create_config_ok Bar',
  );

  my $bar = Clustericious::Config->new('Bar');
  is $bar->bar, 1, 'bar.bar = 1';
  ok $r, "r = $r";

  is(
    intercept { $r = create_config_ok 'Baz' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'create config for Baz';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => 'unable to locate text for Baz';
      };
      end;
    },
    'create_config_ok Baz',
  );
  
  is $r, F(), "r is false";
  
  is(
    intercept { $r = create_config_ok 'Lomo' => "---\nlomo: 1" },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr{^create config for Lomo at .*/etc/Lomo.conf$};
      };
      end;
    },
    'create_config_ok Lomo, "..."',
  );

  my $lomo = Clustericious::Config->new('Lomo');
  is $lomo->lomo, 1, 'lomo.lomo = 1';
  ok $r, "r = $r";
  
};

subtest create_directory_ok => sub {

  use File::Glob qw( bsd_glob );
  use File::Spec;

  my $r;
  
  is(
    intercept { $r = create_directory_ok 'foo/bar/baz' },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr{^create directory .*/foo/bar/baz$};
      };
      end;
    },
    'create_directory_ok foo/bar/baz'
  );
  
  ok -d $r, "r = $r";
  
  my $expected = File::Spec->catfile(bsd_glob '~/foo/bar/baz');
  
  ok -d $expected, "expected = $expected";

  is(
    intercept { $r = create_directory_ok undef },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'create directory [undef]';
      };
      event Diag => sub {};
      end;
    },
    'create_directory_ok undef',
  );

};

subtest home_directory_ok => sub {

  my $r;
  
  is(
    intercept { $r = home_directory_ok },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr{^home directory };
      };
      end;
    },
    'home_directory_ok',
  );
  
  ok -d $r, "r = $r";

};

subtest create_config_helper_ok => sub {

  my $r;
  
  is(
    intercept { $r = create_config_helper_ok leaf => sub { 42 } },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'create config helper leaf';
      };
      end;
    },
    'create_config_helper_ok',
  );
  
  is $r, T(), "r = $r";
  
  create_config_ok 'Leaf';

  my $leaf = Clustericious::Config->new('Leaf');
  is $leaf->leaf, 42, 'leaf.leaf = 42';

};

done_testing;

__DATA__

@@ etc/Bar.conf
---
bar: 1


@@ etc/Leaf.conf
leaf: <%= leaf %>


