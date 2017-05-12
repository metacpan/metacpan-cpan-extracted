package Catalyst::Helper::View::GraphViz;

use strict;

=head1 NAME

Catalyst::Helper::View::GraphViz - Helper for GraphViz Views

=head1 SYNOPSIS

    script/create.pl view GraphViz GraphViz

=head1 DESCRIPTION

Helper for GraphViz Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Johan Lindstrom, C<johanl@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::GraphViz';

=head1 NAME

[% class %] - Catalyst GraphViz View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst GraphViz View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
