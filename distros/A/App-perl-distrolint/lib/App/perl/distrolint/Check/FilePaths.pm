#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::FilePaths 0.09;

apply App::perl::distrolint::CheckRole::EachFile;

use constant DESC => "check that filename paths appear to be sensible";
use constant SORT => 9;

=head1 NAME

C<App::perl::distrolint::Check::FilePaths> - check that file paths are sensible

=head1 DESCRIPTION

This checks that path names of files appear to be sensible.

Currently the only check per filename is that it does not contain a C<:>
symbol, as this will upset Windows filesystems.

=cut

method run ( $app )
{
   return $self->run_for_each_file( check_file => );
}

method check_file ( $file )
{
   $file =~ m/:/ and
      App->diag( App->format_file( $file ), " is named with ':' which will upset Windows" ), return 0;

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
