package Catalyst::Helper::View::Jemplate;

use strict;

=head1 NAME

Catalyst::Helper::View::Jemplate - Helper for Jemplate Views

=head1 SYNOPSIS

    script/create.pl view Jemplate Jemplate

=head1 DESCRIPTION

Helper for Jemplate Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Jemplate>

=head1 AUTHOR

Tatsuhiko Miyagawa, C<miyagawa@bluknews.net>
Daisuke Maki, C<daisuke@endeworks.jp>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::Jemplate';

=head1 NAME

[% class %] - Jemplate View for [% app %]

=head1 DESCRIPTION

Jemplate View for [% app %]. 

=head1 AUTHOR

=head1 SEE ALSO

L<[% app %]>

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;