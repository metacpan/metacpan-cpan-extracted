package Catalyst::Helper::Model::DBIC::Plain;

use strict;

=head1 NAME

Catalyst::Helper::Model::DBIC::Plain - Helper for DBIC Plain Model

=head1 SYNOPSIS

    script/create.pl model DBIC DBIC::Plain dsn user password

=head1 DESCRIPTION

Helper for the DBIC Plain Model.

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

Danijel Milicevic, C<info@danijel.de>

=head1 THANK YOU

Andy Grundman

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::DBIC::Plain';

my @conn_info = (
    '[% dsn %]',
    '[% user %]',
    '[% pass %]',
    { RaiseError => 1, PrintError => 0, ShowErrorStatement => 1, TraceLevel => 0 }
);

__PACKAGE__->load_classes;
__PACKAGE__->compose_connection( __PACKAGE__, @conn_info );

=head1 NAME

[% class %] - DBIC Plain Model Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

DBIC Plain Model Component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

