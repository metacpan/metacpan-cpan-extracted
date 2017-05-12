package Catalyst::Helper::View::JavaScript::Minifier::XS;
$Catalyst::Helper::View::JavaScript::Minifier::XS::VERSION = '2.102000';
use strict;
use warnings;



sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::View::JavaScript::Minifier::XS

=head1 VERSION

version 2.102000

=head1 SYNOPSIS

 script/create.pl view JavaScript JavaScript::Minifier::XS

=head1 NAME

Catalyst::Helper::View::JavaScript::Minifier::XS - Helper for JavaScript::Minifier::XS views

=head1 METHODS

=head2 mk_compclass

Internal method for generating the view.

=head1 AUTHORS

=over 4

=item *

Ivan Drinchev <drinchev (at) gmail (dot) com>

=item *

Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Drinchev <drinchev (at) gmail (dot) com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::View::JavaScript::Minifier::XS';

1;
