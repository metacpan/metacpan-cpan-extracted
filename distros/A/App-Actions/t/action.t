use strict;
use warnings;
use Test::Most;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use App::Actions::Action;

sub write_file {
    my ($dir, $name, $contents) = @_;

    make_path($dir);
    my $file = File::Spec->catfile($dir, $name);
    open my $handle, '>', $file or die $!;
    print {$handle} $contents;
    close $handle;

    return $file;
}

my $root = tempdir(CLEANUP => 1);

my $composite_dir = File::Spec->catdir($root, 'greet');
write_file($composite_dir, 'action.yml', <<'YAML');
name: Greet
description: Say hello
inputs:
  who:
    description: Who to greet
    default: world
  token:
    required: true
outputs:
  greeting:
    description: The greeting
    value: ${{ steps.say.outputs.message }}
runs:
  using: composite
  steps:
    - id: say
      name: Say hello
      shell: sh
      env:
        GREETING: hi
      run: echo "$GREETING ${{ inputs.who }}"
YAML

my $composite = App::Actions::Action->load_from_dir($composite_dir);
isa_ok($composite, 'App::Actions::Action');
is($composite->kind, 'composite', 'composite actions are recognised');
is($composite->name, 'Greet', 'the action name is read');
is($composite->using, 'composite', 'runs.using is exposed');
ok($composite->is_composite, 'is_composite returns true');
ok(!$composite->is_javascript, 'is_javascript returns false');

is($composite->inputs->{who}{default}, 'world', 'input defaults are read');
ok(!$composite->inputs->{who}{required}, 'optional inputs are marked optional');
ok($composite->inputs->{token}{required}, 'required inputs are marked required');
is($composite->outputs->{greeting}{value}, '${{ steps.say.outputs.message }}',
    'composite outputs are read');

is(scalar @{ $composite->steps }, 1, 'composite steps are read');
is($composite->steps->[0]{id}, 'say', 'step ids survive');
is($composite->steps->[0]{shell}, 'sh', 'step shells survive');
is($composite->steps->[0]{env}{GREETING}, 'hi', 'step env survives');

# action.yaml is the fallback name.
my $yaml_dir = File::Spec->catdir($root, 'fallback');
write_file($yaml_dir, 'action.yaml', <<'YAML');
name: Fallback
runs:
  using: composite
  steps:
    - run: echo hi
      shell: sh
YAML

my $fallback = App::Actions::Action->load_from_dir($yaml_dir);
is($fallback->kind, 'composite', 'action.yaml is accepted');
is($fallback->inputs->{'nope'}, undef, 'undeclared inputs are absent');

my $js_dir = File::Spec->catdir($root, 'js');
write_file($js_dir, 'action.yml', <<'YAML');
name: JavaScript
inputs:
  name:
    default: default-name
runs:
  using: node20
  main: dist/index.js
  pre: dist/pre.js
  post: dist/post.js
  post-if: always()
YAML

my $js = App::Actions::Action->load_from_dir($js_dir);
is($js->kind, 'javascript', 'JavaScript actions are recognised');
ok($js->is_javascript, 'is_javascript returns true');
is($js->runs->{main}, 'dist/index.js', 'runs.main is read');
is($js->runs->{pre}, 'dist/pre.js', 'runs.pre is read');
is($js->runs->{post}, 'dist/post.js', 'runs.post is read');
is($js->runs->{'post-if'}, 'always()', 'runs.post-if is read');
is($js->inputs->{name}{default}, 'default-name', 'JavaScript inputs are read');

throws_ok { App::Actions::Action->load_from_dir(File::Spec->catdir($root, 'absent')) }
    qr/does not exist/, 'a missing action directory is reported';

my $empty_dir = File::Spec->catdir($root, 'empty');
make_path($empty_dir);
throws_ok { App::Actions::Action->load_from_dir($empty_dir) }
    qr/No action\.yml or action\.yaml/, 'missing metadata is reported';

my $no_runs = write_file(File::Spec->catdir($root, 'no-runs'), 'action.yml', <<'YAML');
name: Broken
YAML
throws_ok { App::Actions::Action->load($no_runs) }
    qr/has no 'runs' mapping/, 'metadata without runs is rejected';

my $no_using = write_file(File::Spec->catdir($root, 'no-using'), 'action.yml', <<'YAML');
runs:
  main: index.js
YAML
throws_ok { App::Actions::Action->load($no_using) }
    qr/has no 'runs\.using'/, 'metadata without runs.using is rejected';

my $no_steps = write_file(File::Spec->catdir($root, 'no-steps'), 'action.yml', <<'YAML');
runs:
  using: composite
YAML
throws_ok { App::Actions::Action->load($no_steps) }
    qr/has no 'runs\.steps'/, 'composite actions need steps';

my $no_main = write_file(File::Spec->catdir($root, 'no-main'), 'action.yml', <<'YAML');
runs:
  using: node20
YAML
throws_ok { App::Actions::Action->load($no_main) }
    qr/has no 'runs\.main'/, 'JavaScript actions need a main entry point';

my $bad_step = write_file(File::Spec->catdir($root, 'bad-step'), 'action.yml', <<'YAML');
runs:
  using: composite
  steps:
    - name: Nothing
YAML
throws_ok { App::Actions::Action->load($bad_step) }
    qr/neither 'run' nor 'uses'/, 'composite steps need run or uses';

my $docker = write_file(File::Spec->catdir($root, 'docker'), 'action.yml', <<'YAML');
runs:
  using: docker
  image: Dockerfile
YAML
is(App::Actions::Action->load($docker)->kind, 'docker', 'Docker actions are identified');

# A metadata file named without a directory is in the current directory;
# its directory used to be reported as the file name itself.
{
    my $here = File::Spec->catdir($root, 'here');
    write_file($here, 'action.yml', "runs:\n  using: composite\n  steps:\n    - run: echo hi\n");
    require Cwd;
    my $cwd = Cwd::getcwd();
    chdir $here or die "$here: $!";
    my $action = eval { App::Actions::Action->load('action.yml') };
    chdir $cwd or die "$cwd: $!";
    is($action && $action->dir, '.', 'a bare metadata file name is in the current directory');
}

# required: is read for its truth, so a JSON or YAML false is not required.
{
    my $flags = write_file(File::Spec->catdir($root, 'flags'), 'action.yml', <<'YAML');
inputs:
  yes_word: { required: yes }
  false_word: { required: false }
  off: { required: 0 }
runs:
  using: node20
  main: index.js
YAML
    my $inputs = App::Actions::Action->load($flags)->inputs;
    is($inputs->{yes_word}{required}, 1, 'required: yes is required');
    is($inputs->{false_word}{required}, 0, 'required: false is not required');
    is($inputs->{off}{required}, 0, 'required: 0 is not required');
}

throws_ok { App::Actions::Action->load_from_dir(undef) } qr/No action directory given/,
    'no directory is reported';
throws_ok { App::Actions::Action->load(File::Spec->catfile($root, 'absent.yml')) }
    qr/Action metadata file '.*absent\.yml' does not exist/, 'a missing metadata file is reported';

done_testing;
