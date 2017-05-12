use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'set' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);

    {
        my $guard = $dwr->save;
        $dwr->set([qw/hoge/]);
        is $dwr->next, 'hoge';
    };

    is $dwr->next, 'foo';
};

subtest 'remove' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);

    {
        my $guard = $dwr->save;
        $dwr->remove('foo');
        is $dwr->next, 'bar';
    };
    {
        my $guard = $dwr->save;
        $dwr->remove('bar');
        is $dwr->next, 'foo';
    };

    like $dwr->next, qr/\A(?:foo|bar)\z/;
};

subtest 'add' => sub {
    my $dwr = Data::WeightedRoundRobin->new;

    {
        my $guard = $dwr->save;
        $dwr->add('bar');
        is $dwr->next, 'bar';
    };

    ok !$dwr->next;
};

subtest 'replace' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { key => 'foo', value => 'bar' },
    ]);

    {
        my $guard = $dwr->save;
        $dwr->replace({ key => 'foo', value => 'hoge' });
        is $dwr->next, 'hoge';
    };

    is $dwr->next, 'bar';
};

done_testing;
