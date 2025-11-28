
=head1 DESCRIPTION

This test ensures that L<Beam::Minion::Util> can correctly instantiate a
L<Minion> object using any of the supported Minion backends:

L<Minion::Backend::Pg>, L<Minion::Backend::mysql>, L<Minion::Backend::SQLite>,
L<Minion::Backend::MongoDB>

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Mojo::File qw( curfile );
use Beam::Minion::Util qw( minion minion_init_args );

my %backend = (
    mysql => {
        'mysql://user@127.0.0.1/minion'
            => [qw( mysql mysql://user@127.0.0.1/minion )],
        'mysql+dsn+dbi:mysql:mysql_read_default_file=~/.my.cnf'
            => [qw( mysql dsn dbi:mysql:mysql_read_default_file=~/.my.cnf )],
    },
    Pg => {
        'postgres://user@127.0.0.1/minion' => [qw( Pg postgres://user@127.0.0.1/minion )],
    },
    MongoDB => {
        'mongodb://127.0.0.1' => [qw( MongoDB mongodb://127.0.0.1 )],
    },
    SQLite => {
        'sqlite:////tmp/minion.db' => [qw( SQLite sqlite:////tmp/minion.db )],
    },
    file => {
        'file://' . curfile->sibling('share', 'config.yml') => [qw( SQLite sqlite:////tmp/minion.db )],
    },
);

subtest 'reads BEAM_MINION environment variable' => sub {
  for my $backend ( keys %backend ) {
      for my $input ( keys %{ $backend{ $backend } } ) {
          local @Beam::Minion::Util::INIT_ARGS = ();
          local $ENV{ BEAM_MINION } = $input;
          is_deeply [minion_init_args()], $backend{ $backend }{ $input }, $input . ' results in correct args';
      }
  }
};

subtest 'allows overriding via `init()`' => sub {
  my @expect_args = (values $backend{SQLite}->%*)[0]->@*;
  my @got_args = minion_init_args(@expect_args);
  is_deeply \@got_args, \@expect_args, 'calling minion_init_args results in correct args';
  is_deeply [minion_init_args()], \@expect_args, 'args are cached for additional calls';
};

done_testing;
