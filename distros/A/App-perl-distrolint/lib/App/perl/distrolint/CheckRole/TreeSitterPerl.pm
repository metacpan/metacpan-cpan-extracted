#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

role App::perl::distrolint::CheckRole::TreeSitterPerl 0.01;

use Syntax::Keyword::Match;

use File::Slurper qw( read_text );
use Text::Treesitter;
use Text::Treesitter::Query;
use Text::Treesitter::QueryCursor 0.10;

=head1 NAME

C<App::perl::distrolint::CheckRole::TreeSitterPerl> - role for checks that parse Perl source code

=head1 DESCRIPTION

This role provides a number of helper methods for implementing check classes
that parse Perl source code, by using F<tree-sitter-perl>.

=cut

=head1 METHODS

=cut

my $TSPERL;

=head2 tree_sitter_perl

   $ts = $check->tree_sitter_perl;

Returns a singleton L<Text::Treesitter> instance configured for parsing the
Perl language, using F<tree-sitter-perl>.

=cut

method tree_sitter_perl
{
   return $TSPERL //= Text::Treesitter->new(
      lang_name => "perl",
   );
}

my %TREE_FOR_STRING;

=head2 parse_perl_string

   $tree = $check->parse_perl_string( $str );

Returns a cached L<Text::Treesitter::Tree> instance obtained by parsing the
given source string. As multiple checks may wish to inspect the same file, and
hence build the same tree, this will be cached and re-returned as necessary.

=cut

method parse_perl_string ( $str )
{
   return $TREE_FOR_STRING{ $str } //= $self->tree_sitter_perl->parse_string( $str );
}

=head2 parse_perl_file

   $tree = $check->parse_perl_file( $path );

A convenient shortcut for reading the text of the given path, then parsing it
using L</parse_perl_string>.

=cut

method parse_perl_file( $path )
{
   return $self->parse_perl_string( read_text $path );
}

=head2 walk_each_statement

   $ok = $check->walk_each_statement( $node, $method, @args );

      $ok = $self->$method( $child_node, @args );

A trampoline method that invokes the method on the given arguments on every
statement node found as a descendent of the node passed in.

Stops and returns false the first time the invoked method returns false, or
returns true if the invoked method returns true for every call.

=cut

method walk_each_statement ( $node, $method, @args )
{
   my $type = $node->is_named ? sprintf( "(%s)", $node->type ) : $node->type;

   match( $type : eq ) {
      # Containers of statements
      case("(source_file)"), case("(block)") {
         foreach my $kid ( $node->child_nodes ) {
            next if $node->is_extra;

            $self->walk_each_statement( $kid, $method, @args )
               or return 0;
         }

         return 1;
      }
      case("(phaser_statement)") {
         # Ugh, the grammar didn't name this with a field
         my ( $block ) = grep { $_->type eq "block" } $node->child_nodes;
         return $self->walk_each_statement( $block, $method, @args );
      }

      # Direct statements
      case if( $type =~ m/^\(.*_statement\)$/ ) {
         return $self->$method( $node, @args );
      }
   }
   return 1;
}

=head2 walk_each_query_match

   $ok = $check->walk_each_query_match( $src, $node, $method, @args );

      $ok = $self->$method( \%captures, @args );

A trampoline method that invokes the method on the given arguments on every
match of the given query source against the node passed in.

Stops and returns false the first time the invoked method returns false, or
returns true if the invoked method returns true for every call.

The invoked method is passed a reference to a hash, containing mappings from
capture names to the nodes of the tree that were captured by them.

=cut

my %QUERY_FOR_SRC;

method walk_each_query_match ( $src, $node, $method, @args )
{
   my $query = $QUERY_FOR_SRC{ $src } //= Text::Treesitter::Query->new(
      $self->tree_sitter_perl->lang, $src
   );

   my $qc = Text::Treesitter::QueryCursor->new;

   $qc->exec( $query, $node );

   while( my $captures = $qc->next_match_captures ) {
      $self->$method( $captures, @args ) or return 0;
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
