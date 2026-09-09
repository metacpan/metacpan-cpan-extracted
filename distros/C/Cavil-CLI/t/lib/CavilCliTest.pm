# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package CavilCliTest;
use Mojo::Base -base, -signatures;

use Cavil::CLI;
use Mojo::File qw(tempdir);

# One CLI whose client user agent hosts the mock app. Hosting the mock and making the requests through the
# same user agent (and thus the same event loop) is what lets a blocking client request be served in-process,
# exactly as cavil-gitea does.
has cli => sub { Cavil::CLI->new };
has 'url';

# Each harness gets its own config directory (via XDG_CONFIG_HOME), so scenarios do not touch the real one or
# each other, while two runs within one scenario still share it.
has config_dir => sub {tempdir};

sub new ($class, $app) {
  my $self   = $class->SUPER::new;
  my $server = $self->cli->client->ua->server;
  $server->app($app);
  $self->url('http://127.0.0.1:' . $server->url->port);
  return $self;
}

# Run the CLI as a user would: seed @ARGV with the check command and the caller's arguments, and point it at
# the mock. Capture stdout, stderr and the exit code. Credentials go through the environment because
# there is no --url/--token to pass (see Cavil::CLI): the server and its token always travel as a pair.
sub run ($self, @args) { return $self->run_command('check', @args) }

# Same, but for an arbitrary command (e.g. whoami) rather than the check default.
sub run_command ($self, @argv) {
  return $self->_invoke(\@argv, undef, {CAVIL_URL => $self->url, CAVIL_API_KEY => 'test-token'});
}

# Same, with whatever credentials the caller wants in the environment (a bad token, or only one of the pair).
sub run_with_env ($self, $env, @argv) { return $self->_invoke(\@argv, undef, $env) }

# Run exactly the given arguments with no credentials in the environment, optionally feeding stdin (for the
# config command's prompts). Used to exercise resolution from the saved config file.
sub run_bare ($self, $argv, $stdin = undef) { return $self->_invoke($argv, $stdin) }

sub _invoke ($self, $argv, $stdin = undef, $env = {}) {
  my $cli = $self->cli;
  my ($out, $err, $code) = ('', '', undef);
  my $run = sub {
    local @ARGV = @$argv;

    # A whole copy, so a CAVIL_URL or CAVIL_API_KEY in the real environment cannot reach the code under test.
    local %ENV = (%ENV, XDG_CONFIG_HOME => $self->config_dir->to_string, NO_COLOR => 1);
    delete @ENV{qw(CAVIL_URL CAVIL_API_KEY)};
    @ENV{keys %$env} = values %$env;
    $code = $cli->run;
  };
  {
    open my $o, '>', \$out;
    open my $e, '>', \$err;
    local *STDOUT = $o;
    local *STDERR = $e;
    if (defined $stdin) { open my $i, '<', \$stdin; local *STDIN = $i; $run->() }
    else                { $run->() }
  }

  return {stdout => $out, stderr => $err, exit => $code};
}

1;
