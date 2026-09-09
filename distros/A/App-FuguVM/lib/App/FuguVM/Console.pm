# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2024 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguVM::Console;
our $VERSION = '0.2.0';

use Fugu::File;
use Fugu::Log;
use Fugu::Process;

# App::FuguVM::Console - drive the serial console of a guest.
#
# The console answers no protocol, so an expect(1) script types at it.
# The module runs the installer that way, and it runs any other script
# the operator names. The scripts ship under share/fuguvm/expect, and
# Fugu::File resolves them against the install root.

# Where the shipped scripts live, relative to the root of the tree.
use constant SCRIPT_DIR => 'share/fuguvm/expect';

sub new ( $class, %args )
{
	my $self = bless {
		host => $args{host} // 'localhost',
		port => $args{port},
	}, $class;

	return $self;
}

# $class_or_self->script_path($script_name):
#	Return the path of a shipped expect script, or undef.
#
#	The method also works on the class. App::FuguVM::DiskCache hashes
#	the installer script into its cache key, so it must resolve the
#	script the same way run_install does.
sub script_path ( $self, $script_name )
{
	return Fugu::File->share_path(
		SCRIPT_DIR . "/$script_name",
		from => __FILE__,
		dist => 'App-FuguVM'
	);
}

# $self->run_script($script, @args):
#	Run one expect script against the console of this VM. The
#	method takes a path, or the name of a shipped script.
sub run_script ( $self, $script, @args )
{
	my $path = -f $script ? $script : $self->script_path($script);
	unless ( defined $path && -f $path ) {
		Fugu::Log->default->error( 'Expect script not found: %s',
			$script );
		return 0;
	}
	unless ( -x $path ) {
		Fugu::Log->default->error( 'Expect script not executable: %s',
			$path );
		return 0;
	}

	return $self->_expect( $path, @args );
}

# $self->run_install($config):
#	Drive a complete OpenBSD installation. The script reads its
#	arguments by position: the root password, the proxy URL, the
#	architecture, and the verify word.
sub run_install ( $self, $config )
{
	my $script = $self->script_path('install.exp');
	unless ( defined $script ) {
		Fugu::Log->default->error('Install script not found');
		return 0;
	}

	return $self->_expect(
		$script,
		$config->{root_password} // 'openbsd',
		$config->{proxy_url}     // 'none',
		$config->{arch},
		$config->{verify} // 'yes',
	);
}

# $self->run_autoinstall($config):
#	Start an autoinstall(8) over the serial console. The script
#	answers the install prompt and the response-file prompt, and
#	the response file answers everything else. The configuration
#	gives the response-file URL and the architecture.
#
#	The method calls _expect, like run_install, and it must not use
#	run_script: run_script needs the execute bit, and an installed
#	share tree does not keep it.
sub run_autoinstall ( $self, $config )
{
	my $script = $self->script_path('autoinstall.exp');
	unless ( defined $script ) {
		Fugu::Log->default->error('Autoinstall script not found');
		return 0;
	}

	return $self->_expect( $script, $config->{autoinstall_url},
		$config->{arch} );
}

# $self->attach:
#	Attach the terminal of the caller to this console, with
#	telnet(1). The method returns the exit code of telnet(1).
#
#	The guest never closes the console, so no end of file ends the
#	attachment. The operator ends it with the telnet escape key,
#	Ctrl-], and then 'quit'. telnet(1) leaves the terminal raw
#	when a signal kills it, so the method saves the terminal
#	attributes first and restores them on every exit path. The
#	restore is idempotent. A signal that kills the tool also ends
#	telnet(1), so no raw orphan keeps the terminal.
sub attach ($self)
{
	# POSIX loads lazily, as App::FuguVM::Guest already does it.
	require POSIX;

	my $saved;
	if ( POSIX::isatty(*STDIN) ) {
		$saved = POSIX::Termios->new;
		$saved->getattr( fileno(STDIN) );
	}
	my $restore = sub {
		$saved->setattr( fileno(STDIN), POSIX::TCSANOW() )
		    if defined $saved;
	};

	# A fork and an exec, not Fugu::Process->run: the child must
	# keep the terminal of the caller, and the parent must know
	# the child process ID, so a signal handler can end the child.
	my $pid = fork;
	if ( !defined $pid ) {
		Fugu::Log->default->error( 'Cannot fork: %s', $! );
		return 1;
	}
	if ( $pid == 0 ) {
		exec( 'telnet', $self->{host}, $self->{port} );

		# The exec failed. Exit like an absent command.
		POSIX::_exit(1);
	}

	# The handler ends the child, restores the terminal, resets
	# itself, and raises the same signal again. Thus one kill of
	# the tool ends the whole session, and the exit status of the
	# tool stays honest.
	local @SIG{qw(INT TERM HUP)};
	for my $name (qw(INT TERM HUP)) {
		$SIG{$name} = sub ($signal) {
			kill $signal, $pid;
			$restore->();
			$SIG{$signal} = 'DEFAULT';
			kill $signal, $$;
		};
	}

	my $reaped = waitpid( $pid, 0 );
	my $status = $reaped == $pid ? $? : -1;

	$restore->();

	# Fugu::Process->exit_code maps a failure to 1, and a signal
	# death to 128 plus the signal number.
	return Fugu::Process->exit_code($status);
}

# $self->_expect($script, @args):
#	Run expect(1) on the script, with the host and the port first.
#	The scripts read their timeout from FUGUVM_TIMEOUT in the
#	environment themselves, and each carries its own default.
#
#	The run is a passthrough. An installation writes for tens of
#	minutes, and an operator who waits needs to see the progress
#	while it happens, not after.
sub _expect ( $self, $script, @args )
{
	my $result = Fugu::Process->run(
		cmd =>
		    [ 'expect', $script, $self->{host}, $self->{port}, @args ],
		passthrough => 1,
	);

	unless ( $result->{success} ) {
		Fugu::Log->default->error( 'expect %s failed: %s',
			$script,
			$result->{error} // "exit $result->{exit_code}" );
	}

	return $result->{success} ? 1 : 0;
}

1;
