use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Data::Recursive qw/clone lclone/;

subtest 'object with clone logic' => sub {
    {
        package MyComplex;
        sub HOOK_CLONE {
            my %new = %{$_[0]};
            delete $new{b};
            return bless \%new, 'MyComplex';
        }
    }
    my $val = bless {a => 1, b => 2}, 'MyComplex';
    my $copy = lclone($val);
    $val->{b} = 3;
    cmp_deeply($copy, bless {a => 1}, 'MyComplex');
    is(ref $copy, 'MyComplex');
};

subtest 'object with clone logic using clone function again recursively' => sub {
    {
        package MyMoreComplex;
        sub HOOK_CLONE {
            my $self = shift;
            delete local $self->{b};
            return Data::Recursive::clone($self);
        }
    }
    my $val = bless {a => 1, b => 2}, 'MyMoreComplex';
    my $copy = lclone($val); # should not enter inifinite loop
    is($val->{b}, 2);
    cmp_deeply($copy, bless {a => 1}, 'MyMoreComplex');
    $val->{b} = 3;
    cmp_deeply($copy, bless {a => 1}, 'MyMoreComplex');
    is(ref $copy, 'MyMoreComplex');
};

subtest 'fclone with HOOK_CLONE and again clone inside - MUST NOT loose object dictionary inside' => sub {
    {
        package MyObj;
        use Data::Dumper;
        sub HOOK_CLONE {
            my $self = shift;
            my $ret = Data::Recursive::clone($self);
            $ret->{copied} = 1;
            return $ret;
        }
    }
    my $val = {obj => bless({a => 1}, 'MyObj')};
    $val->{obj}{top} = $val;
    my $copy = clone($val);
    $copy->{obj}{a}++;
    is($val->{obj}{a}, 1);
    cmp_deeply([$copy->{obj}{a}, $copy->{obj}{copied}], [2, 1]);
    isnt($val, $copy);
    isnt($val->{obj}, $copy->{obj});
    is($copy->{obj}{top}, $copy, 'same dictionary used');
};

done_testing();
