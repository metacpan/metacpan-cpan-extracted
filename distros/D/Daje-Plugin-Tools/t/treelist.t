#!/usr/bin/perl
use v5.40;

use strict;
use warnings;
use Test::More;

use Daje::Database::Helper::TreeList;
use Mojo::Pg;
use Data::Dumper;

sub treelist () {
    # my $pg = Mojo::Pg->new->dsn(
    #     "dbi:Pg:dbname=Toolstest;host=database;port=54321;user=test;password=test"
    # );
    #
    # Daje::Database::Helper::TreeList->new(
    #     db => $pg->db
    # )->load_treelist(8)->then(
    #     sub ($treelist) {
    #     say Dumper($treelist);
    # })->catch(sub($err) {
    #     say $err;
    # });

    return 1;
}

ok (treelist() == 1);
done_testing();

