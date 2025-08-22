#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;
use Test::Exit;
use Test::Output;

use_ok('CLI::Simple');

use vars qw(@ARGV);

########################################################################
sub foo {
########################################################################
  print {*STDOUT} 'Hello World!';

  return 0;
}

my @options = qw(
  foo
  bar=s
);

########################################################################
subtest 'happy path' => sub {
########################################################################

  local @ARGV = qw(--foo --bar=buz foo);

  my $app = CLI::Simple->new( commands => { foo => \&foo }, option_specs => \@options );

  ok( $app->get_foo,          'foo set' );
  ok( $app->get_bar eq 'buz', 'bar set' );
};

########################################################################
subtest 'bad option' => sub {
########################################################################

  local @ARGV = '--bad-option foo';

  exits_ok { CLI::Simple->new( commands => { foo => \&foo }, option_specs => \@options ), 1, 'called exit' };
};

########################################################################
subtest 'option alias' => sub {
########################################################################

  local @ARGV = qw(--foo --bar=buz foo);

  my $app = CLI::Simple->new(
    commands     => { foo     => \&foo },
    alias        => { options => { biz => 'bar' } },
    option_specs => \@options
  );

  ok( $app->get_foo,          'foo set' );
  ok( $app->get_bar eq 'buz', 'bar set' );
  ok( $app->get_biz eq 'buz', 'biz set' );

  local @ARGV = qw(--foo --biz=buz foo);

  $app = CLI::Simple->new(
    commands     => { foo     => \&foo },
    alias        => { options => { biz => 'bar' } },
    option_specs => \@options
  );

  ok( $app->get_foo,          'foo set' );
  ok( $app->get_bar eq 'buz', 'bar set' );
  ok( $app->get_biz eq 'buz', 'biz set' );
};

########################################################################
subtest 'run' => sub {
########################################################################
  local @ARGV = qw(--foo --bar=buz foo);

  my $app = CLI::Simple->new(
    commands     => { foo     => \&foo },
    alias        => { options => { biz => 'bar' } },
    option_specs => \@options
  );

  stdout_is( sub { $app->run() }, 'Hello World!' );
};

########################################################################
subtest 'alias precedence and symmetry' => sub {
########################################################################
  local @ARGV = qw(--bar=2 --biz=9 go);  # biz is alias for bar

  my $got;

  my $app = CLI::Simple->new(
    commands     => { go      => sub { $got = \%ENV } },  # or capture parsed opts via a hook
    alias        => { options => { biz => 'bar' } },
    option_specs => ['bar=i'],
  );

  # however you surface parsed options, assert both entries reflect last value
  is( $app->get_bar, 2, 'canonical reflects first' );
  is( $app->get_biz, 2, 'alias mirrors canonical' );
};

########################################################################
subtest 'command alias' => sub {
########################################################################
  local @ARGV = qw(--foo --bar=buz fiz);

  my $app = CLI::Simple->new(
    commands     => { foo     => \&foo },
    alias        => { options => { biz => 'bar' }, commands => { fiz => 'foo' } },
    option_specs => \@options
  );

  stdout_is( sub { $app->run() }, 'Hello World!' );
};

########################################################################
subtest 'command abbreviations' => sub {
########################################################################
  local @ARGV = qw(--foo --bar=buz fuzz);

  my $app = CLI::Simple->new(
    commands      => { fuzzball => \&foo },
    alias         => { options  => { biz => 'bar' } },
    option_specs  => \@options,
    abbreviations => 1,
  );

  stdout_is( sub { $app->run() }, 'Hello World!' );

  local @ARGV = qw(--foo --bar=buz fuzz);

  eval {
    CLI::Simple->new(
      commands => {
        fuzzball => \&foo,
        buzzball => sub { return 0; },
      },
      alias        => { options => { biz => 'bar' } },
      option_specs => \@options
    )->run();
  };

  my $err = $EVAL_ERROR // q{};

  like( $err, qr/unknown\s+command/xsmi, 'bad command' );
};

########################################################################
subtest 'ambiguous abbrev croaks' => sub {
########################################################################
  local @ARGV = qw(run);  # both runit and runner exist

  eval {
    CLI::Simple->new(
      commands      => { runit => sub { }, runner => sub { } },
      abbreviations => 1,
      option_specs  => [],
    )->run;
  };

  my $err = $EVAL_ERROR;

  like $err, qr/\bambiguous\b/ixsm, 'croaks on ambiguous command';
};

done_testing;

1;

__END__

1;
