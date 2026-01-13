#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::PostfixDeref 0.09;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use List::Util 1.29 qw( any first );

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that postfix deref is used if enabled";
use constant SORT => 25;

=head1 NAME

C<App::perl::distrolint::Check::PostfixDeref> - check that postfix dereference syntax is used

=head1 DESCRIPTION

This checks that for every Perl source file in F<lib/>, that any dereference
expression made inside a scope that has the C<postderef> feature enabled is
actually written using postfix dereference syntax. That said, it fails if a
dereference expression using the older circumfix-style (such as C<@{ ... }>)
is found, if it lies inside a scope that specifically enables the feature.

This checker does not complain about circumfix dereference operators being
applied to string literal expressions, such as C<@{"This::Module::ISA"}>.
While technically it could be written using postfix-deref, this style is often
used for symbolic references, and the distinct visual style helps distinguish
them from regular data structure operations.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

my $QUERY = <<'EOF';
(use_version_statement)
   @use_version

(use_statement
   module: _ @module (#eq? @module "feature"))
   @use_module

[
   (scalar (varname (block (expression_statement) @expr)))
   (array  (varname (block (expression_statement) @expr)))
   (hash   (varname (block (expression_statement) @expr)))
] @deref
EOF

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   my $ok = 1;
   $self->walk_each_scoped_query_match( $QUERY, $tree->root_node, method ( $capture, $context ) {
      my $node;
      if( $node = $capture->{use_version} ) {
         my $version = version->new( $node->child_by_field_name( 'version' )->text );
         # 'use VERSION' doesn't actually enable the feature, but if the code is
         # asking for v5.24 or above, then the feature will always be available
         $context->{use_feature_postderef} = ( $version ge v5.24 );
      }
      elsif( $node = $capture->{use_module} ) {
         my $sense = ( $node->child_nodes )[0]->type eq "use";
         my @features = $self->extract_use_module_imports( $node );

         $context->{use_feature_postderef} = $sense
            if any { $_ eq "postderef" } @features;
      }
      elsif( $node = $capture->{deref} ) {
         my $type = uc $node->type;
         my ( $expr ) = $capture->{expr}->child_nodes;
         # If the expression is a string-literal or interpolated
         # string-literal, we think that's a symbolic reference and exempt
         my $is_symref = $expr->type eq "string_literal" ||
                         $expr->type eq "interpolated_string_literal";
         if( $context->{use_feature_postderef} and !$is_symref ) {
            App->diag( App->format_file( $file, $node->start_row + 1 ), " dereferences $type without postfix-deref" );
            $ok = 0;
         }
      }
      else {
         warn "TODO: Check <@{[ sort keys %$capture ]}> while use=$context->{use_feature_postderef}\n";
      }

      return 1; # check all
   } );

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
