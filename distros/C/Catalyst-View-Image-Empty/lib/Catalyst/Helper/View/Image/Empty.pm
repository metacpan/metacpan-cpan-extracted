package Catalyst::Helper::View::Image::Empty;

use strict;
use warnings; 
 
=head1 NAME

Catalyst::Helper::View::Image::Empty - Helper for Empty Image Views

=head1 SYNOPSIS

To create an empty GIF/PNG view in your Catalyst application, enter the following command:

 script/myapp_create.pl view Image::Empty Image::Empty

=head1 DESCRIPTION

Helper for empty GIF/PNG Views. Needed by catalyst create script.

=head1 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 AUTHOR

Rob Brown, L<rob at intelcompute.com>

=head1 SEE ALSO

L<Catalyst::View::Image::empty>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use base 'Catalyst::View::Image::Empty';

__PACKAGE__->config(

);

=head1 NAME

[% class %] - Empty GIF/PNG View for [% app %]

=head1 DESCRIPTION

Empty GIF/PNG View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself. This software comes "as it is" with absolutely no warranty.

=cut

1;