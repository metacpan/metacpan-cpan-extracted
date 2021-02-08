package Catalyst::Helper::View::CSV;

use strict;
use warnings;

our $VERSION = "1.8";

=head1 NAME

Catalyst::Helper::View::CSV - Helper for CSV views

=head1 SYNOPSIS

    script/create.pl view CSV CSV

=head1 DESCRIPTION

Helper for CSV views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    ( my $self, my $helper ) = @_;

    my $file = $helper->{file};
    $helper->render_file ( "compclass", $file );
}

=head1 SEE ALSO

L<Catalyst::View::CSV>, L<Catalyst::Manual>, L<Catalyst::Helper>

=cut

1;

__DATA__

__compclass__
package [% class %];

use base qw ( Catalyst::View::CSV );
use strict;
use warnings;

__PACKAGE__->config ( sep_char => "," );

=head1 NAME

[% class %] - CSV view for [% app %]

=head1 DESCRIPTION

CSV view for [% app %]

=head1 SEE ALSO

L<[% app %]>, L<Catalyst::View::CSV>, L<Text::CSV>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
