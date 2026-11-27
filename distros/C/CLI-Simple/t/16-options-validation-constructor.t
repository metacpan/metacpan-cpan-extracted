use strict;
use warnings;

use Test::More;
use CLI::Simple;

{
  package Local::ValidatedConstructor;
  use parent qw(CLI::Simple);
  sub cmd_run { return 0; }
  sub init {
    my ($self) = @_;
    $self->{value_at_init} = $self->get_port;
    return $self;
  }
}

subtest 'CLI value validated before init' => sub {
  local @ARGV = qw(--port 8080 run);
  my $app = Local::ValidatedConstructor->new(
    options  => { 'port|p=i' => { required => 1, min => 1, max => 65535 } },
    commands => { run => \&Local::ValidatedConstructor::cmd_run },
  );
  is( $app->{value_at_init}, 8080, 'validated value available in init' );
};

subtest 'default satisfies required option' => sub {
  local @ARGV = qw(run);
  my $app = Local::ValidatedConstructor->new(
    options         => { 'port|p=i' => { required => 1, min => 1 } },
    default_options => { port => 1234 },
    commands        => { run => \&Local::ValidatedConstructor::cmd_run },
  );
  is( $app->{value_at_init}, 1234, 'default validated before init' );
};

subtest 'missing required option rejected' => sub {
  local @ARGV = qw(run);
  my $ok = eval {
    Local::ValidatedConstructor->new(
      options  => { 'port|p=i' => { required => 1 } },
      commands => { run => \&Local::ValidatedConstructor::cmd_run },
    );
    1;
  };
  ok( !$ok, 'construction rejects missing required option' );
  like( $@, qr/Required option 'port' is undefined/, 'specific error' );
};

subtest 'legacy parsing still succeeds' => sub {
  local @ARGV = qw(--port 8080 run);
  my $app = Local::ValidatedConstructor->new(
    option_specs => [ 'port|p=i' ],
    commands     => { run => \&Local::ValidatedConstructor::cmd_run },
  );
  is( $app->get_port, 8080, 'legacy option still works' );
};

done_testing;
1;
