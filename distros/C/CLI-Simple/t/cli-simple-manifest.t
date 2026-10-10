#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;
use YAML::Tiny qw(DumpFile);

use_ok('CLI::Simple');

if ( !CLI::Simple->can('_load_manifest') ) {
  plan skip_all => 'CLI::Simple 2.0.0 manifest methods not yet implemented';
}

########################################################################
# Helpers
########################################################################

sub write_manifest {
  my (%manifest) = @_;

  my ( $fh, $path ) = tempfile( 'manifest-XXXX', SUFFIX => '.yml', UNLINK => 1 );

  close $fh;

  DumpFile( $path, \%manifest );

  return $path;
}

########################################################################
# _load_manifest stores legacy command metadata without composing roles
########################################################################

{

  package CLI::Simple::Test::RoleA;

  use Role::Tiny;

  sub cmd_foo {
    return 'foo';
  }

  sub cmd_bar {
    return 'bar';
  }

  package CLI::Simple::Test::RoleB;

  use Role::Tiny;

  sub cmd_baz {
    return 'baz';
  }
}

{
  my $yaml = write_manifest(
    options  => [qw(help|h verbose!)],
    commands => {
      foo => 'CLI::Simple::Test::RoleA',
      bar => 'CLI::Simple::Test::RoleA',
      baz => 'CLI::Simple::Test::RoleB',
    },
  );

  {

    package CLI::Simple::Test::Consumer;

    use parent qw(CLI::Simple);
  }

  CLI::Simple->_load_manifest( 'CLI::Simple::Test::Consumer', $yaml );

  my $manifest = CLI::Simple::Test::Consumer->_manifest;

  ok( $manifest, '_manifest returns stored manifest', );

  is_deeply(
    $manifest->{_commands},
    { foo => 'CLI::Simple::Test::RoleA',
      bar => 'CLI::Simple::Test::RoleA',
      baz => 'CLI::Simple::Test::RoleB',
    },
    'legacy command metadata preserved',
  );

  ok( !CLI::Simple::Test::Consumer->can('cmd_foo'), '_load_manifest does not compose first legacy role', );

  ok( !CLI::Simple::Test::Consumer->can('cmd_baz'), '_load_manifest does not compose second legacy role', );
}

########################################################################
# _load_manifest normalizes selective role metadata
########################################################################

{
  my $yaml = write_manifest(
    roles => {
      foo => 'CLI::Simple::Test::RoleA',
      baz => [ 'CLI::Simple::Test::RoleA', 'CLI::Simple::Test::RoleB', ],
    },
  );

  {

    package CLI::Simple::Test::Selective;

    use parent qw(CLI::Simple);
  }

  CLI::Simple->_load_manifest( 'CLI::Simple::Test::Selective', $yaml );

  my $manifest = CLI::Simple::Test::Selective->_manifest;

  is_deeply( $manifest->{_roles}{foo}, ['CLI::Simple::Test::RoleA'], 'scalar selective role normalized to array', );

  is_deeply(
    $manifest->{_roles}{baz},
    [ 'CLI::Simple::Test::RoleA', 'CLI::Simple::Test::RoleB', ],
    'selective role array preserved',
  );

  ok( !CLI::Simple::Test::Selective->can('cmd_foo'), '_load_manifest does not compose selective roles', );
}

########################################################################
# command cannot be declared in both commands and roles
########################################################################

{
  my $yaml = write_manifest(
    commands => { foo => 'CLI::Simple::Test::RoleA', },
    roles    => { foo => 'CLI::Simple::Test::RoleA', },
  );

  {

    package CLI::Simple::Test::Duplicate;

    use parent qw(CLI::Simple);
  }

  my $err = do {
    local $@;

    eval { CLI::Simple->_load_manifest( 'CLI::Simple::Test::Duplicate', $yaml ); };

    $@;
  };

  like( $err, qr/command 'foo' is defined in both commands and roles/, 'command cannot appear in both commands and roles', );
}

########################################################################
# selective role specification must be scalar or array
########################################################################

{
  my $yaml = write_manifest( roles => { foo => { role => 'CLI::Simple::Test::RoleA', }, }, );

  {

    package CLI::Simple::Test::InvalidRoles;

    use parent qw(CLI::Simple);
  }

  my $err = do {
    local $@;

    eval { CLI::Simple->_load_manifest( 'CLI::Simple::Test::InvalidRoles', $yaml ); };

    $@;
  };

  like( $err, qr/invalid roles specification for command 'foo'/, 'invalid selective role specification rejected', );
}

########################################################################
# selective role names must be valid class names
########################################################################

{
  my $yaml = write_manifest( roles => { foo => 'not a class name', }, );

  {

    package CLI::Simple::Test::InvalidRoleName;

    use parent qw(CLI::Simple);
  }

  my $err = do {
    local $@;

    eval { CLI::Simple->_load_manifest( 'CLI::Simple::Test::InvalidRoleName', $yaml ); };

    $@;
  };

  like( $err, qr/invalid role 'not a class name' for command 'foo'/, 'invalid selective role class name rejected', );
}

########################################################################
# manifest values pass through unchanged
########################################################################

{
  my $yaml = write_manifest(
    options         => [qw(help|h verbose! format=s)],
    default_options => { format => 'json' },
    extra_options   => [qw(content)],
    abbreviations   => 1,
    alias           => { commands => { f => 'foo', }, },
    commands        => { foo      => 'CLI::Simple::Test::RoleA', },
  );

  {

    package CLI::Simple::Test::PassThrough;

    use parent qw(CLI::Simple);
  }

  CLI::Simple->_load_manifest( 'CLI::Simple::Test::PassThrough', $yaml );

  my $manifest = CLI::Simple::Test::PassThrough->_manifest;

  is_deeply( $manifest->{default_options}, { format => 'json' }, 'manifest preserves default_options', );

  is_deeply( $manifest->{extra_options}, [qw(content)], 'manifest preserves extra_options', );

  is_deeply( $manifest->{options}, [qw(help|h verbose! format=s)], 'manifest preserves options', );

  is( $manifest->{abbreviations}, 1, 'manifest preserves abbreviations', );

  is_deeply( $manifest->{alias}, { commands => { f => 'foo', }, }, 'manifest preserves aliases', );
}

########################################################################
# classes without manifests are unaffected
########################################################################

{

  package CLI::Simple::Test::Legacy;

  use parent qw(CLI::Simple);

  sub cmd_legacy {
    return 'legacy';
  }
}

{
  ok( !CLI::Simple::Test::Legacy->_manifest, 'class without manifest has no manifest metadata', );

  ok( CLI::Simple::Test::Legacy->can('cmd_legacy'), 'class without manifest retains its own methods', );
}

done_testing;
