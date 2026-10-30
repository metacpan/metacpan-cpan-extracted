#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

use CLI::Simple;

plan skip_all => 'no Log::Log4perl installed'
  if !eval { require Log::Log4perl; };

{

  package Local::LogLevelTest;

  use parent qw(CLI::Simple);

  __PACKAGE__->use_log4perl( level => 'error' );
}

my $commands = {
  plain  => sub { return 0 },
  logged => [ sub { return 0 }, 'debug' ],
};

subtest 'application default' => sub {
  local @ARGV = ('plain');

  my $cli = Local::LogLevelTest->new(
    option_specs => ['log-level=s'],
    commands     => $commands,
  );

  is( $cli->get_log_level,     'error',               'application default selected' );
  is( $cli->get_logger->level, $Log::Log4perl::ERROR, 'logger uses application default' );
};

subtest 'command-specific level' => sub {
  local @ARGV = ('logged');

  my $cli = Local::LogLevelTest->new(
    option_specs => ['log-level=s'],
    commands     => $commands,
  );

  is( $cli->get_log_level,     'debug',               'command level overrides default' );
  is( $cli->get_logger->level, $Log::Log4perl::DEBUG, 'logger uses command level' );
};

subtest 'explicit CLI level' => sub {
  local @ARGV = ( '--log-level', 'warn', 'logged' );

  my $cli = Local::LogLevelTest->new(
    option_specs => ['log-level=s'],
    commands     => $commands,
  );

  is( $cli->get_log_level,     'warn',               'CLI level overrides command level' );
  is( $cli->get_logger->level, $Log::Log4perl::WARN, 'logger uses CLI level' );
};

done_testing;
