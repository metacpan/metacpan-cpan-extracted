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
# Command name -> method name transformation
########################################################################

{
  my @cases = (
    [ 'annotate',           'cmd_annotate' ],
    [ 'code-review',        'cmd_code_review' ],
    [ 'update-annotations', 'cmd_update_annotations' ],
    [ 'pod-finding',        'cmd_pod_finding' ],
    [ 'release-notes',      'cmd_release_notes' ],
  );

  for my $case (@cases) {
    my ( $cmd, $expected ) = @{$case};
    ( my $got = "cmd_$cmd" ) =~ s/-/_/gxsm;
    is( $got, $expected, "name transform: $cmd -> $expected" );
  }
}

########################################################################
# _load_manifest: roles applied and dispatch table built
########################################################################

{
  package CLI::Simple::Test::RoleA;
  use Role::Tiny;
  sub cmd_foo { return 'foo' }
  sub cmd_bar { return 'bar' }

  package CLI::Simple::Test::RoleB;
  use Role::Tiny;
  sub cmd_baz { return 'baz' }
}

{
  my $yaml = write_manifest(
    options  => [qw(help|h verbose!)],
    commands => {
      'foo' => 'CLI::Simple::Test::RoleA',
      'bar' => 'CLI::Simple::Test::RoleA',
      'baz' => 'CLI::Simple::Test::RoleB',
    },
  );

  {
    package CLI::Simple::Test::Consumer;
    use parent qw(CLI::Simple);
  }

  CLI::Simple->_load_manifest( 'CLI::Simple::Test::Consumer', $yaml );

  ok( CLI::Simple::Test::Consumer->can('cmd_foo'),
    '_load_manifest: cmd_foo composed into consumer' );

  ok( CLI::Simple::Test::Consumer->can('cmd_bar'),
    '_load_manifest: cmd_bar composed into consumer' );

  ok( CLI::Simple::Test::Consumer->can('cmd_baz'),
    '_load_manifest: cmd_baz composed from second role' );

  my $manifest = CLI::Simple::Test::Consumer->_manifest;

  ok( $manifest, '_manifest returns stored manifest' );

  ok( exists $manifest->{_dispatch}{foo}, 'dispatch table has foo' );
  ok( exists $manifest->{_dispatch}{bar}, 'dispatch table has bar' );
  ok( exists $manifest->{_dispatch}{baz}, 'dispatch table has baz' );

  my $obj = bless {}, 'CLI::Simple::Test::Consumer';
  is( $manifest->{_dispatch}{foo}->($obj), 'foo', 'dispatch foo calls cmd_foo' );
  is( $manifest->{_dispatch}{baz}->($obj), 'baz', 'dispatch baz calls cmd_baz' );
}

########################################################################
# Role deduplication - same role for multiple commands
########################################################################

{
  package CLI::Simple::Test::RoleC;
  use Role::Tiny;
  sub cmd_one { return 'one' }
  sub cmd_two { return 'two' }
}

{
  my $yaml = write_manifest(
    options  => [qw(help|h)],
    commands => {
      'one' => 'CLI::Simple::Test::RoleC',
      'two' => 'CLI::Simple::Test::RoleC',
    },
  );

  {
    package CLI::Simple::Test::ConsumerC;
    use parent qw(CLI::Simple);
  }

  my $ok = eval {
    CLI::Simple->_load_manifest( 'CLI::Simple::Test::ConsumerC', $yaml );
    1;
  };

  ok( $ok, 'deduplication: same role for two commands does not die' );
  ok( CLI::Simple::Test::ConsumerC->can('cmd_one'), 'cmd_one available after dedup' );
  ok( CLI::Simple::Test::ConsumerC->can('cmd_two'), 'cmd_two available after dedup' );
}

########################################################################
# Error: role does not implement the expected method
########################################################################

{
  package CLI::Simple::Test::RoleEmpty;
  use Role::Tiny;
  # deliberately no cmd_missing
}

{
  my $yaml = write_manifest(
    options  => [qw(help|h)],
    commands => { 'missing' => 'CLI::Simple::Test::RoleEmpty' },
  );

  {
    package CLI::Simple::Test::ConsumerBad;
    use parent qw(CLI::Simple);
  }

  my $err = do {
    local $@;
    eval { CLI::Simple->_load_manifest( 'CLI::Simple::Test::ConsumerBad', $yaml ) };
    $@;
  };

  like( $err, qr/does not implement cmd_missing/,
    'error when role missing required method' );
}

########################################################################
# Backward compatibility: classes without YAML are unaffected
########################################################################

{
  package CLI::Simple::Test::Legacy;
  use parent qw(CLI::Simple);
  sub cmd_legacy { return 'legacy' }
}

{
  ok( !CLI::Simple::Test::Legacy->_manifest,
    'backward compat: no manifest on class that did not load YAML' );

  ok( CLI::Simple::Test::Legacy->can('cmd_legacy'),
    'backward compat: own methods still present' );
}

########################################################################
# manifest option/default_options/extra_options pass-through
########################################################################

{
  my $yaml = write_manifest(
    options         => [qw(help|h verbose! format=s)],
    default_options => { format => 'json' },
    extra_options   => [qw(content)],
    commands        => { 'foo' => 'CLI::Simple::Test::RoleA' },
  );

  {
    package CLI::Simple::Test::ConsumerD;
    use parent qw(CLI::Simple);
  }

  CLI::Simple->_load_manifest( 'CLI::Simple::Test::ConsumerD', $yaml );

  my $m = CLI::Simple::Test::ConsumerD->_manifest;

  is_deeply( $m->{default_options}, { format => 'json' },
    'manifest preserves default_options' );

  is_deeply( $m->{extra_options}, [qw(content)],
    'manifest preserves extra_options' );

  is_deeply( $m->{options}, [qw(help|h verbose! format=s)],
    'manifest preserves options' );
}

done_testing;
