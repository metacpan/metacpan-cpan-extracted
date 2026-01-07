#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::PerlVersionVar 0.08;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that perl files use \$] correctly";
use constant SORT => 12;

=head1 NAME

C<App::perl::distrolint::Check::PerlVersionVar> - check for bad use of C<$]>

=head1 DESCRIPTION

The special Perl variable C<$]> contains the Perl version number, formatted as
a regular floating-point integer. Comparisons on this variable should be done
using numerical operators (C<< >= >> etc) rather than stringy ones
(C<ge> etc). This checker ensures any comparisons use the former kind, and not
the latter.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

# We can't do "either left or right" in tree-sitter queries, but we can do two
# separate queries that match each case
my $QUERY = <<'EOF';
(relational_expression
   left: _ @left (#eq? @left "$]")
   operator: _ @operator (#any-of? @operator "eq" "ne" "lt" "le" "ge" "gt" "cmp"))
   @expression

(relational_expression
   operator: _ @operator (#any-of? @operator "eq" "ne" "lt" "le" "ge" "gt" "cmp")
   right: _ @right (#eq? @right "$]"))
   @expression
EOF

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   return 0 unless $self->walk_each_query_match( $QUERY, $tree->root_node, method ( $captures ) {
      my $node = $captures->{expression};

      App->diag( App->format_file( $file, $node->start_row + 1 ), " applies stringy comparison operator to ", App->format_literal( '$]' ) );
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
