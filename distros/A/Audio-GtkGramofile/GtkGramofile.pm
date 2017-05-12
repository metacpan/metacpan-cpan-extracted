package Audio::GtkGramofile;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';

1;
__END__

=head1 NAME

Audio::GtkGramofile - a Gtk2-Perl interface to libgramofile. 

=head1 SYNOPSIS

  use Audio::GtkGramofile;

=head1 DESCRIPTION

This is a collection of modules, which enable the Gtk2 interface 
to libgramofile, gtkgramofile. That script is provided within this
module. The individual modules are 

Audio::GtkGramofile::GUI - a set of routines which provide the Gtk2 interface.

Audio::GtkGramofile::Logic - the underlying logic to enable the application.

Audio::GtkGramofile::Signals - the signal handlers for the GUI.

Audio::GtkGramofile::Settings - holds the current state of selections made.

=head1 SEE ALSO

Audio::Gramofile, libgramofile at http://sourceforge.net/projects/libgramofile/
Gramofile at http://www.opensourcepartners.nl/~costar/gramofile/

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Bob Wilkinson, E<lt>bob@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Bob Wilkinson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
