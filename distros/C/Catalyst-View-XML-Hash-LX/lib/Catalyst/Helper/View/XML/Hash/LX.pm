package Catalyst::Helper::View::XML::Hash::LX;

use strict;

=head1 NAME

Catalyst::Helper::View::XML::Hash::LX - Helper for XML View

=head1 SYNOPSIS

    script/create.pl view XML XML::Hash::LX

=head1 DESCRIPTION

Helper for XML Views.

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

Lindolfo Rodrigues de Oliveira Neto, C<lorn at cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::XML::Hash::LX';

=head1 NAME

[% class %] - Catalyst XML View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst XML View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
