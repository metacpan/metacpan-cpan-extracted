#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Data::CSel qw(csel_each);
use Local::C;
use Local::TN;
use Local::TN1;
use Local::TN2;

# from csel.t
my $tree1 = Local::TN->new_from_struct({
    id => 'root', _children => [
        {id => 'a1', _children => [
            {id => 'b11'},
            {id => 'b12', _class=>'Local::TN2'},
            {id => 'b13', _class=>'Local::TN2'},
            {id => 'b14', _class=>'Local::TN1'},
            {id => 'b15', _class=>'Local::TN'},
        ]},
        {id => 'a2', _children => [
             {id => 'b21', _class=>'Local::TN2', _children => [
                 {id => 'c211', _class=>'Local::TN1'},
             ]},
         ]},
    ]},
);

my @res;
csel_each { push @res, $_->id } "Local::TN2", $tree1;
is_deeply(\@res, [qw/b12 b13 b21/]);

DONE_TESTING:
done_testing;
