use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Git;
use lib 't/lib';
use Repo;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );
use Test2::Tools::URL;

my $build = alienfile_ok q{
  use alienfile;
  
  plugin 'Fetch::Git';
};

$build->load_requires('share');

my $example1 = example1();
note "example1 = $example1";

subtest 'fetch with tag' => sub {

  my $ret;
  my $error;
  note capture_merged {
    $ret = eval { $build->fetch("$example1#0.02") };
    $error = $@;
  };
  
  is $error, '';

  is(
    $ret,
    hash {
      field filename => 'example1';
      field path     => match(qr/example1/);
      field type     => 'file';
    },
  );
  
  is(
    path($ret->{path})->child('content.txt')->slurp,
    "This is version 0.02\n",
  );
    
};

subtest 'fetch without tag' => sub {

  my $ret;
  my $error;
  note capture_merged {
    $ret = eval { $build->fetch("$example1") };
    $error = $@;
  };
  
  is $error, '';

  my $url_check = Test2::Compare::Custom->new(
    name => 'UrlCheck',
    code => sub {
      # this seems to be different from the
      # documentation?
      my %args = @_;
      my $url = URI->new($args{got});
      return 0 unless $url->scheme eq 'file'
      &&              $url->host   eq 'localhost'
      &&              $url->path   eq $example1;
      1;
    },
  );

  is(
    $ret,
    hash {
      field type => 'list';
      field list => array {
        item hash {
          field filename => '0.01';
          field url      => url {
            url_component scheme   => 'file';
            url_component host     => 'localhost';
            url_component path     => $example1;
            url_component fragment => '0.01';
          };
        };
        item hash {
          field filename => '0.02';
          field url      => url {
            url_component scheme   => 'file';
            url_component host     => 'localhost';
            url_component path     => $example1;
            url_component fragment => '0.02';
          };
        };
        item hash {
          field filename => '0.03';
          field url      => url {
            url_component scheme   => 'file';
            url_component host     => 'localhost';
            url_component path     => $example1;
            url_component fragment => '0.03';
          };
        };
        end;
      };
    },
  );
};

done_testing
