package App::duino::Command::models;
{
  $App::duino::Command::models::VERSION = '0.10';
}

use strict;
use warnings;

use App::duino -command;

=head1 NAME

App::duino::Command::models - List all known Arduino models

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  $ duino models

=head1 DESCRIPTION

This command can be used to list all known Arduino models.

=cut

sub abstract { 'list all known Arduino models' }

sub usage_desc { '%c models %o' }

sub opt_spec {
	my ($self) = @_;

	return (
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

	my $boards = $self -> file($opt, 'hardware/' .
			$opt -> hardware . '/boards.txt');

	open my $fh, '<', $boards
		or die "Can't open file 'boards.txt'.\n";

	print "Supported models:\n\n";

	while (my $line = <$fh>) {
		chomp $line;

		my $first = substr $line, 0, 1;

		next if $first eq '#' or $first eq '';
		next unless $line =~ /^(.*)\.name\=/;

		my $board = $1;

		my (undef, $value) = split '=', $line;

		printf "%10s: %s\n", $board, $value;
	}

	close $fh;
}

=head1 OPTIONS

=over 4

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

1; # End of App::duino::Command::models
