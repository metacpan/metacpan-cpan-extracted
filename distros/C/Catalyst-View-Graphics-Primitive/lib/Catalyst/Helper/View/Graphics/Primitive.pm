package Catalyst::Helper::View::Graphics::Primitive;
use strict;

=head1 NAME

Catalyst::Helper::View::Graphics::Primitive - Helper for Graphics::Primitive Views

=head1 SYNOPSIS

    script/create.pl view GP Graphics::Primitive

=head1 DESCRIPTION

Helper for Graphics::Primitive Views.

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Graphics::Primitive>

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

Infinity Interactive, L<http://www.iinteractive.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::Graphics::Primitive';

__PACKAGE__->config(
);

=head1 NAME

[% class %] - Catalyst Graphics::Primitive View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Graphics::Primitive View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut