package App::duino::Command;
{
  $App::duino::Command::VERSION = '0.10';
}

use strict;
use warnings;

use App::Cmd::Setup -command;

use File::Basename;
use Config::INI::Reader;

=head1 NAME

App::duino::Command - Base class for App::duino commands

=head1 VERSION

version 0.10

=cut

sub ini {
	my ($self, $config) = @_;

	if (-e 'duino.ini') {
		my $cfg = Config::INI::Reader -> read_file('duino.ini');
		return $cfg -> {'_'} -> {$config};
	}

	return undef;
}

sub default_config {
	my ($self, $config) = @_;

	return $self -> ini($config) || $ENV{'ARDUINO_BOARD'} || 'uno'
		if $config eq 'board';

	return $ENV{'ARDUINO_PORT'}  || '/dev/ttyACM0'
		if $config eq 'port';

	return $ENV{'ARDUINO_FUSES'}  || 0
		if $config eq 'fuses';

	return $ENV{'ARDUINO_UPLOADER'}  || undef
		if $config eq 'uploader';

	return $self -> ini($config) || $ENV{'ARDUINO_LIBS'}  || ''
		if $config eq 'libs';

	return $ENV{'ARDUINO_SKETCHBOOK'} || "$ENV{'HOME'}/sketchbook"
		if $config eq 'sketchbook';

	return $ENV{'ARDUINO_ROOT'}   || '/usr/share/arduino'
		if $config eq 'root';

	return $self -> ini($config) || $ENV{'ARDUINO_HARDWARE'} || 'arduino'
		if $config eq 'hardware';
}

sub board_config {
	my ($self, $opt, $config) = @_;

	my $board = $opt -> board;

	my $boards = $self -> file($opt, 'hardware/' .
			$opt -> hardware . '/boards.txt');

	open my $fh, '<', $boards
		or die "Can't open file 'boards.txt'.\n";

	my $value = undef;

	while (my $line = <$fh>) {
		chomp $line;

		my $first = substr $line, 0, 1;

		next if $first eq '#' or $first eq '';
		next unless $line =~ /^$board\.$config\=/;

		(undef, $value) = split '=', $line;
	}

	close $fh;

	return $value;
}

sub file {
	my ($self, $opt, $file) = @_;

	my $path = $opt -> root . '/' . $file;
	return $path if -e $path;

	die "Can't find file '" . basename($file) . "'.\n";
}

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::duino::Command
