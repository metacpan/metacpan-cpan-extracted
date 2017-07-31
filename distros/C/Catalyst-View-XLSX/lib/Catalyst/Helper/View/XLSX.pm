package Catalyst::Helper::View::XLSX;

use strict;
use warnings;

our $VERSION = "1.2";

=head1 NAME

Catalyst::Helper::View::XLSX - Helper for XLSX views

=head1 SYNOPSIS

    script/create.pl view XLSX XLSX

=head1 DESCRIPTION

Helper for XLSX views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    ( my $self, my $helper ) = @_;

    my $file = $helper->{file};
    $helper->render_file ( "compclass", $file );
}

=head1 SEE ALSO

L<Catalyst::View::XLSX>, L<Catalyst::Manual>, L<Catalyst::Helper>

=cut

1;

__DATA__

__compclass__
package [% class %];

use base qw ( Catalyst::View::XLSX );
use strict;
use warnings;

=head1 NAME

[% class %] - XLSX view for [% app %]

=head1 DESCRIPTION

XLSX view for [% app %]

=head1 SEE ALSO

L<[% app %]>, L<Catalyst::View::XLSX>, L<Text::XLSX>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
