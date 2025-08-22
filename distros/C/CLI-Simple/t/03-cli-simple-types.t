#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;
use Test::Exit;
use Test::Output;

use_ok(qw(CLI::Simple));

########################################################################
subtest 'type mismatch croaks' => sub {
########################################################################
  local @ARGV = qw(--count foo go);

  stderr_like(
    sub {
      exits_ok {
        CLI::Simple->new(
          commands     => { go => sub { } },
          option_specs => ['count=i'],
        )->run,
        1,
        'exits on option error'
      }
    },
    qr/invalid\sfor\soption\scount/xsmi
  );
};

########################################################################
subtest 'multi options accumulate' => sub {
########################################################################
  local @ARGV = qw(--tag a --tag b go);

  my $seen;

  CLI::Simple->new(
    commands => {
      go => sub {
        my ($self) = @_;
        $seen = $self->get_tag;
      }
    },
    option_specs => ['tag=s@'],
  )->run;

  is_deeply $seen, [qw(a b)], 'tags accumulated';
};

done_testing;

1;
