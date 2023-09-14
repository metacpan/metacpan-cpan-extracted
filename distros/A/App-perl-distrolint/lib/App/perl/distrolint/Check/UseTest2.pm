#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

class App::perl::distrolint::Check::UseTest2 0.03
   :does(App::perl::distrolint::CheckRole::EachFile)
   :does(App::perl::distrolint::CheckRole::TreeSitterPerl);

use constant DESC => "check that every unit-test uses Test2";
use constant SORT => 20;

=head1 NAME

C<App::perl::distrolint::Check::UseTest2> - check that unit tests are using C<Test2>

=head1 DESCRIPTION

This checks that every unit test (F<.t>) file contains a C<use Test2::V0>
line.

Additionally, this checks for several older modules, that have more modern
replacements within the C<Test2> system, to ensure that none of these modules
are found in C<use> statements:

   Test::More

   Test::Deep
   Test::Fatal
   Test::Identity
   Test::Refcount

=cut

my @BANNED_MODULES = qw(
   Test::More Test::Deep Test::Fatal Test::Identity Test::Refcount
);

method run ( $app )
{
   return $self->run_for_each_test_file( check_file => $app );
}

my $QUERY = <<'EOF';
(use_statement module: _ @module)
EOF

method check_file ( $file, $app )
{
   my $tree = $self->parse_perl_file( $file );

   my $found_Test2_V0;

   return 0 unless $self->walk_each_query_match( $QUERY, $tree->root_node, method ( $captures ) {
      my $module = $captures->{module}->text;

      $module eq $_ and
         $app->diag( "%s uses \`$module\`", $file ), return 0 for @BANNED_MODULES;

      $module eq "Test2::V0" and $found_Test2_V0++;

      return 1;
   } );

   return 1 if $found_Test2_V0;

   $app->diag( "%s missing \`use Test2::V0\`", $file );
   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
