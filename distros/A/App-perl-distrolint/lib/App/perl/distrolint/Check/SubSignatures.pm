#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::SubSignatures 0.09;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use List::Util 1.29 qw( any first );

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that Perl subroutines use signatures if enabled";
use constant SORT => 25;

=head1 NAME

C<App::perl::distrolint::Check::SubSignatures> - check that Perl subroutines use signatures

=head1 DESCRIPTION

This checks that for every Perl source file in F<lib/>, that any C<sub> or
C<method> declarations made inside a scope that has the C<signatures> feature
enabled are actually made using signatures. That said, it fails if a
subroutine declaration is found that does not have a signature, if it lies
inside a scope that specifically enables the feature.

The C<signatures> feature is considered enabled by a C<use VERSION>
declaration of a version C<v5.36> or later, or by a C<use feature> declaration
that specifically lists the C<signatures> feature.

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

(subroutine_declaration_statement (signature) ? @signature)
   @sub

(method_declaration_statement (signature) ? @signature)
   @method

(anonymous_subroutine_expression (signature) ? @signature)
   @sub

(anonymous_method_expression (signature) ? @signature)
   @method
EOF

my sub proto_looks_like_signature ( $proto )
{
   # prototype must be wrapped in (...)
   $proto =~ s/^\((.*)\)$/$1/ or
      return 0;

   # trim
   $proto =~ s/^\s+//;
   $proto =~ s/\s+$//;

   # Empty string would count as a zero-arg signature
   return 1 if $proto eq '';

   # A single '$' would count as a single-arg unnamed signature param
   # A single '@' or '%' would count as a single slurpy unnamed signature param
   return 1 if $proto eq '$' or $proto eq '@' or $proto eq '%';

   return 0;
}

method check_file ( $file )
{
   my $tree = $self->parse_perl_file( $file );

   my $ok = 1;
   $self->walk_each_scoped_query_match( $QUERY, $tree->root_node, method ( $capture, $context ) {
      my $node;
      if( $node = $capture->{use_version} ) {
         my $version = version->new( $node->child_by_field_name( 'version' )->text );
         $context->{use_feature_signatures} = ( $version ge v5.36 );
      }
      elsif( $node = $capture->{use_module} ) {
         my $sense = ( $node->child_nodes )[0]->type eq "use";
         my @features = $self->extract_use_module_imports( $node );

         $context->{use_feature_signatures} = $sense
            if any { $_ eq "signatures" } @features;
      }
      elsif( $node = $capture->{sub} or $node = $capture->{method} ) {
         my $kw = ( $capture->{sub} ) ? "sub" : "method";
         my $has_signature = defined $capture->{signature};
         # tree-sitter-perl can't tell the difference between prototypes
         # and signatures
         if( $context->{use_feature_signatures} and not $has_signature ) {
            my $proto_node = first { $_->type eq "prototype" } $node->child_nodes;

            $has_signature = proto_looks_like_signature( $proto_node->text ) if $proto_node;
         }

         if( $context->{use_feature_signatures} and !$has_signature ) {
            App->diag( App->format_file( $file, $node->start_row + 1 ), " declares a $kw without signature" );
            $ok = 0;
         }
      }
      else {
         my @names = sort keys %$capture;
         die "TODO: Unsure how to handle captures <@names>\n";
      }

      return 1; # check all of them
   } );

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
