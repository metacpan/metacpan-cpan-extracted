#!/usr/bin/perl

# Tests the MERGE directive, which merges the data of a fragment into a
# structured configuration file (JSON, TOML, YAML or INI).

use strict;
use warnings;

use Test2::V0;

use English;
use File::Spec::Functions 'catfile';
use JSON::PP ();
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest;

our $VERSION = 0.01;

# Skips the current subtest if the given module is not installed, as the
# program would otherwise try to install it.
sub need_module {
  my ($module) = @_;
  skip_all("${module} is not installed") if not eval "require ${module}; 1";  ## no critic (ProhibitStringyEval)
  return;
}

# Returns the data of a TOML file in the home directory of the sandbox.
sub read_toml {
  my ($t, $path) = @_;
  my ($data, $error) = TOML::Tiny::from_toml($t->read_home_file($path));
  die "${error}\n" if $error;
  return $data;
}

subtest 'TOML: merged with the existing content' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.toml',
    qq{# comment\ntheme = "dark"\n[editor]\nfont = "mono"\n[[plugin]]\nname = "a"\n});
  $t->add_fragment('app',
    qq{FILENAME app.toml\nMERGE toml\n\n[editor]\nsize = 12\n[[plugin]]\nname = "b"\n});
  my $r = $t->run();
  like($r->{stdout}, qr/^Updated:[ ]app[.]toml$/mx, 'reported as updated');
  is(
    read_toml($t, 'app.toml'), {
      theme => 'dark',
      editor => {font => 'mono', size => 12},
      plugin => [{name => 'a'}, {name => 'b'}]
    },
    'tables merged and arrays of tables unioned');

  # The program owning the file rewrites it in another order.
  my $rewritten =
       qq{[[plugin]]\nname = "a"\n[[plugin]]\nname = "b"\n[editor]\nsize = 12\nfont = "mono"\n}
      .qq{# new comment\ntheme = "dark"\n};
  $t->write_home_file('app.toml', $rewritten);
  $r = $t->run();
  like(
    $r->{stdout},
    qr/^Nothing[ ]to[ ]do[ ]for:[ ]app[.]toml$/mx,
    'rewritten file: nothing to do');
  is($t->read_home_file('app.toml'), $rewritten, 'rewritten file: not modified');
};

subtest 'TOML: values removed from the fragment' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.toml', qq{user = 1\n});
  $t->add_fragment('app',
         qq{FILENAME app.toml\nMERGE toml\n\na = 1\nb = 2\nc = 3\n[sub]\nd = 4\n}
        .qq{[[p]]\nname = "x"\n[[p]]\nname = "y"\n});
  $t->run();
  # The program modifies one of our values.
  my $data = read_toml($t, 'app.toml');
  $data->{b} = 'changed';
  $t->write_home_file('app.toml', TOML::Tiny::to_toml($data));

  $t->add_fragment('app', qq{FILENAME app.toml\nMERGE toml\n\na = 1\n[[p]]\nname = "x"\n});
  $t->run();
  is(
    read_toml($t, 'app.toml'),
    {user => 1, a => 1, b => 'changed', p => [{name => 'x'}]},
    'unmodified values removed, empty table removed, modified value kept');
};

subtest 'TOML: state saved when there is nothing to do' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.toml', qq{a = 1\nb = 2\n});
  $t->add_fragment('app', qq{FILENAME app.toml\nMERGE toml\n\na = 1\nb = 2\n});
  my $r = $t->run('--test');
  like($r->{stdout}, qr/^Nothing[ ]to[ ]do[ ]for:[ ]app[.]toml$/mx, 'nothing to do');
  is($t->read_home_file('.local/state/update_config/app'), undef, '--test: no state saved');
  $t->run();
  $t->add_fragment('app', qq{FILENAME app.toml\nMERGE toml\n\na = 1\n});
  $t->run();
  is(read_toml($t, 'app.toml'), {a => 1}, 'value removed using the saved state');
};

subtest 'TOML: MERGE ARRAYS replace' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.toml', qq{list = ["x", "z"]\n[[p]]\nname = "a"\n});
  $t->add_fragment('app',
    qq{FILENAME app.toml\nMERGE toml\nMERGE ARRAYS replace\n\nlist = ["y"]\n[[p]]\nname = "b"\n});
  $t->run();
  is(read_toml($t, 'app.toml'), {list => ['y'], p => [{name => 'b'}]}, 'arrays replaced');
};

subtest 'TOML: arrays of tables with a key' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('languages.toml',
         qq{[[language]]\nname = "go"\nauto-format = true\n}
        .qq{[[language]]\nname = "rust"\nindent = 2\nservers = ["ra"]\n});
  $t->add_fragment('languages',
         qq{FILENAME languages.toml\nMERGE toml\n\n}
        .qq{update_config_arrays = { language = "key:name" }\n}
        .qq{[[language]]\nname = "rust"\nindent = 4\n}
        .qq{[[language]]\nname = "python"\nauto-format = true\n});
  $t->run();
  is(
    read_toml($t, 'languages.toml'), {
      language => [
        {name => 'go', 'auto-format' => T()},
        {name => 'rust', indent => 4, servers => ['ra']},
        {name => 'python', 'auto-format' => T()}
      ]
    },
    'matching entry merged, new entry appended, marker not written');

  $t->add_fragment('languages',
         qq{FILENAME languages.toml\nMERGE toml\n\n}
        .qq{update_config_arrays = { language = "key:name" }\n}
        .qq{[[language]]\nname = "go"\nauto-format = true\n});
  $t->run();
  is(
    read_toml($t, 'languages.toml'),
    {language => [{name => 'go', 'auto-format' => T()}, {name => 'rust', servers => ['ra']}]},
    'removed entries: our values removed, entry removed when only its key remains');
};

subtest 'TOML: nested array with a composite key' => sub {
  need_module('TOML::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('alacritty.toml',
         qq{[[keyboard.bindings]]\nkey = "N"\nmods = "Control"\naction = "A"\n}
        .qq{[[keyboard.bindings]]\nkey = "N"\nmods = "Shift"\naction = "B"\n});
  $t->add_fragment('alacritty',
         qq{FILENAME alacritty.toml\nMERGE toml\n\n[keyboard]\n}
        .qq{update_config_arrays = { bindings = "key:key,mods" }\n}
        .qq{[[keyboard.bindings]]\nkey = "N"\nmods = "Shift"\naction = "C"\n});
  $t->run();
  is(
    read_toml($t, 'alacritty.toml'), {
      keyboard => {
        bindings => [
          {key => 'N', mods => 'Control', action => 'A'},
          {key => 'N', mods => 'Shift', action => 'C'}
        ]
      }
    },
    'entry matched on all the key fields');
};

subtest 'JSON' => sub {
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.json', qq{{"z": [1, 2], "b": {"c": true},}\n});
  $t->add_fragment('app',
    qq{FILENAME app.json\nMERGE json\n\n{"b": {"d": null}, "z": [2, 3]}\n});
  my $r = $t->run('--diff');
  is(
    $t->read_home_file('app.json'),
    qq{{\n  "b": {\n    "c": true,\n    "d": null\n  },\n  "z": [\n    2,\n    3\n  ]\n}\n},
    'merged, with sorted keys, and arrays of scalars replaced');
  like($r->{stdout}, qr/^[+]\s+"d":[ ]null$/mx, '--diff: added value printed');
  unlike($r->{stdout}, qr/"b"/x, '--diff: unchanged lines not printed');
};

subtest 'YAML' => sub {
  need_module('YAML::PP');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.yaml', qq{a: {x: 1, y: [a, b]}\nb: true\n});
  $t->add_fragment('app',
    qq{FILENAME app.yaml\nMERGE yaml\n\na:\n  update_config_arrays: {y: union}\n  y: [c]\n  z: text\n}
  );
  $t->run();
  is(
    YAML::PP->new->load_string($t->read_home_file('app.yaml')),
    {a => {x => 1, y => [qw(a b c)], z => 'text'}, b => T()},
    'flow style YAML merged, with a union of scalars');
};

subtest 'INI' => sub {
  need_module('Config::Tiny');
  my $t = UpdateConfigTest->new;
  $t->write_home_file('app.ini',
    qq{; comment\nroot = 1\n[org/app]\nkey='value'\n\n[other]\nk = v\n});
  $t->add_fragment('app', qq{FILENAME app.ini\nMERGE ini\n\n[org/app]\nnew=[1, 2]\n});
  $t->run();
  is(
    $t->read_home_file('app.ini'),
    qq{root=1\n\n[org/app]\nkey='value'\nnew=[1, 2]\n\n[other]\nk=v\n},
    'merged, with sorted sections and keys');
};

subtest 'NEED ROOT' => sub {
  my $t = UpdateConfigTest->new;
  my $state_dir = catfile($t->root, 'root_state');
  my $env = {env => {UPDATE_CONFIG_ROOT_STATE_DIR => $state_dir}};
  $t->add_fragment('app', qq{FILENAME app.json\nMERGE json\nNEED ROOT\n\n{"a": 1, "b": 2}\n});
  $t->run($env, '--no-root');
  ok(!-e $state_dir, 'no state saved without --root');
  $t->run($env, '--root');
  ok(-f catfile($state_dir, 'app'), 'state saved in the root state directory');
  is($t->read_home_file('.local/state/update_config/app'), undef, 'no state saved in the home');
  $t->add_fragment('app', qq{FILENAME app.json\nMERGE json\nNEED ROOT\n\n{"a": 1}\n});
  $t->run($env, '--root');
  is($t->read_home_file('app.json'), qq{{\n  "a": 1\n}\n},
    'value removed using the root state');
};

subtest 'Invalid configurations' => sub {
  my $t = UpdateConfigTest->new;
  $t->add_fragment('app', qq{MERGE xml\n\n<a/>\n});
  my $r = $t->run();
  isnt($r->{exit}, 0, 'unsupported format: failure');
  like($r->{stderr}, qr/Unsupported[ ]MERGE[ ]format:[ ]'xml'/x, 'unsupported format: message');

  $t->add_fragment('app', qq{MERGE json\nGUARD SUFFIX foo\n\n{}\n});
  $r = $t->run();
  like(
    $r->{stderr},
    qr/MERGE[ ]cannot[ ]be[ ]used[ ]with[ ]GUARD[ ]SUFFIX/x,
    'incompatible directive');

  $t->add_fragment('app', qq{MERGE ARRAYS union\n\n{}\n});
  $r = $t->run();
  like(
    $r->{stderr},
    qr/MERGE[ ]ARRAYS[ ]requires[ ]the[ ]MERGE[ ]directive/x,
    'MERGE ARRAYS alone');

  $t->add_fragment('app', qq{MERGE json\n\n{}\n});
  $t->write_home_file('app', qq{[1, 2]\n});
  $r = $t->run();
  like($r->{stderr}, qr/The[ ]content[ ]of[ ]'.*app'[ ]is[ ]not[ ]a[ ]json[ ]table/x,
    'not a table');
  is($t->read_home_file('app'), qq{[1, 2]\n}, 'invalid target not modified');

  $t->write_home_file('app', qq{{}\n});
  $t->add_fragment('app',
    qq{MERGE json\n\n{"update_config_arrays": {"a": "sorted"}, "a": []}\n});
  $r = $t->run();
  like($r->{stderr}, qr/Invalid[ ]array[ ]merge[ ]mode:[ ]'sorted'/x, 'invalid array mode');

  $t->add_fragment('app', qq{MERGE json\n\n{"update_config_arrays": {"a": "union"}}\n});
  $r = $t->run();
  like(
    $r->{stderr},
    qr/names[ ]'a'[ ]which[ ]is[ ]not[ ]an[ ]array/x,
    'marker for a missing array');
};

done_testing;
