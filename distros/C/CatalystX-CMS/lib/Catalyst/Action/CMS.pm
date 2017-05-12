package Catalyst::Action::CMS;
use strict;
use base 'CatalystX::CMS::Action';

=head1 NAME

Catalyst::Action::CMS - namespace holder for CatalystX::CMS::Action

=head1 SYNOPSIS

 # see CatalystX::CMS::Action

=head1 DESCRIPTION

This class is a simple subclass of CatalystX::CMS::Action. It exists
primarily to make it easy to do this:

 sub foo : ActionClass('CMS') {
  # ...
 }

in your controller classes when you have set C<actionclass_per_action>
in your B<cms> config.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
