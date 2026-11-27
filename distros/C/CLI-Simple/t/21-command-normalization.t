#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use CLI::Simple;

subtest 'normalizes extended command declarations' => sub {
  my $plain = sub { return 11; };
  my $other = sub { return 22; };
  my $source = {
    plain    => $plain,
    oldstyle => [ $other, 'debug' ],
    shortcut => 'plain',
    extended => { command => $other, description => 'Do another thing' },
    logged   => { command => $plain, description => 'Do something', log_level => 'info' },
  };

  my ( $commands, $metadata ) = CLI::Simple->normalize_commands($source);

  is( $commands->{plain}, $plain, 'plain code reference preserved' );
  is_deeply( $commands->{oldstyle}, [ $other, 'debug' ], 'legacy array preserved' );
  is( $commands->{shortcut}, 'plain', 'string alias preserved' );
  is( $commands->{extended}, $other, 'extended declaration unwrapped' );
  is_deeply( $commands->{logged}, [ $plain, 'info' ], 'log level converted to legacy dispatch form' );
  is_deeply( $metadata->{extended}, { description => 'Do another thing' }, 'description retained' );
  is_deeply( $metadata->{logged}, { description => 'Do something' }, 'logged description retained' );
  ok( !exists $source->{logged}{handler}, 'original declaration untouched' );
};

subtest 'constructor integrates command metadata and dispatch' => sub {
  local @ARGV = ('execute');
  my $app = CLI::Simple->new(
    options  => [],
    commands => { execute => { command => sub { return 73 }, description => 'Execute something' } },
  );
  is( $app->run, 73, 'normalized command dispatches' );
  is( $app->{_cli_simple_command_metadata}{execute}{description}, 'Execute something', 'description available for future help generation' );
};

subtest 'rejects malformed extended declarations' => sub {
  foreach my $case (
    [ { test => { description => 'no command' } }, qr/Missing command handler/ ],
    [ { test => { command => 'missing' } }, qr/Invalid command handler/ ],
    [ { test => { command => sub {}, unexpected => 1 } }, qr/Unknown attribute/ ],
    [ { test => { command => sub {}, description => [] } }, qr/Description.*scalar/ ],
    [ { test => { command => sub {}, log_level => [] } }, qr/Log level.*scalar/ ],
  ) {
    eval { CLI::Simple->normalize_commands($case->[0]) };
    like( $@, $case->[1], 'bad declaration rejected' );
  }
};

done_testing;
