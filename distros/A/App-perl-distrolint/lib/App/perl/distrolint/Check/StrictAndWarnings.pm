#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::StrictAndWarnings 0.02
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that every perl file sets strict and warnings";
use constant SORT => 11;

=head1 NAME

C<App::perl::distrolint::Check::StrictAndWarnings> - check that every perl file sets the C<strict> and C<warnings> pragmata

=head1 DESCRIPTION

This checks that for every Perl source code file, there are no significant
statements before both the C<strict> and C<warnings> pragmata are in effect.

A "significant statement" is considered to be most statements, with the
exception of any C<package> or C<use> statement, as these typically appear
right at the top of the file.

Either a C<use strict> or a C<use VERSION> with a version number set to v5.12
or higher are considered to enable C<strict>.

Either a C<use warning> or a C<use VERSION> with a version number set to v5.35
or higher are considered to enable C<warnings>.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => $app );
}

method check_file ( $file, $app )
{
   my $tree = $self->parse_perl_file( $file );

   my $ok = 1;
   my $has_strict;
   my $has_warnings;

   # Not using walk_each_statement because we only care about toplevel
   # statements

   foreach my $node ( $tree->root_node->child_nodes ) {
      next if $node->is_extra;

      if( $node->is_named and $node->type eq "use_version_statement" ) {
         my $version = version->new( $node->child_by_field_name( "version" )->text );

         $has_strict   = 1 if $version ge v5.12;
         $has_warnings = 1 if $version ge v5.35;

         next;
      }
      # We permit package statements
      elsif( $node->is_named and $node->type eq "package_statement" ) {
         next;
      }
      elsif( $node->is_named and $node->type eq "use_statement" ) {
         my $module = $node->child_by_field_name( "module" )->text;

         # TODO: Even   use strict ();  would keep this happy
         $has_strict   = 1, next if $module eq "strict";
         $has_warnings = 1, next if $module eq "warnings";

         # We permit any other use statement
         next;
      }

      if( !$has_strict or !$has_warnings ) {
         my $line = ( $node->start_point )[0] + 1;

         $app->diag( "%s line %d has a statement before use strict", $file, $line ) if !$has_strict;
         $app->diag( "%s line %d has a statement before use warnings", $file, $line ) if !$has_warnings;
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
