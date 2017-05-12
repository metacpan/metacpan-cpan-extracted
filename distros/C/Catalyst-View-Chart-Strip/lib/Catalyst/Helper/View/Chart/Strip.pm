package Catalyst::Helper::View::Chart::Strip;

use strict;

=head1 NAME

Catalyst::Helper::View::Chart::Strip - Helper for Chart::Strip Views

=head1 SYNOPSIS

    script/create.pl view MyChartStrip Chart::Strip

=head1 DESCRIPTION

Helper for Chart::Strip Views.

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::Chart::Strip>,
L<Catalyst::View::Chart::Strip::Example>, L<Chart::Strip>,
L<Chart::Strip::Stacked>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::Chart::Strip';

__PACKAGE__->config(
    height => 192,
    width => 720,
    limit_factor => 1,
    transparent => 0,
);

=head1 NAME

[% class %] - Catalyst Chart::Strip View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Chart::Strip View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
