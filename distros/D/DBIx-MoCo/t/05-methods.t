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
use DBIx::MoCo;
use Blog::User;
use Data::Dumper;

sub retrieve_keys : Tests {
    DBIx::MoCo->retrieve_keys(['user_id', 'entry_id']);
    is_deeply(DBIx::MoCo->retrieve_keys, ['user_id', 'entry_id']);
}

sub quote : Tests {
    is (Blog::User->quote('hello world'), "'hello world'");
    is (Blog::User->quote("it's fine day!"), "'it''s fine day!'");
    my $u = Blog::User->retrieve(1);
    is ($u->quote("it's fine day!"), "'it''s fine day!'");
}

sub universal_can : Tests {
    ok (Blog::User->can('has_a'), 'User can has_a');
    ok (Blog::User->can('retrieve'), 'User can retrieve');
    ok (Blog::User->can('name'), 'User can name');
    ok (Blog::User->can('entries'), 'User can entries');
    ok (!Blog::User->can('jump'), 'User cannot jump');
    ok (Blog::User->can('retrieve_by_name'), 'User can retrieve_by_name');
    ok (Blog::User->can('name_as_URI'), 'User can name_as_URI');
}

1;
