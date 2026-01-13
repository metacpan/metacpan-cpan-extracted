#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::UseVERSION 0.09;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use Text::Treesitter 0.07; # child_by_field_name

use App::perl::distrolint::Config;

use constant DESC => "check that every perl file contains 'use VERSION'";
use constant SORT => 10;

=head1 NAME

C<App::perl::distrolint::Check::UseVERSION> - check that every perl file contains C<use VERSION>

=head1 DESCRIPTION

This checks that every Perl source code file contains a C<use VERSION>
declaration as its first significant statement. A C<package> statement is
permitted before this, but no other code is allowed.

=head1 CONFIGURATION

=for highlighter language=ini

The following extra configuration may be added to the C<[check UseVERSION]>
section of F<distrolint.ini>:

=head2 min_version

   min_version = v5.NN

If present, the C<use VERSION> declaration at the start of every checked Perl
source file must be at least this given version. If a version number lower is
found then the check fails.

The minimum version part of the check does not apply to F<Build.PL> or
F<Makefile.PL> as those files should remain runnable by any version of Perl.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   my $min_version = App::perl::distrolint::Config->check_config(
      $self, "min_version", undef
   );
   defined $min_version and $min_version = version->new( $min_version );

   my $ok = 1;
   my $has_use_version;

   # Not using walk_each_statement because we only care about toplevel
   # statements

   foreach my $node ( $tree->root_node->child_nodes ) {
      next if $node->is_extra;

      if( $node->is_named and $node->type eq "use_version_statement" ) {
         my $version_node = $node->child_by_field_name( 'version' );

         if( defined $min_version ) {
            my $version = version->new( $version_node->text );

            if( $version lt $min_version and not(
                  $file eq "Build.PL" or $file eq "Makefile.PL" ) ) {
               App->diag( App->format_file( $file, $version_node->start_row + 1 ), " has a 'use VERSION' of only $version" );
               $ok = 0;
            }
         }

         $has_use_version = 1;
         next;
      }
      # We permit package statements
      elsif( $node->is_named and $node->type eq "package_statement" ) {
         next;
      }

      if( !$has_use_version ) {
         App->diag( App->format_file( $file, $node->start_row + 1 ), " has a statement before use VERSION" );
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
