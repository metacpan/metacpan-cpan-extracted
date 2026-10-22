use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::KDTree::Shared;

my $dir = tempdir(CLEANUP => 1);
for my $dims (1, 2, 16) {
    for my $sign (-1, 1) {
        my $path = "$dir/$dims-$sign.kd";
        my $kd = Data::KDTree::Shared->new($path, $dims, 3);
        my @point = ($sign * 0.3, (0) x ($dims - 1));
        my @query = ($sign, (0) x ($dims - 1));
        $kd->add(\@point, $_) for 1 .. 3;
        for my $readonly (0, 1) {
            if ($readonly) {
                $kd->freeze;
                $kd = Data::KDTree::Shared->new_readonly($path);
            }
            is_deeply [map { $_->{id} } $kd->radius(\@query, 0.7)], [1, 2, 3],
                "decimal boundary: dims=$dims sign=$sign readonly=$readonly";
            is_deeply [map { $_->{id} } $kd->radius(\@point, 0)], [1, 2, 3],
                'zero radius includes every duplicate';
            is_deeply [$kd->radius(\@query, 0.6999)], [],
                'points beyond the radius remain excluded';
        }
    }
}

{
    my $kd = Data::KDTree::Shared->new(undef, 2, 10);
    $kd->add([0, 0], 42);
    my @hole;
    $hole[1] = 1;
    for my $point (\@hole, [undef, 1]) {
        my @calls = (
            ['add',     sub { $kd->add($point) }],
            ['nearest', sub { $kd->nearest($point) }],
            ['knn',     sub { $kd->knn($point, 2) }],
            ['range lo',sub { $kd->range($point, [1, 1]) }],
            ['range hi',sub { $kd->range([0, 0], $point) }],
            ['radius',  sub { $kd->radius($point, 1) }],
        );
        for my $call (@calls) {
            eval { $call->[1]->() };
            like $@, qr/coordinate 0 is missing/, "$call->[0] rejects a missing coordinate";
        }
        is $kd->count, 1, 'failed calls leave the tree unchanged';
        is $kd->nearest([0, 0])->{id}, 42, 'valid query still works after errors';
    }
}

{
    package Local::Coordinate;
    sub TIESCALAR { bless { value => $_[1], fetches => 0 }, $_[0] }
    sub FETCH { ++$_[0]{fetches}; $_[0]{value} }
}
{
    my $kd = Data::KDTree::Shared->new(undef, 1, 2);
    my @point = (0);
    my $tied = tie $point[0], 'Local::Coordinate', 0.3;
    $kd->add(\@point, 7);
    is $tied->{fetches}, 1, 'coordinate magic is fetched once';
    is $kd->nearest([0.3])->{id}, 7, 'a tied coordinate is read correctly';
    $tied->{value} = undef;
    eval { $kd->add(\@point) };
    like $@, qr/coordinate 0 is missing/, 'undefined tied coordinate is rejected';
    is $kd->count, 1, 'undefined tied coordinate does not append';
}

done_testing;
