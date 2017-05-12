#!perl

use strict;
use warnings;

use POSIX qw(:errno_h);
use Test::More tests => 2 + 6 + 1;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test');
isa_ok($root, 'DBIx::Path', 'Constructor return');

GOOD: {
    my $bin=$root->get('usr')->get('bin');
    isa_ok($bin, 'DBIx::Path', 'root->get(usr)->get(bin)');
    my $perl=$bin->get('perl');
    isa_ok($perl, 'DBIx::Path', 'bin->get(perl)');

    my %ret=$perl->parents;
    is(scalar keys %ret, 1, "perl has one parent");
    ok((grep { $_ == $bin->id } keys %ret), "    with bin's ID");
    is(scalar @{$ret{$bin->id}}, 1, "    one name");
    ok((grep { $_ eq 'perl' } @{$ret{$bin->id}}), "        and it's 'perl'");
}

BAD: {
    my %ret=$root->parents;
    is(scalar keys %ret, 0, "Root is an orphan");
}
