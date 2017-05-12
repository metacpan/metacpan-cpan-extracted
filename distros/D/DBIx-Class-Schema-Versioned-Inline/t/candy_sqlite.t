#!perl

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use Module::Find;
use Test::Roo;

eval "use DBIx::Class::Candy";
plan skip_all => "DBIx::Class::Candy required" if $@;

eval "use TestCandy::Schema";
plan skip_all => "DBIx::Class::Candy required" if $@;

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

with 'Role::SQLite', @test_roles;

run_me({ schema_class => "TestCandy::Schema" });

done_testing;
