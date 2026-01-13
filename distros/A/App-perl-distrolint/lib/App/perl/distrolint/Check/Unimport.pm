#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::Unimport 0.09;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that if import exists then so does unimport";
use constant SORT => 20;

=head1 NAME

C<App::perl::distrolint::Check::Unimport> - check that a C<sub unimport> is defined if required

=head1 DESCRIPTION

This checks that if any package defines a C<sub import>, then it also defines
a C<sub unimport>. This helps to ensure that whatever effects the module
normally provides at import time can be undone by the C<no ...> syntax.
=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

my $QUERY = <<'EOF';
(subroutine_declaration_statement name: _ @name)
EOF

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   my $have_import;
   my $have_unimport;

   $self->walk_each_query_match( $QUERY, $tree->root_node, method ( $captures ) {
      my $subname = $captures->{name}->text;

      $have_import++   if $subname eq "import";
      $have_unimport++ if $subname eq "unimport";

      return 1;
   } );

   return 1 if $have_unimport or !$have_import;

   App->diag( App->format_file( $file ), " has sub import but no sub unimport" );
   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
