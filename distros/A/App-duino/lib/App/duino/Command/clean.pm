package App::duino::Command::clean;
{
  $App::duino::Command::clean::VERSION = '0.10';
}

use strict;
use warnings;

use App::duino -command;

use File::Path qw(remove_tree);

=head1 NAME

App::duino::Command::clean - Clean the build directory

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  $ duino clean --board uno

=head1 DESCRIPTION

This command can be used to clean the build directory for a specific Arduino
board.

=cut

sub abstract { 'clean the build directory' }

sub usage_desc { '%c clean %o' }

sub opt_spec {
	my ($self) = @_;

	return (
		[ 'board|b=s', 'specify the board model',
			{ default => $self -> default_config('board') } ],
	);
}

sub is_folder_empty {
	my $dir = shift;

	opendir my $dh, $dir or return 0;
	return !grep { not /^\.+$/ } readdir $dh;
}

sub execute {
	my ($self, $opt, $args) = @_;

	my $board_name = $opt -> board;

	remove_tree(".build/$board_name/");
	remove_tree(".build") if is_folder_empty(".build");
}

=head1 OPTIONS

=over 4

=item B<--board>, B<-b>

The Arduino board model. The environment variable C<ARDUINO_BOARD> will be used
if present and if the command-line option is not set. If neither of them is set
the default value (C<uno>) will be used.

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

1; # End of App::duino::Command::clean
