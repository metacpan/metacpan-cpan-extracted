package Catalyst::Helper::View::BK;

use strict;

=head1 NAME

Catalyst::Helper::View::BK - Helper for BK Views

=head1 SYNOPSIS

    script/create.pl view BK BK

=head1 DESCRIPTION

Helper for BK Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ($self, $helper ) = @_;
    my $classfile = $helper->{file};
    $helper->render_file('subclass', $classfile);
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Jeremy Wall, C<jeremy@marzhillstudios.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__subclass__
package [% class %];

use strict;
use base 'Catalyst::View::BK';

=head1 NAME

[% class %] - BK View for [% app %]

=head1 DESCRIPTION

BK View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
