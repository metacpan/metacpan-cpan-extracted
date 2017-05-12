package Catalyst::Helper::View::Image::Text2Image;
use strict;

=head1 NAME

Catalyst::Helper::View::Image::Text2Image - Helper for Text2Image Views

=head1 SYNOPSIS

To create a Text2Image view in your Catalyst application, enter the following command:

 script/myapp_create.pl view Image::Text2Image Image::Text2Image

=head1 DESCRIPTION

Helper for Text2Image Views. Needed by catalyst create script.

=head1 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 AUTHOR

Martin Gillmaier, L<gillmaus at googlemail.com>

=head1 SEE ALSO

L<Catalyst::View::Image::Text2Image>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Martin Gillmaier (GILLMAUS), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This software comes "as it is" with absolutely no warranty.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use parent 'Catalyst::View::Image::Text2Image';

=head1 NAME

[% class %] - Text2Image View for [% app %]

=head1 DESCRIPTION

Text2Image View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself. This software comes "as it is" with absolutely no warranty.

=cut

1;
