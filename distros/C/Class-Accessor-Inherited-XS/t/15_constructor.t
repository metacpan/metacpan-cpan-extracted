use strict;
use Test::More;
use Test::Deep;
use Class::Accessor::Inherited::XS constructor => 'new';

cmp_deeply __PACKAGE__->new(1,2,3,4), bless {1 => 2, 3 => 4};
cmp_deeply __PACKAGE__->new({5,6,7,8}), bless {5 => 6, 7 => 8};
cmp_deeply __PACKAGE__->new, bless {};

my %args = (1..4);
cmp_deeply __PACKAGE__->new(\%args), bless {1 => 2, 3 => 4};

my $hargs = {5..8};
cmp_deeply __PACKAGE__->new($hargs), bless {5 => 6, 7 => 8};
cmp_deeply $hargs, bless {5 => 6, 7 => 8};

my @list = (__PACKAGE__->new(1,2));
cmp_deeply \@list, [bless {1,2}];

@list = (__PACKAGE__->new(1,2), __PACKAGE__->new(1,2));
cmp_deeply \@list, [bless({1,2}), bless({1,2})];

sub builder {
    my ($obj) = @_;
    return __PACKAGE__->new($obj);
}

cmp_deeply builder(), bless({});

done_testing;
