package Catalyst::Plugin::Flavour::Data;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

use overload (
    q{""} => sub { shift->flavour },
);

__PACKAGE__->mk_accessors(qw/fn flavour year month day/);

*yr = \&year;
*mo = \&month;
*da = \&day;

=head1 NAME

Catalyst::Plugin::Flavour::Data - Flavour data class

=head1 SEE ALSO

L<Catalyst::Plugin::Flavour>

=head1 AUTHOR

Daisuke Murase E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
