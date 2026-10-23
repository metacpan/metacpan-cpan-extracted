use strict;
use warnings;
use Test::Most;
use Test::Exception;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();

use App::Actions::Workflow;

my $json = JSON::PP->new->canonical;

sub load_workflow {
    my ($yaml) = @_;

    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'workflow.yml');
    open my $handle, '>', $path or die $!;
    print {$handle} $yaml;
    close $handle;

    return App::Actions::Workflow->load($path);
}

my $workflow = load_workflow(<<'YAML');
name: Test workflow
on: push
env:
  GLOBAL: yes
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        perl: ['5.38', '5.40']
        exclude:
          - os: windows-latest
            perl: '5.40'
        include:
          - color: green
          - color: pink
            os: windows-latest
          - os: ubuntu-latest
            shape: circle
          - perl: '5.42'
          - perl: '5.42'
            os: ubuntu-latest
    name: Perl ${{ matrix.perl }} on ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Perl
        uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: ${{ matrix.perl }}
      - run: echo hello
YAML

is($workflow->name, 'Test workflow', 'workflow name');
is($workflow->env->{GLOBAL}, 'yes', 'workflow env');

my $jobs = $workflow->expand_jobs;
is(scalar @$jobs, 5, 'matrix combinations after exclude and include');

my %combinations = map {
    my $matrix = $_->{matrix};
    $json->encode($matrix) => 1;
} @$jobs;

ok($combinations{ $json->encode({ os => 'ubuntu-latest', perl => '5.38', color => 'green', shape => 'circle' }) },
    'include values are merged into matching original combinations');
ok($combinations{ $json->encode({ os => 'ubuntu-latest', perl => '5.40', color => 'green', shape => 'circle' }) },
    'exclude removed only the matching combination');
ok($combinations{ $json->encode({ os => 'windows-latest', perl => '5.38', color => 'pink' }) },
    'later include can replace an earlier include value');
ok($combinations{ $json->encode({ perl => '5.42' }) },
    'include that cannot merge creates a new combination');
ok($combinations{ $json->encode({ perl => '5.42', os => 'ubuntu-latest' }) },
    'second include-only combination is kept separate');

my ($first) = grep { $_->{matrix}{perl} eq '5.38' && $_->{matrix}{os} eq 'ubuntu-latest' } @$jobs;
is($first->{display_name}, 'Perl 5.38 on ubuntu-latest', 'display name interpolation');
is($first->{setup_perl_version}, '5.38', 'setup-perl version from matrix');
is($workflow->container_image($first, 'ubuntu-latest', 'ubuntu:latest', 'perl:%s'),
    'perl:5.38', 'setup-perl selects a Perl image');

my $container_workflow = load_workflow(<<'YAML');
name: Container
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: perldocker/perl-tester:${{ matrix.perl }}
    strategy:
      matrix:
        perl: ['5.36', '5.38']
    steps:
      - run: perl -V
YAML

my $container_jobs = $container_workflow->expand_jobs;
is($container_workflow->container_image($container_jobs->[0], 'ubuntu-latest', 'ubuntu:latest', 'perl:%s'),
    'perldocker/perl-tester:5.36', 'container image takes precedence');

my $default_workflow = load_workflow(<<'YAML');
name: Default image
on: push
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - run: echo hello
YAML

my $default_jobs = $default_workflow->expand_jobs;
is($default_workflow->container_image($default_jobs->[0], 'ubuntu-24.04', 'ubuntu:latest', 'perl:%s'),
    'ubuntu:24.04', 'runs-on selects the matching Ubuntu image');

my $windows_workflow = load_workflow(<<'YAML');
name: Windows
on: push
jobs:
  test:
    runs-on: windows-latest
    steps:
      - run: echo hello
YAML

my $windows_jobs = $windows_workflow->expand_jobs;
ok(!$windows_workflow->is_linux_runner(
    $windows_workflow->runs_on_text($windows_jobs->[0]{'runs-on'}, {}),
), 'Windows runner is not Linux');

my $macos_workflow = load_workflow(<<'YAML');
name: macOS
on: push
jobs:
  test:
    runs-on: [self-hosted, macos]
    steps:
      - run: echo hello
YAML

my $macos_jobs = $macos_workflow->expand_jobs;
ok(!$macos_workflow->is_linux_runner(
    $macos_workflow->runs_on_text($macos_jobs->[0]{'runs-on'}, {}),
), 'macOS runner is not Linux');

my $only_include = load_workflow(<<'YAML');
name: Include only
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - perl: '5.38'
            os: ubuntu-latest
          - perl: '5.40'
            os: ubuntu-latest
    steps:
      - run: echo hello
YAML

my $include_jobs = $only_include->expand_jobs;
is(scalar @$include_jobs, 2, 'include-only matrix produces one job per include entry');

my $needs_workflow = load_workflow(<<'YAML');
name: Needs
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo build
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo test
YAML

my $needs_job = $needs_workflow->job_by_id('test');
is_deeply($needs_job->{needs}, ['build'], 'scalar needs is normalized to a list');

throws_ok {
    load_workflow("name: Bad\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps: not-a-list\n");
} qr/no 'steps' list/, 'missing steps list is rejected';

throws_ok {
    load_workflow("name: Bad\non: push\n");
} qr/no 'jobs' mapping/, 'missing jobs is rejected';

done_testing;
