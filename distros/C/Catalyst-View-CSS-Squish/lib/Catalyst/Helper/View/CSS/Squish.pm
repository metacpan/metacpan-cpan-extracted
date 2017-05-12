package Catalyst::Helper::View::CSS::Squish;

use strict;

=head1 NAME

Catalyst::Helper::View::TT - Helper for CSS::Squish Views

=head1 SYNOPSIS

    script/create.pl view Squish CSS::Squish

=head1 DESCRIPTION

Helper for CSS::Squish Views.

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

Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::CSS::Squish';

=head1 NAME

[% class %] - Catalyst CSS::Squish View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Helper to create a Catalyst CSS::Squish View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
