package Catalyst::Helper::View::HTML::CTPP2;

use strict;

=head1 NAME

Catalyst::Helper::View::HTML::CTPP2 - Helper for HTML::CTPP2 Views

=head1 SYNOPSIS

    script/create.pl view HTML::CTPP2 HTML::CTPP2

=head1 DESCRIPTION

Helper for HTML::CTPP2 Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ($self, $helper) = @_;
    my $file = $helper->{file};
    $helper->render_file('compclass', $file);
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Victor Elfimov (victor@sols.ru)

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::HTML::CTPP2';

=head1 NAME

[% class %] - CTPP2 View for [% app %]

=head1 DESCRIPTION

CTPP2 View for [% app %].

=head1 SEE ALSO

L<[% app %]>, L<HTML::CTPP2>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

