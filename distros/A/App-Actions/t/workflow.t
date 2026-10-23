use strict;
use warnings;
use Test::Most;
use Test::Exception;
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Expression;
use App::Actions::Workflow;

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
name: Full workflow
on: push
env:
  WORKFLOW_ENV: yes
defaults:
  run:
    shell: bash
    working-directory: src
jobs:
  first:
    runs-on: ubuntu-latest
    container: alpine:3.20
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: secret
        ports:
          - 5432:5432
        volumes:
          - data:/var/lib/postgresql/data
        options: --health-cmd pg_isready
    defaults:
      run:
        shell: sh
    env:
      JOB_ENV: job
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Build
        run: make
        env:
          STEP_ENV: step
        working-directory: .
        shell: bash
  second:
    needs: [first]
    runs-on: [self-hosted, linux]
    steps:
      - run: echo second
YAML

is_deeply([ map { $_->{id} } @{ $workflow->jobs } ], [qw(first second)],
    'jobs keep their file order');

my $first = $workflow->job_by_id('first');
is_deeply($first->{container}, { image => 'alpine:3.20' },
    'scalar container is normalized');
is($first->{defaults}{run}{shell}, 'sh', 'job defaults are kept');
is($workflow->defaults->{run}{shell}, 'bash', 'workflow defaults are kept');
is($first->{env}{JOB_ENV}, 'job', 'job env is kept');
is($first->{steps}[0]{with}{'fetch-depth'}, 0, 'with values are kept');
is($first->{steps}[1]{env}{STEP_ENV}, 'step', 'step env is kept');
is($first->{steps}[1]{shell}, 'bash', 'step shell is kept');
is($first->{steps}[1]{'working-directory'}, '.', 'step working directory is kept');

my $postgres = $first->{services}{postgres};
is($postgres->{image}, 'postgres:16', 'service image');
is($postgres->{env}{POSTGRES_PASSWORD}, 'secret', 'service env');
is_deeply($postgres->{ports}, ['5432:5432'], 'service ports');

is($workflow->runs_on_text($first->{'runs-on'}, {}), 'ubuntu-latest',
    'runs-on text');
is($workflow->runs_on_text($workflow->job_by_id('second')->{'runs-on'}, {}),
    'self-hosted linux', 'array runs-on text');

ok($workflow->is_linux_runner('ubuntu-latest'), 'ubuntu is Linux');
ok($workflow->is_linux_runner('self-hosted linux'), 'self-hosted Linux is Linux');
ok(!$workflow->is_linux_runner('macos-latest'), 'macOS is not Linux');
ok(!$workflow->is_linux_runner('windows-2022'), 'Windows is not Linux');

is($workflow->default_image_for_runner('ubuntu-latest', 'fallback'), 'ubuntu:latest',
    'ubuntu-latest image');
is($workflow->default_image_for_runner('ubuntu-22.04', 'fallback'), 'ubuntu:22.04',
    'versioned Ubuntu image');
is($workflow->default_image_for_runner('self-hosted', 'fallback'), 'fallback',
    'self-hosted uses the fallback');

is($workflow->perl_image_for_version('5.38', 'perl:%s'), 'perl:5.38', 'Perl image');
is($workflow->perl_image_for_version('dev', 'perl:%s'), 'perl:latest', 'dev Perl image');
is($workflow->perl_image_for_version(undef, 'perl:%s'), 'perl:latest', 'missing Perl image');

my $unnamed = load_workflow(<<'YAML');
name: Unnamed jobs
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        perl: ['5.38', '5.40']
    steps:
      - run: echo hello
YAML

my $unnamed_jobs = $unnamed->expand_jobs;
is($unnamed_jobs->[0]{display_name}, 'test (perl=5.38)',
    'default display name includes matrix values');

throws_ok {
    load_workflow("name: Bad\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - name: nothing\n");
} qr/neither 'run' nor 'uses'/, 'step without run or uses is rejected';

throws_ok {
    load_workflow("name: Bad\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    env: nope\n    steps:\n      - run: echo\n");
} qr/env .* must be a mapping/, 'invalid env is rejected';

throws_ok {
    load_workflow("name: Bad\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    container: [a, b]\n    steps:\n      - run: echo\n");
} qr/container must be a mapping or a string/, 'invalid container is rejected';

throws_ok {
    load_workflow("name: Bad\non: push\njobs: [not, a, mapping]\n");
} qr/no 'jobs' mapping/, 'invalid jobs is rejected';

# Boolean matrix values are YAML booleans, which on Perl 5.36 and later are
# core booleans; they used to be written as 1 and the empty string, so a step
# saw "debug=" where GitHub gives "debug=false".
SKIP: {
    skip 'core booleans need Perl 5.36', 3 if $] < 5.036;

    my $booleans = load_workflow(<<'YAML');
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        debug: [true, false]
    steps:
      - run: echo "debug=${{ matrix.debug }}"
YAML
    my $jobs = $booleans->expand_jobs;
    is_deeply([ map { $_->{display_name} } @$jobs ], [ 'test (debug=true)', 'test (debug=false)' ],
        'boolean matrix values are named true and false');
    my $expression = App::Actions::Expression->new;
    is($expression->interpolate($jobs->[1]{steps}[0]{run}, { matrix => $jobs->[1]{matrix} }),
        'echo "debug=false"', 'a false matrix value interpolates as false');
    ok($expression->condition('matrix.debug == false', { matrix => $jobs->[1]{matrix} }),
        'a false matrix value equals the literal false');
}

throws_ok {
    load_workflow("jobs:\n  test:\n    runs-on: ubuntu-latest\n    strategy:\n      matrix:\n        perl: []\n    steps:\n      - run: echo\n")->expand_jobs;
} qr/Matrix key 'perl' must be a list with at least one value/, 'an empty matrix dimension says what is wrong';

is($workflow->perl_image_for_version('5.38', 'reg.example/100%/perl:%s'), 'reg.example/100%/perl:5.38',
    'a literal % in the image template is kept');
is($workflow->perl_image_for_version('5.38', 'perl:%s-%s'), 'perl:5.38-5.38',
    'every %s in the template is replaced, without a sprintf warning');
is($workflow->perl_image_for_version('DEV'), 'perl:latest', 'dev means latest whatever its case');

my @none = $workflow->job_by_id('no-such-job');
is_deeply(\@none, [ undef ], 'job_by_id returns one undef for a missing job, also in list context');

throws_ok { $workflow->runs_on_text({ group => 'big' }) } qr/'runs-on' must be a string or a list/,
    'a runner group is refused with a sentence';
throws_ok { $workflow->container_image('not a job') } qr/Invalid arguments to App::Actions::Workflow::container_image/,
    'container_image refuses a job that is not a hash';

done_testing;
