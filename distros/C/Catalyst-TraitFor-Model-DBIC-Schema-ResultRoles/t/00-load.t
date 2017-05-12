#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles' ) || print "Bail out!
";
}

diag( "Testing Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles $Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles::VERSION, Perl $], $^X" );
