package App::GUI::Notepad;

use 5.005;
use strict;
use Data::Dumper;
use Wx; 
use base qw/Wx::App/;
use App::GUI::Notepad::Frame;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

sub OnInit {
	my ($this) = @_;

	Wx::InitAllImageHandlers();
	my ($frame) = App::GUI::Notepad::Frame->new(
		"Perlpad",
		Wx::Point->new( 50, 50 ),
		Wx::Size->new( 450, 350 )
		);
	$this->{frame} = $frame;

	$this->SetTopWindow($frame);
	$frame->Show(1);

	$this;
}

1;

=pod

=head1 NAME

App::GUI::Notepad - A wxPerl-based notepad text editor application

=head1 DESCRIPTION

This package implements a wxWindows desktop application which provides the
ability to do rudimentary text file editing.

The C<App::GUI::Notepad> module implements the application, but is itself of no
use to the user. The launcher for the application 'perlpad' is installed
with this module, and can be launched by simply typing the following from
the command line.

  perlpad

When launched, the application looks and acts like a very simple rendition of 
Notepad from Windows.  Currently you can create new files and save files and 
perform the usual edit functions (Undo, Redo, Cut, Copy and Paste)

( It's early days yet for this application ).

=head1 TO DO

- Add the typical features found in most editors these days.


=head1 SUPPORT

Bugs should B<always> be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-GUI-Notepad>

For general comments, contact the author.


=head1 AUTHOR

Ben Marsh E<lt>blm@woodheap.orgE<gt>

Created with the valuable assistance of Adam Kennedy E<lt>cpan@aliasE<gt> 


=head1 SEE ALSO

L<App::GUI::Notepad::Frame>, L<App::GUI::Notepad::MenuBar>

=head1 COPYRIGHT

Copyright (c) 2005 Ben Marsh, Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

