package App::duino::Command::com;
{
  $App::duino::Command::com::VERSION = '0.10';
}

use strict;
use warnings;

use App::duino -command;

use Device::SerialPort;
use IPC::Cmd qw(can_run);

=head1 NAME

App::duino::Command::com - Open a serial monitor to an Arduino

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  $ duino com --port /dev/ttyACM0

=head1 DESCRIPTION

This command can be used to initiate a serial monitor with an Arduino board (or
any other device that supports serial communication). The C<picocom> terminal
emulator will be used if installed, otherwise a built-in RX-only terminal will
be started.

=cut

sub abstract { 'open a serial monitor to an Arduino' }

sub usage_desc { '%c upload %o [sketch.ino]' }

sub opt_spec {
	my ($self) = @_;

	return (
		[ 'port|p=s', 'specify the serial port to use',
			{ default => $self -> default_config('port') } ],
	);
}

sub execute {
	my ($self, $opt, $args) = @_;

	if (can_run('picocom')) {
		system 'picocom', $opt -> port;
	} else {
		open my $fh, '<', $opt -> port
			or die "Can't open serial port '".$opt -> port."'.\n";

		my $fd = fileno $fh;

		while (read $fh, my $char, 1) {
			print $char;
		}

		close $fh;
	}
}

=head1 OPTIONS

=over 4

=item B<--port>, B<-p>

The path to the Arduino serial port. The environment variable C<ARDUINO_PORT>
will be used if present and if the command-line option is not set. If neither
of them is set the default value (C</dev/ttyACM0>) will be used.

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::duino::Command::com
