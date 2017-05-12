#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Catalyst::TraitFor::Model::DBIC::Schema::QueryLog');
}

diag(
"Testing Catalyst::TraitFor::Model::DBIC::Schema::QueryLog $Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::VERSION, Perl $], $^X"
);
