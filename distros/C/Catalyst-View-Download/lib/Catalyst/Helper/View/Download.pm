package Catalyst::Helper::View::Download;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::View::Download - Helper for Download Views

=head1 SYNOPSIS

    script/create.pl view Download Download

=head1 DESCRIPTION

Helper for Download Views.

=head1 METHODS

=head2 mk_compclass

see L<Catalyst::Helper>

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::View::Download>

=head1 AUTHOR

Travis Chase, C<< <gaudeon at cpan dot org> >>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Download';

=head1 NAME

[% class %] - Download View for [% app %]

=head1 DESCRIPTION

Download View for [% app %].

=head1 SEE ALSO

L<[% app %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
