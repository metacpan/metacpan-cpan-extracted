use strict;
use warnings;
use Test::More;

use Data::Monad::Either qw(right left);

sub get_key ($) {
    my ($k) = @_;
    return sub {
        my ($data) = @_;
        return left('not_hash') unless (ref($data) // '') eq 'HASH';
        return exists $data->{$k} ? right($data->{$k}) : left("no_key:$k");
    };
}

{
    my $failure = get_key('name')->(undef);
    ok $failure->is_left;
    is $failure->value, 'not_hash';
};

{
    my $failure = get_key('name')->({ lang => 'ja' });
    ok $failure->is_left;
    is $failure->value, 'no_key:name';
};

{
    my $success = get_key('name')->({ name => 'Larry' });
    ok $success->is_right;
    is $success->value, 'Larry';
};

{
    my $right = right({ author => { info => { name => 'Larry' } } });
    my $success = $right->flat_map(get_key('author'))->flat_map(get_key('info'))->flat_map(get_key('name'));
    ok $success->is_right;
    is $success->value, 'Larry';
};

{
    my $right = right({ author => { info => { name => 'Larry' } } });
    my $failure = $right->flat_map(get_key('author'))->flat_map(get_key('parent'))->flat_map(get_key('name'));
    ok $failure->is_left;
    is $failure->value, 'no_key:parent';
};

done_testing;
