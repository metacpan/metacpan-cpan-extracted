#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::NoStrictRefs 0.06;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "forbid the use of no strict 'refs'";
use constant SORT => 12;

use List::Util qw( any );

=head1 NAME

C<App::perl::distrolint::Check::NoStrictRefs> - forbid the use of C<no strict 'refs'>

=head1 DESCRIPTION

This checks that no Perl source code file contains a C<no strict> declaration
that turns off the C<refs> stricture.

This is generally considered an anti-pattern that should be replaced by uses
of the L<meta> metaprogramming module, or more specialised things such as
L<Object::Pad::MOP>.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

my $QUERY = <<'EOF';
(use_statement
   "no"
   module: _ @module (#eq? @module "strict"))
   @statement
EOF

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   return 0 unless $self->walk_each_query_match( $QUERY, $tree->root_node, method ( $captures ) {
      my $node = $captures->{statement};
      my @imports = $self->extract_use_module_imports( $node );

      my $has_refs = !@imports || any { $_ eq "refs" } @imports;
      $has_refs or return 1;

      App->diag( App->format_file( $file, $node->start_row + 1 ), " has " . App->format_literal( $node->text ) );

      return 0;
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
