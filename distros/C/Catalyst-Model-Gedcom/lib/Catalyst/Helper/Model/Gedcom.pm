package Catalyst::Helper::Model::Gedcom;

use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

Catalyst::Helper::Model::Gedcom - Helper for Gedcom models

=head1 SYNOPSIS

  script/myapp_create.pl model Gedcom Gedcom myfamily.ged

=head1 DESCRIPTION

Helper for the C<Catalyst> Gedcom model.

=head1 METHODS

=head2 mk_compclass

Makes the Gedcom model class.

=cut

sub mk_compclass {
    my ( $self, $helper, $filename ) = @_;

    die( 'No filename specified' ) unless $filename;

    $helper->{ filename } = $filename;
    $helper->render_file( 'modelclass', $helper->{ file } );

    return 1;
}

=head2 mk_comptest

Makes tests for the Gedcom model.

=cut

sub mk_comptest {
    my ( $self, $helper ) = @_;

    $helper->render_file( 'modeltest', $helper->{ test } );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Helper>

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

__DATA__

__modelclass__
package [% class %];

use strict;
use base qw( Catalyst::Model::Gedcom );

__PACKAGE__->config(
    gedcom_file => [% filename %],
    read_only   => 1
);

=head1 NAME

[% class %] - Gedcom Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Gedcom Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use Test::More tests => 2;
use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
