use strict;
use warnings;

use Test::More;
use App::HTTPThis;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);

sub make_config {
  my ($contents) = @_;
  my $dir = tempdir(CLEANUP => 1);
  my $file = "$dir/http_thisrc";
  open my $fh, '>', $file or die "cannot create config '$file': $!";
  print {$fh} $contents;
  close $fh;
  return $file;
}

sub new_app {
  my (@argv) = @_;
  local @ARGV = @argv;
  my $orig = getcwd();
  my $tmp = tempdir(CLEANUP => 1);
  local $ENV{HOME} = $tmp;
  chdir $tmp or die "cannot chdir to '$tmp': $!";
  my $app = App::HTTPThis->new;
  chdir $orig or die "cannot chdir back to '$orig': $!";
  return $app;
}

subtest 'defaults host to localhost when unset' => sub {
  local $ENV{HTTP_THIS_CONFIG};
  my $app = new_app();
  is $app->{host}, '127.0.0.1', 'host defaults to localhost';
};

subtest 'reads host from config file' => sub {
  my $config = make_config("host=0.0.0.0\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  my $app = new_app();
  is $app->{host}, '0.0.0.0', 'host is read from config file';
};

subtest q{--config selects config file before loading defaults} => sub {
  my $env_config = make_config("host=0.0.0.0\n");
  my $cli_config = make_config("host=::1\n");
  local $ENV{HTTP_THIS_CONFIG} = $env_config;
  my $app = new_app(q{--config}, $cli_config);
  is $app->{host}, q{::1}, q{--config wins over HTTP_THIS_CONFIG};
};

subtest 'command line host overrides config host' => sub {
  my $config = make_config("host=0.0.0.0\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  my $app = new_app('--host', '::1');
  is $app->{host}, '::1', 'command line host wins over config host';
};

subtest '--all sets host to 0.0.0.0' => sub {
  local $ENV{HTTP_THIS_CONFIG};
  my $app = new_app('--all');
  is $app->{host}, '0.0.0.0', '--all binds to all interfaces';
};

subtest '--promiscuous sets host to 0.0.0.0' => sub {
  local $ENV{HTTP_THIS_CONFIG};
  my $app = new_app('--promiscuous');
  is $app->{host}, '0.0.0.0', '--promiscuous binds to all interfaces';
};

subtest 'config all=1 sets host to 0.0.0.0' => sub {
  my $config = make_config("all=1\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  my $app = new_app();
  is $app->{host}, '0.0.0.0', 'all=1 in config binds to all interfaces';
};

subtest q{config wsl=1 sets host to WSL address} => sub {
  my $config = make_config("wsl=1\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  no warnings q{redefine};
  local *App::HTTPThis::_wsl_addresses = sub {
    return qw(127.0.0.1 172.30.98.229);
  };
  my $app = new_app();
  is $app->{host}, q{172.30.98.229}, q{wsl=1 in config binds to WSL address};
};

subtest q{CLI --host overrides config wsl=1} => sub {
  my $config = make_config("wsl=1\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  no warnings q{redefine};
  local *App::HTTPThis::_wsl_addresses = sub {
    die q{should not resolve WSL address when --host is used};
  };
  my $app = new_app(q{--host}, q{127.0.0.1});
  is $app->{host}, q{127.0.0.1}, q{--host on CLI overrides config wsl=1};
};

subtest q{CLI --all overrides config wsl=1} => sub {
  my $config = make_config("wsl=1\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  no warnings q{redefine};
  local *App::HTTPThis::_wsl_addresses = sub {
    die q{should not resolve WSL address when --all is used};
  };
  my $app = new_app(q{--all});
  is $app->{host}, q{0.0.0.0}, q{--all on CLI overrides config wsl=1};
};

subtest 'CLI --host overrides config all=1' => sub {
  my $config = make_config("all=1\n");
  local $ENV{HTTP_THIS_CONFIG} = $config;
  my $app = new_app('--host', '127.0.0.1');
  is $app->{host}, '127.0.0.1', '--host on CLI overrides config all=1';
};

subtest '--wsl uses first non-loopback IPv4 address' => sub {
  local $ENV{HTTP_THIS_CONFIG};
  no warnings 'redefine';
  local *App::HTTPThis::_wsl_addresses = sub {
    return qw(::1 127.0.0.1 172.30.98.229 fe80::1 10.0.0.2);
  };
  my $app = new_app('--wsl');
  is $app->{host}, '172.30.98.229', '--wsl binds to the WSL IPv4 address';
};

subtest '--wsl dies when no usable IPv4 address is found' => sub {
  no warnings 'redefine';
  local *App::HTTPThis::_wsl_addresses = sub {
    return qw(::1 127.0.0.1 fe80::1);
  };
  my $app = bless {}, 'App::HTTPThis';
  eval { $app->_wsl_host };
  like $@, qr/non-loopback IPv4 address/,
    'reports that no WSL IPv4 address was found';
};

done_testing;
