#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use CLI::Simple;

########################################################################
sub write_manifest {
########################################################################
  my ($yaml) = @_;

  my ( $fh, $filename ) = tempfile();

  print {$fh} $yaml;
  close $fh;

  return $filename;
}

########################################################################
subtest 'single selective role' => sub {
########################################################################
  {

    package Local::Role::Foo;

    use Role::Tiny;

    sub cmd_foo {
      return 'foo';
    }
  }

  {

    package Local::Role::Bar;

    use Role::Tiny;

    sub cmd_bar {
      return 'bar';
    }
  }

  {

    package Local::App::Single;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  foo: Local::Role::Foo
  bar: Local::Role::Bar
YAML

  local @ARGV = qw(foo);

  CLI::Simple->_load_manifest( 'Local::App::Single', $manifest );

  is( Local::App::Single->main, 'foo', 'selective role command runs' );

  ok( Local::App::Single->can('cmd_foo'), 'selected role was composed' );

  ok( !Local::App::Single->can('cmd_bar'), 'unselected role was not composed' );

  return;
};

########################################################################
subtest 'multiple roles for one command' => sub {
########################################################################
  {

    package Local::Role::Packages;

    use Role::Tiny;

    sub package_name {
      return 'Foo-Bar';
    }
  }

  {

    package Local::Role::Publish;

    use Role::Tiny;

    sub cmd_publish {
      my ($self) = @_;

      return $self->package_name;
    }
  }

  {

    package Local::App::Multiple;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  publish:
    - Local::Role::Publish
    - Local::Role::Packages
YAML

  local @ARGV = qw(publish);

  CLI::Simple->_load_manifest( 'Local::App::Multiple', $manifest );

  is( Local::App::Multiple->main, 'Foo-Bar', 'all roles required by command are composed' );

  ok( Local::App::Multiple->can('cmd_publish'), 'command role was composed' );

  ok( Local::App::Multiple->can('package_name'), 'supporting role was composed' );

  return;
};

########################################################################
subtest 'legacy command selection composes all legacy roles' => sub {
########################################################################
  {

    package Local::Role::LegacyFoo;

    use Role::Tiny;

    sub cmd_foo {
      return 'foo';
    }
  }

  {

    package Local::Role::LegacyBar;

    use Role::Tiny;

    sub cmd_bar {
      return 'bar';
    }
  }

  {

    package Local::App::Legacy;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
commands:
  foo: Local::Role::LegacyFoo
  bar: Local::Role::LegacyBar
YAML

  local @ARGV = qw(foo);

  CLI::Simple->_load_manifest( 'Local::App::Legacy', $manifest );

  ok( !Local::App::Legacy->can('cmd_foo'), 'legacy selected role not composed during manifest load', );

  ok( !Local::App::Legacy->can('cmd_bar'), 'legacy unselected role not composed during manifest load', );

  is( Local::App::Legacy->main, 'foo', 'legacy command still runs', );

  ok( Local::App::Legacy->can('cmd_foo'), 'legacy selected role composed after selecting legacy command', );

  ok( Local::App::Legacy->can('cmd_bar'), 'all legacy roles composed after selecting legacy command', );

  return;
};

########################################################################
subtest 'abbreviation resolves before selective composition' => sub {
########################################################################
  {

    package Local::Role::PublishLong;

    use Role::Tiny;

    sub cmd_publish_to_cpan {
      return 'published';
    }
  }

  {

    package Local::App::Abbreviation;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  publish-to-cpan: Local::Role::PublishLong
abbreviations: 1
YAML

  local @ARGV = qw(publish-to);

  CLI::Simple->_load_manifest( 'Local::App::Abbreviation', $manifest );

  is( Local::App::Abbreviation->main, 'published', 'abbreviation resolves to selective command' );

  ok( Local::App::Abbreviation->can('cmd_publish_to_cpan'), 'canonical command role was composed' );

  return;
};

########################################################################
subtest 'command alias uses canonical selective command' => sub {
########################################################################
  {

    package Local::Role::PublishAlias;

    use Role::Tiny;

    sub cmd_publish_to_cpan {
      return 'published';
    }
  }

  {

    package Local::App::Alias;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  publish-to-cpan: Local::Role::PublishAlias
alias:
  commands:
    pub: publish-to-cpan
YAML

  local @ARGV = qw(pub);

  CLI::Simple->_load_manifest( 'Local::App::Alias', $manifest );

  is( Local::App::Alias->main, 'published', 'alias dispatches to canonical selective command' );

  ok( Local::App::Alias->can('cmd_publish_to_cpan'), 'canonical command method was composed' );

  ok !Local::App::Alias->can('cmd_pub'), 'alias does not require a separate command method';

  return;
};

########################################################################
subtest 'command cannot appear in commands and roles' => sub {
########################################################################
  {

    package Local::App::Duplicate;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
commands:
  foo: Local::Role::Foo
roles:
  foo: Local::Role::Foo
YAML

  eval { CLI::Simple->_load_manifest( 'Local::App::Duplicate', $manifest ); };

  like( $@, qr/command 'foo' is defined in both commands and roles/, 'duplicate command definition rejected' );

  return;
};

########################################################################
subtest 'invalid selective role specification' => sub {
########################################################################
  {

    package Local::App::InvalidSpec;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  foo:
    role: Local::Role::Foo
YAML

  eval { CLI::Simple->_load_manifest( 'Local::App::InvalidSpec', $manifest ); };

  like( $@, qr/invalid roles specification for command 'foo'/, 'non-scalar and non-array role specification rejected' );

  return;
};

########################################################################
subtest 'selected roles must implement command' => sub {
########################################################################
  {

    package Local::Role::NoCommand;

    use Role::Tiny;

    sub something_else {
      return 'nope';
    }
  }

  {

    package Local::App::MissingCommand;

    use parent qw(CLI::Simple);
  }

  my $manifest = write_manifest(<<'YAML');
---
roles:
  foo: Local::Role::NoCommand
YAML

  local @ARGV = qw(foo);

  CLI::Simple->_load_manifest( 'Local::App::MissingCommand', $manifest );

  eval { Local::App::MissingCommand->main; };

  like( $@, qr/roles for command 'foo' do not implement cmd_foo/, 'selected role set must provide command method' );

  return;
};

done_testing;
