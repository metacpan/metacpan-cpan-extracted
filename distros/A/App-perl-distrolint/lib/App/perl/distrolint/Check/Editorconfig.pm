#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::Editorconfig 0.07;

use constant DESC => "check that .editorconfig exists";
use constant SORT => 5;

=head1 NAME

C<App::perl::distrolint::Check::Editorconfig> - check that a F<.editorconfig> file exists

=head1 DESCRIPTION

This checks that a file called F<.editorconfig> exists in the distribution
directory.

The contents of such a file are described in more detail at
L<https://editorconfig.org/>

=cut

method run
{
   return -e ".editorconfig";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
