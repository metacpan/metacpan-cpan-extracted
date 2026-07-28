package Catalyst::Helper::View::Wkhtmltopdf;

use strict;
use warnings;

our $VERSION = 'v0.6.3';


sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}


1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::View::Wkhtmltopdf

=head1 VERSION

version v0.6.3

=head1 SYNOPSIS

    script/create.pl view Wkhtmltopdf Wkhtmltopdf

=head1 DESCRIPTION

Helper for Wkhtmltopdf Views.

=head1 METHODS

=head2 mk_compclass

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Catalyst-View-Wkhtmltopdf>
and may be cloned from L<https://github.com/robrwo/Catalyst-View-Wkhtmltopdf.git>

=head1 SUPPORT

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-View-Wkhtmltopdf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michele Beltrame <mb@italpro.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2018, 2026 by Michele Beltrame <mb@italpro.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__compclass__
package [% class %];
use Moose;

extends 'Catalyst::View::Wkhtmltopdf';

=head1 NAME

[% class %] - Catalyst Wkhtmltopdf View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Wkhtmltopdf View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
