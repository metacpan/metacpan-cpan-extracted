package App::duino::Command::upload;
{
  $App::duino::Command::upload::VERSION = '0.10';
}

use strict;
use warnings;

use App::duino -command;

use Cwd;
use POSIX;
use File::Basename;

=head1 NAME

App::duino::Command::upload - Upload a sketch to an Arduino

=head1 VERSION

version 0.10

=head1 SYNOPSIS

   # this will find the *.hex file to upload in the board's build directory
   $ duino upload --board uno --port /dev/ttyACM0

   # explicitly provide the *.hex file
   $ duino upload --board uno some_file.hex

=cut

sub abstract { 'upload a sketch to an Arduino' }

sub usage_desc { '%c upload %o [sketch.ino]' }

sub opt_spec {
	my ($self) = @_;

	return (
		[ 'board|b=s', 'specify the board model',
			{ default => $self -> default_config('board') } ],

		[ 'port|p=s', 'specify the serial port to use',
			{ default => $self -> default_config('port') } ],

		[ 'fuses|f', 'write the fuses bits when uploading',
			{ default => $self -> default_config('fuses') } ],

		[ 'uploader|u=s', 'specify the uploader to use',
			{ default => $self -> default_config('uploader') } ],

		[ 'sketchbook|s=s', 'specify the user sketchbook directory',
			{ default => $self -> default_config('sketchbook') } ],

		[ 'root|d=s', 'specify the Arduino installation directory',
			{ default => $self -> default_config('root') } ],

		[ 'hardware|r=s', 'specify the hardware type to build for',
			{ default => $self -> default_config('hardware') } ],
	);
}

sub execute {
	my ($self, $opt, $args) = @_;

	my $board= $opt -> board;
	my $port = $opt -> port;
	my $name = basename getcwd;

	($name = basename($args -> [0])) =~ s/\.[^.]+$//
		if $args -> [0] and -e $args -> [0];

	my $hex  = ".build/$board/$name.hex";

	$hex = $args -> [0] if $args -> [0] and $args -> [0] =~ /\.hex$/;

	my $mcu  = $self -> board_config($opt, 'build.mcu');
	my $prog = $opt -> uploader                               ||
		   $self -> board_config($opt, 'upload.protocol') ||
		   $self -> board_config($opt, 'upload.using');
	my $baud = $self -> board_config($opt, 'upload.speed');

	my $avrdude      = $self -> file($opt, 'hardware/tools/avrdude');
	my $avrdude_conf = $self -> file($opt, 'hardware/tools/avrdude.conf');

	print "Uploading to '" . $self -> board_config($opt, 'name') . "'...\n";

	my @avrdude_opts;
	push @avrdude_opts, '-C', $avrdude_conf;
	push @avrdude_opts, '-p', $mcu;

	push @avrdude_opts, '-c', $prog;
	push @avrdude_opts, '-b', $baud if $baud;
	push @avrdude_opts, '-P', $port;

	if ($opt -> fuses) {
		my $efuse = $self -> board_config($opt, 'bootloader.extended_fuses');
		my $hfuse = $self -> board_config($opt, 'bootloader.high_fuses');
		my $lfuse = $self -> board_config($opt, 'bootloader.low_fuses');

		push @avrdude_opts, '-U', "efuse:w:$efuse:m" if $efuse;
		push @avrdude_opts, '-U', "hfuse:w:$hfuse:m" if $hfuse;
		push @avrdude_opts, '-U', "lfuse:w:$lfuse:m" if $lfuse;
	}

	push @avrdude_opts, '-U', "flash:w:$hex:i";

	die "Can't find file '$hex', did you run 'duino build'?\n"
		unless -e $hex;

	open my $fh, '<', $opt -> port
		or die "Can't open serial port '" . $opt -> port . "'.\n";

	my $fd = fileno $fh;

	my $term = POSIX::Termios -> new;
	$term -> getattr($fd);

	if ($self -> board_config($opt, 'bootloader.path') eq 'caterina') {
		$term -> setispeed(&POSIX::B1200);
		$term -> setospeed(&POSIX::B1200);

		$term -> setattr($fd, &POSIX::TCSANOW);
	} else {
		require Device::SerialPort;

		my $serial = Device::SerialPort -> new($opt -> port)
			or die "Can't open serial port '" . $opt -> port . "'.\n";

		$serial -> pulse_dtr_on(0.1 * 1000.0);
	}

	close $fh;

	sleep 1;

	system $avrdude, @avrdude_opts;
}

=head1 OPTIONS

=over 4

=item B<--board>, B<-b>

The Arduino board model. The environment variable C<ARDUINO_BOARD> will be used
if present and if the command-line option is not set. If neither of them is set
the default value (C<uno>) will be used.

=item B<--port>, B<-p>

The path to the Arduino serial port. The environment variable C<ARDUINO_PORT>
will be used if present and if the command-line option is not set. If neither
of them is set the default value (C</dev/ttyACM0>) will be used.

=item B<--fuses>, B<-f>

Whether to write the fuses bits when uploading. The environment variable
C<ARDUINO_FUSES> will be used if present and if the command-line option is not
set. If neither of them is set the default value (C<false>) will be used.

=item B<--uploader>, B<-u>

The uploader to use to upload. The environment variable C<ARDUINO_UPLOADER>
will be used if present and if the command-line option is not set. If neither
of them is set the default value specified in the C<boards.txt> file will be
used.

=item B<--sketchbook>, B<-s>

The path to the user's sketchbook directory. The environment variable
C<ARDUINO_SKETCHBOOK> will be used if present and if the command-line option is
not set. If neither of them is set the default value (C<$HOME/sketchbook>) will
be used.

=item B<--root>, B<-d>

The path to the Arduino installation directory. The environment variable
C<ARDUINO_DIR> will be used if present and if the command-line option is not
set. If neither of them is set the default value (C</usr/share/arduino>) will
be used.

=item B<--hardware>, B<-r>

The "type" of hardware to target. The environment variable C<ARDUINO_HARDWARE>
will be used if present and if the command-line option is not set. If neither
of them is set the default value (C<arduino>) will be used.

This option is only useful when using MCUs not officially supported by the
Arduino platform (e.g. L<ATTiny|https://code.google.com/p/arduino-tiny/>).

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

1; # End of App::duino::Command::upload
