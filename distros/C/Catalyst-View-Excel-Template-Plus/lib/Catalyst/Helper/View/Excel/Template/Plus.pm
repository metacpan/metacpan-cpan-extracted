package Catalyst::Helper::View::Excel::Template::Plus;

use strict;
use warnings;

use Carp qw/ croak /;

=head1 NAME

Catalyst::Helper::View::Excel::Template::Plus - Helper Class for Catalyst::View::Excel::Template::Plus

=head1 SYNOPSIS

    MyApp_create.pl view Excel Excel::Template::Plus

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;

    $helper->render_file( 'compclass', $helper->{file} );
}


=head1 AUTHOR

Robert Bohne E<lt>rbo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__DATA__
=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use warnings;

use base qw/Catalyst::View::Excel::Template::Plus/;

=head1 NAME

[% class %] - Excel::Plus View for [% app %]

=head1 SEE ALSO

See L<[% app %]>.

=head1 DESCRIPTION

Catalyst Catalyst::View::Excel::Template::Plus View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;