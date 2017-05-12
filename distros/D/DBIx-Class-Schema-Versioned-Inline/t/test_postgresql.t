#!perl

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use Module::Find;
use Test::Roo;
use TestVersion::Schema;

# LANG can cause initdb failures
delete $ENV{LANG};

my @test_roles;

if ( $ENV{TEST_ROLE_ONLY} ) {
    push @test_roles, map { "Test::$_" } split(/,/, $ENV{TEST_ROLE_ONLY});
}
else {
    my @old_inc = @INC;
    setmoduledirs( File::Spec->catdir( 't', 'lib' ) );
    @test_roles = Module::Find::findsubmod Test;
    setmoduledirs(@old_inc);
}

diag "with " . join(" ", @test_roles);

with 'Role::PostgreSQL', @test_roles;

run_me;

done_testing;
