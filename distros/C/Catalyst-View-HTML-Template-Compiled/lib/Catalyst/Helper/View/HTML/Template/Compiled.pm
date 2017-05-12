package Catalyst::Helper::View::HTML::Template::Compiled;

use strict;
our $VERSION = '0.03';

=head1 NAME

Catalyst::Helper::View::HTML::Template::Compiled - Helper for HTML::Template::Compiled Views

=head1 SYNOPSIS

    script/myapp_create.pl view HTML::Template::Compiled HTML::Template::Compiled

=head1 DESCRIPTION

Helper for HTML::Template::Compiled Views.

=head1 METHODS

=over 4

=item mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=back

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sascha Kiefer, <esskar@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::HTML::Template::Compiled';

=head1 NAME

[% class %] - HTML::Template::Compiled View Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
