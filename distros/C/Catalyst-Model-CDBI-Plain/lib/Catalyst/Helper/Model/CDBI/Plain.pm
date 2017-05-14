package Catalyst::Helper::Model::CDBI::Plain;

use strict;

=head1 NAME

Catalyst::Helper::Model::CDBI::Plain - Helper for CDBI Plain Model

=head1 SYNOPSIS

    script/create.pl model CDBI CDBI::Plain dsn user password

=head1 DESCRIPTION

Help for CDBI Plain Model.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $dsn, $user, $pass ) = @_;
    $helper->{dsn}  = $dsn  || '';
    $helper->{user} = $user || '';
    $helper->{pass} = $pass || '';    
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Andy Grundman, C<andy@hybridized.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::CDBI::Plain';

__PACKAGE__->connection('[% dsn %]', '[% user %]', '[% pass %]');

=head1 NAME

[% class %] - CDBI Plain Model Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

CDBI Plain Model Component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
