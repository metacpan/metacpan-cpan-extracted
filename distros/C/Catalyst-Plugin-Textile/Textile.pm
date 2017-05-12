package Catalyst::Plugin::Textile;

use strict;
use base 'Class::Data::Inheritable';
use Text::Textile;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('textile');
__PACKAGE__->textile( Text::Textile->new );

=head1 NAME

Catalyst::Plugin::Textile - Textile for Catalyst

=head1 SYNOPSIS

    # include it in plugin list
    use Catalyst qw/Textile/;

    my $html = $c->textile->process($text);

=head1 DESCRIPTION

Persistent Textile processor for Catalyst.

=head2 METHODS

=head3 $c->textile;

Returns a ready to use L<Text::Textile> object.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Text::Textile>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
