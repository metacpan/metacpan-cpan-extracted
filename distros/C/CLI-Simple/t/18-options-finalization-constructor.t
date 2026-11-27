use strict;
use warnings;

use Test::More;
use CLI::Simple;

{
  package Local::FinalizedConstructor;
  use parent qw(CLI::Simple);

  sub cmd_run { return 0; }

  sub init {
    my ($self) = @_;
    $self->{value_at_init} = $self->get_config;
    return $self;
  }
}

subtest 'finalization runs before application init' => sub {
  local @ARGV = qw(--config settings.json run);
  my $calls = 0;
  my $app = Local::FinalizedConstructor->new(
    options => {
      'config|c=s' => {
        finalize => sub {
          my ($self, $path) = @_;
          $calls++;
          return { path => $path };
        },
      },
    },
    commands => { run => \&Local::FinalizedConstructor::cmd_run },
  );
  is_deeply( $app->{value_at_init}, { path => 'settings.json' }, 'init sees final result' );
  is( $calls, 1, 'finalizer called once' );
};

subtest 'default can be finalized' => sub {
  local @ARGV = qw(run);
  my $app = Local::FinalizedConstructor->new(
    options => {
      'config|c=s' => {
        finalize => sub { return uc $_[1]; },
      },
    },
    default_options => { config => 'default' },
    commands => { run => \&Local::FinalizedConstructor::cmd_run },
  );
  is( $app->{value_at_init}, 'DEFAULT', 'default transformed before init' );
};

done_testing;
1;
