#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::POD 0.02
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use Text::Treesitter 0.10; # parse_string_range

use constant DESC => "check that every perl file contains some POD";
use constant SORT => 30;

use List::Util qw( any );

=head1 NAME

C<App::perl::distrolint::Check::POD> - check that every Perl source file contains documentation

=head1 DESCRIPTION

This checks that Perl source code files contain at least one block of POD.

Unit tests (named F<*.t>) and build-time generated source files (F<*.PL>) are
exempt from this check. Files in the F<examples/> directory are also skipped.

Additionally checks that each of the following C<=head1> sections appear:

   =head1 NAME
   =head1 DESCRIPTION
   =head1 AUTHOR

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => $app );
}

my $HEAD_QUERY = <<'EOF';
(head_paragraph
   (head_directive _ @directive) (#eq? @directive "=head1")
   _ @content)
EOF

method check_file ( $file, $app )
{
   # .t and .PL files don't need POD
   return 1 if $file =~ m/\.t$|\.PL$/;
   # Examples probably not either
   return 1 if $file =~ m/examples\//;

   my $tree = $self->parse_perl_file( $file );

   my @pod_nodes;

   $self->walk_each_query_match( '(pod) @pod', $tree->root_node, method ( $captures ) {
      push @pod_nodes, $captures->{pod};
   } );

   unless( @pod_nodes ) {
      $app->diag( "%s has no POD", $file );
      return 0;
   }

   state $TSPOD //= Text::Treesitter->new( lang_name => "pod" );

   my $text = $tree->text;

   my @head1_titles;

   foreach my $pod ( @pod_nodes ) {
      my $podtree = $TSPOD->parse_string_range( $text,
         start_byte => $pod->start_byte,
         end_byte   => $pod->end_byte,
      );

      # We can't use ->walk_each_query_match because that presumes a query
      # based on t-s-perl
      state $QUERY = Text::Treesitter::Query->new(
         $TSPOD->lang, $HEAD_QUERY
      );

      my $qc = Text::Treesitter::QueryCursor->new;
      $qc->exec( $QUERY, $podtree->root_node );

      while( my $captures = $qc->next_match_captures ) {
         push @head1_titles, $captures->{content}->text;
      }
   }

   foreach my $title (qw( NAME DESCRIPTION AUTHOR )) {
      any { $_ eq $title } @head1_titles and next;

      $app->diag( "%s is missing a '=head1 %s' POD section", $file, $title );
      return 0;
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
