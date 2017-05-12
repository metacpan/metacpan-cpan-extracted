package Curses::UI::Mousehandler::GPM;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( gpm_enable gpm_get_mouse_event );

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Curses::UI::Mousehandler::GPM', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Curses::UI::Mousehandler::GPM - Curses::UI GPM Bindings

=head1 SYNOPSIS

  use Curses::UI::Mousehandler::GPM;

  if (gpm_enable) {
    print "Succesfully enabled GPM mouse events\n";
  } else {
    print "Couldn't enable GPM mouse events\n";
  }

  while (1) {
    my $MEVENT = gpm_get_mouse_event();
    if ($MEVENT) {
	my ($id, $x, $y, $z, $bstate) = unpack("sx2i3l", $MEVENT);
	my %MEVENT = (
		      -id     => $id,
		      -x      => $x,
		      -y      => $y,
		      -bstate => $bstate
		      );
	print "Got mouse event at $x,$y\n";
    }
  }

=head1 REQUIREMENTS

You will need curses.h (from a curses-devel package) and gpm.h 
(from a gpm-devel or libgpm-devel package) in order to compile.
Libgpm is needed to bind against it. A running GPM is not really
needed but might be usefull :-).

=head1 DESCRIPTION

Curses::UI::Mousehandler::GPM is a module to allow GPM style mouse
events in Curses::UI. 

=head1 EXPORT

=over 4

=item B<gpm_enable>

Tries to connect to GPM. Returns a true value on success, false 
otherwise.

=item B<gpm_get_mouse_event>

Selects for a mouse event in the GPM queue and returns it in an
ncurses compatible MEVENT struct. If no mouse event is found
undef will be returned. The call is non blocking.

=back

=head1 SEE ALSO

L<ncurses(3NCURSES)>
L<gpm(8)>

=head1 AUTHOR

Marcus Thiesen, E<lt>marcus@thiesen.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Marcus Thiesen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
