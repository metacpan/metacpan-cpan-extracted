#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::UseUTF8 0.06;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use constant DESC => "check that every perl file sets 'use utf8' if required";
use constant SORT => 11;

=head1 NAME

C<App::perl::distrolint::Check::UseUTF8> - check that every perl file sets the C<utf8> pragma if required

=head1 DESCRIPTION

This checks that for every Perl source code file, if it contains any non-ASCII
characters then a C<use utf8> statement is in effect.

The contents of comments and POD sections are ignored, as any non-ASCII
characters here will not change meaning in the presence or absence of the
C<utf8> pragma.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

my $EXTRAS_QUERY = <<'EOF';
(comment) @comment
(pod) @pod
EOF

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   my $use_utf8_at;

   my $all_source = $tree->root_node->text;

   # Not using walk_each_statement because we only care about toplevel
   # statements

   foreach my $node ( $tree->root_node->child_nodes ) {
      next if $node->is_extra;

      if( $node->is_named and $node->type eq "use_statement" ) {
         my $module = $node->child_by_field_name( "module" )->text;

         $use_utf8_at = $node->start_byte, next if $module eq "utf8";
      }
   }

   $self->walk_each_query_match( $EXTRAS_QUERY, $tree->root_node, method ( $captures ) {
      my ( $node ) = values %$captures;

      my $len = $node->end_byte - $node->start_byte;
      use bytes;
      substr( $all_source, $node->start_byte, $len ) = "-" x $len;
   } );

   if( !defined $use_utf8_at and
       $all_source =~ m/[^[:ascii:]]/ ) {
      App->diag( App->format_file( $file ), " contains non-ASCII characters but no ", App->format_literal( "use utf8" ) );
      return 0;
   }

   if( defined $use_utf8_at and
       do { use bytes; substr( $all_source, 0, $use_utf8_at ) } =~ m/[^[:ascii:]]/ ) {
      App->diag( App->format_file( $file ), " contains non-ASCII characters before the ", App->format_literal( "use utf8" ) );
      return 0;
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
