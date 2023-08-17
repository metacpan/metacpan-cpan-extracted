#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::VersionVar 0.02
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that no perl file sets 'our \$VERSION'";
use constant SORT => 12;

=head1 NAME

C<App::perl::distrolint::Check::VersionVar> - check that no file sets C<our $VERSION>

=head1 DESCRIPTION

This checks that no Perl source file contains a statement that would directly
affect a package variable called C<$VERSION>; in effect ensuring that any
module version numbers are set only with the new C<package NAME VERSION>
syntax of Perl v5.14.
=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => $app );
}

method check_file ( $file, $app )
{
   my $tree = $self->parse_perl_file( $file );

   return $self->walk_each_statement( $tree->root_node, check_statement => $file, $app );
}

method check_statement ( $node, $file, $app )
{
   my ( $expr ) = $node->child_nodes;
   return 1 unless $expr->type eq "assignment_expression";

   my $lhs = $expr->child_by_field_name( "left" );

   my @vars;

   if( $lhs->type eq "variable_declaration" ) {
      if( my $var = $lhs->try_child_by_field_name( "variable" ) ) {
         @vars = ( $var );
      }
      elsif( my $varlist = $lhs->try_child_by_field_name( 'variables' ) ) {
         foreach my $var ( $varlist->child_nodes ) {
            push @vars, $var if $var->type eq "scalar";
         }
      }
      else {
         return 1;
      }
   }
   elsif( $lhs->type eq "scalar" ) {
      @vars = ( $lhs );
   }
   else {
      return 1;
   }

   foreach my $var ( @vars ) {
      next unless $var->text eq '$VERSION';

      my $line = ( $node->start_point )[0] + 1;
      $app->diag( "%s line %d has an assignment to \$VERSION", $file, $line );
      return 0;
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
