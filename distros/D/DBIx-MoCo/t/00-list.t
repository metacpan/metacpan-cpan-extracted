#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo::List;
use Blog::User;

sub use_test : Tests {
    use_ok 'DBIx::MoCo::List';
}

sub new_test : Tests {
    my $array_ref = [1,2];
    my $list = DBIx::MoCo::List->new($array_ref);
    ok $list;
    isa_ok $list, 'DBIx::MoCo::List';
    isa_ok $list, 'ARRAY';
    is $list->size, 2;
    is $list->first, 1;
    is $list->last, 2;
}

sub index_of : Tests {
    my $list = DBIx::MoCo::List->new([0,1,2,3]);
    ok ($list, 'list');
    is ($list->index_of(0), 0, 'index of 0');
    is ($list->index_of(1), 1, 'index of 1');
    is ($list->index_of(2), 2, 'index of 2');
    is ($list->index_of(3), 3, 'index of 3');
    ok (!$list->index_of(4), 'index of 4');
    is ($list->index_of(sub { shift == 2 }), 2, 'index of sub(2)');
}

sub grep : Tests {
    my $list = DBIx::MoCo::List->new([
        Blog::User->new(name => 0),
        Blog::User->new(name => 1),
        Blog::User->new(name => ''),
        Blog::User->new(name => 'jkondo'),
    ])->grep('name');
    is ($list->size, 2);
}

1;
