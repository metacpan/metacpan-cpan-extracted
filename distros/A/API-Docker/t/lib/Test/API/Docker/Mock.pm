package Test::API::Docker::Mock;
use strict;
use warnings;
use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny;
use Carp qw( croak );
use Test::More;

use Exporter 'import';
our @EXPORT = qw(
  test_docker
  load_fixture
  is_live
  can_write
  skip_unless_write
  check_live_access
  register_cleanup
);

my $FIXTURES_DIR = path(__FILE__)->parent->parent->parent->parent->parent->child('fixtures');

my @_cleanups;

sub load_fixture {
  my ($name) = @_;
  my $file = $FIXTURES_DIR->child("$name.json");
  croak "Fixture not found: $file" unless $file->exists;
  return decode_json($file->slurp_utf8);
}

sub is_live {
  return !!$ENV{API_DOCKER_TEST_HOST};
}

sub can_write {
  return is_live() && !!$ENV{API_DOCKER_TEST_WRITE};
}

sub skip_unless_write {
  if (is_live() && !can_write()) {
    plan skip_all => 'Write tests skipped (set API_DOCKER_TEST_WRITE=1 to enable)';
  }
}

sub check_live_access {
  return unless is_live();

  my $host = $ENV{API_DOCKER_TEST_HOST};
  if ($host =~ m{^unix://(.+)$}) {
    unless (-S $1) {
      plan skip_all => "Docker socket $1 not available";
    }
  }

  eval {
    require API::Docker;
    my $docker = API::Docker->new(host => $host);
    my $result = $docker->system->ping;
    die "ping failed" unless $result eq 'OK';
  };
  if ($@) {
    plan skip_all => "Docker daemon not reachable at $host: $@";
  }
}

sub register_cleanup {
  my ($code) = @_;
  push @_cleanups, $code;
}

sub _run_cleanups {
  for my $cleanup (reverse @_cleanups) {
    eval { $cleanup->() };
    warn "Cleanup failed: $@" if $@;
  }
  @_cleanups = ();
}

sub test_docker {
  my (%routes) = @_;

  if (is_live()) {
    require API::Docker;
    return API::Docker->new(host => $ENV{API_DOCKER_TEST_HOST});
  }

  return _mock_docker(%routes);
}

sub _mock_docker {
  my (%routes) = @_;

  unless (grep { /version/ } keys %routes) {
    $routes{'GET /version'} = load_fixture('system_version');
  }

  require API::Docker;

  my $docker = API::Docker->new(
    host        => 'unix:///var/run/docker.sock',
    api_version => '1.47',
  );

  my $mock_request = sub {
    my ($self, $method, $path, %opts) = @_;

    my $clean_path = $path;
    $clean_path =~ s{^/v[\d.]+}{};

    my $key = "$method $clean_path";

    if (exists $routes{$key}) {
      my $handler = $routes{$key};
      if (ref $handler eq 'CODE') {
        return $handler->($method, $clean_path, %opts);
      }
      return $handler;
    }

    for my $pattern (keys %routes) {
      my ($route_method, $route_path) = split /\s+/, $pattern, 2;
      next unless $method eq $route_method;
      if ($clean_path =~ m{^$route_path$}) {
        my $handler = $routes{$pattern};
        if (ref $handler eq 'CODE') {
          return $handler->($method, $clean_path, %opts);
        }
        return $handler;
      }
    }

    croak "No mock route for: $key (available: " . join(', ', sort keys %routes) . ")";
  };

  my $mock_pkg = "API::Docker::Mock::" . int(rand(1_000_000));
  {
    no strict 'refs';
    @{"${mock_pkg}::ISA"} = ('API::Docker');
    *{"${mock_pkg}::_request"} = $mock_request;
  }

  bless $docker, $mock_pkg;
  return $docker;
}

END { _run_cleanups() }

1;
