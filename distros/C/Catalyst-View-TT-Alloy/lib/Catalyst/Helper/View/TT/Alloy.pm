#!/bin/false

use strict;
package Catalyst::Helper::View::TT::Alloy;
$Catalyst::Helper::View::TT::Alloy::VERSION = '0.00007';
=head1 NAME

Catalyst::Helper::View::TT::Alloy - Helper for Template::Alloy Views

=head1 VERSION

version 0.00007

=head1 SYNOPSIS

    script/create.pl view TT::Alloy TT::Alloy

=head1 DESCRIPTION

Helper for Template::Alloy Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::View::TT::Alloy>, L<Template::Alloy>, L<Catalyst::Manual>

=head1 AUTHORS

Carl Franks, C<cfranks@cpan.org>

Based on the code of C<Catalyst::Helper::TT::Alloy>, by

Sebastian Riedel, C<sri@oook.de>

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
use parent 'Catalyst::View::TT::Alloy';

1;

__END__

=head1 NAME

[% class %] - TT::Alloy View for [% app %]

=head1 DESCRIPTION

TT::Alloy View for [% app %].

=head1 AUTHOR

=head1 SEE ALSO

L<[% app %]>

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
