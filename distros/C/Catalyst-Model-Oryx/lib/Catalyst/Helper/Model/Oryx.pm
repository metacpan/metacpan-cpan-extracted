package Catalyst::Helper::Model::Oryx;

use strict;

=head1 NAME

Catalyst::Helper::Model::Oryx - Helper for Oryx Model

=head1 SYNOPSIS

    script/create.pl model Oryx Oryx

=head1 DESCRIPTION

Helper for Oryx Model

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::Oryx>,
L<Oryx>, L<Oryx::Class>

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 THANKS TO

Sebastian Riedel for graciously letting me borrow his C<mk_compclass>
method as well as most of the pod in this module.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;

use base qw(Catalyst::Model::Oryx);

# CHANGE ME!
__PACKAGE__->config(
    dsname => 'dbm:Deep:datapath=/tmp',
    usname => '',
    passwd => '',
);

=head1 NAME

[% class %] - Oryx Model Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Oryx Model Component. This module holds the connection
details which are passed to C<connect()>.

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
