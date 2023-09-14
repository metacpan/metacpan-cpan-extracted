#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::UseVERSION 0.03
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that every perl file contains 'use VERSION'";
use constant SORT => 10;

=head1 NAME

C<App::perl::distrolint::Check::UseVERSION> - check that every perl file contains C<use VERSION>

=head1 DESCRIPTION

This checks that every Perl source code file contains a C<use VERSION>
declaration as its first significant statement. A C<package> statement is
permitted before this, but no other code is allowed.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => $app );
}

method check_file ( $file, $app )
{
   my $tree = $self->parse_perl_file( $file );

   my $ok = 1;
   my $has_use_version;

   # Not using walk_each_statement because we only care about toplevel
   # statements

   foreach my $node ( $tree->root_node->child_nodes ) {
      next if $node->is_extra;

      if( $node->is_named and $node->type eq "use_version_statement" ) {
         my $version = $node->child_by_field_name( 'version' );

         $has_use_version = 1;
         next;
      }
      # We permit package statements
      elsif( $node->is_named and $node->type eq "package_statement" ) {
         next;
      }

      if( !$has_use_version ) {
         my $line = ( $node->start_point )[0] + 1;
         $app->diag( "%s line %d has a statement before use VERSION", $file, $line );
         $ok = 0;
         last;
      }
   }

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
