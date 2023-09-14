#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::DeprecatedFeatures 0.03
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use Text::Treesitter 0.07; # child_by_field_name

use constant DESC => "check that no perl file uses any deprecated features";
use constant SORT => 16;

=head1 NAME

C<App::perl::distrolint::Check::DeprecatedFeatures> - check C<use feature> statements

=head1 DESCRIPTION

This checks C<use feature ...> statements looking for deprecated features.

The following named features are deprecated, and not allowed:

   switch

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => $app );
}

my %BANNED_FEATURES = map { $_ => 1 } qw(
   switch
);

my $QUERY = <<'EOF';
(use_statement
   module: _ @module (#eq? @module "feature"))
   @statement
EOF

method check_file ( $file, $app )
{
   my $tree = $self->parse_perl_file( $file );

   return 0 unless $self->walk_each_query_match( $QUERY, $tree->root_node, method ( $captures ) {
      my @imports = $self->extract_use_module_imports( $captures->{statement} );

      foreach my $feature ( @imports ) {
         $BANNED_FEATURES{$feature} and
            $app->diag( "%s uses feature '%s'", $file, $feature ), return 0;
      }

      return 1;
   } );

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
