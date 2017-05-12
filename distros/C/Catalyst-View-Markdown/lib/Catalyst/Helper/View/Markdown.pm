package Catalyst::Helper::View::Markdown;

use strict;

=head1 NAME

Catalyst::Helper::View::Markdown - Helper for Markdown Views

=head1 SYNOPSIS

    script/create.pl view MD Markdown

=head1 DESCRIPTION

Helper for Markdown Views.

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

Richard Wallman, C<wallmari@bossolutions.co.uk>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Markdown';

__PACKAGE__->config(
    FILENAME_EXTENSION => '.md',
);

=head1 NAME

[% class %] - Markdown View for [% app %]

=head1 DESCRIPTION

Markdown View for [% app %].

=head1 SEE ALSO

L<[% app %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
