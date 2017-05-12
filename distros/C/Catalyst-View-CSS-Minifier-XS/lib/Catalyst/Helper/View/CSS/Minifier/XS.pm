package Catalyst::Helper::View::CSS::Minifier::XS;
{
  $Catalyst::Helper::View::CSS::Minifier::XS::VERSION = '2.000002';
}

use strict;


sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}


1;

=pod

=head1 NAME

Catalyst::Helper::View::CSS::Minifier::XS

=head1 VERSION

version 2.000002

=head1 SYNOPSIS

    script/create.pl view CSS CSS::Minifier::XS

=head1 DESCRIPTION

Helper for CSS::Minifier::XS views

=head2 METHODS

=head3 mk_compclass

=head1 NAME

Catalyst::Helper::View::CSS::Minifier::XS - Helper for CSS::Minifier::XS views

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>

=head1 AUTHORS

=over 4

=item *

Ivan Drinchev <drinchev (at) gmail (dot) com>

=item *

Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Drinchev <drinchev (at) gmail (dot) com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::View::CSS::Minifier::XS';

1;
