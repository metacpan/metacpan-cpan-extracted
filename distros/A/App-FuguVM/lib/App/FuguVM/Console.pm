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
our $VERSION = '0.1.1';

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
#	Drive a complete OpenBSD installation.
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
	);
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
