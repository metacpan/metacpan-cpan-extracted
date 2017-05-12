#!perl

use File::Spec;
use Module::Find;
use Test::Roo;

use lib File::Spec->catdir( 't', 'lib' );
my @test_roles;

if ( $ENV{TEST_ROLE_ONLY} ) {
    push @test_roles, map { "Test::$_" } split(/,/, $ENV{TEST_ROLE_ONLY});
}
else {
    my @old_inc = @INC;
    setmoduledirs( File::Spec->catdir( 't', 'lib' ) );

    @test_roles = sort { $a cmp $b } findsubmod Test;

    setmoduledirs(@old_inc);
}

diag "with " . join(" ", @test_roles);

with 'Interchange6::Test::Role::Fixtures',
  'Interchange6::Test::Role::PostgreSQL', 'Role::Deploy', @test_roles;

run_me;

done_testing;
