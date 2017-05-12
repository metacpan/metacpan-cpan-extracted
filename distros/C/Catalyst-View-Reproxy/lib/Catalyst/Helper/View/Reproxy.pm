package Catalyst::Helper::View::Reproxy;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::View::Reproxy - Helper class for Catalyst::View::Reproxy

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  ./script/myapp_create.pl view MyReproxy Reproxy

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    $helper->render_file( 'viewclass', $helper->{file} );
    return 1;
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-helper-view-reproxy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Reproxy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::View::Reproxy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Reproxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Reproxy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Reproxy>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Reproxy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Catalyst::Helper::View::Reproxy

__DATA__

=begin pod_to_ignore

__viewclass__

package [% class %];

use strict;
use warnings;

use base qw/Catalyst::View::Reproxy/;

=head1 NAME

[% class %] - Catalyst::View::Reproxy sub class.

=head1 SYNOPSIS

SEE L<[% app %]>

=head1 DESCRIPTION

SEE L<Catalyst::View::Reproxy>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
