use strict;
use warnings;
use Test::More;

{
    package InvalidIdentity1;
    use parent qw/Data::Monad::Base::Monad/;

    sub unit {
        my $class = shift;
        bless [@_], $class
    }
}

{
    package InvalidIdentity2;
    use parent qw/Data::Monad::Base::Monad/;

    sub unit {
        my $class = shift;
        bless [@_], $class
    }

    sub map {
        my ($self, $f) = @_;
        bless [$f->(@$self)], ref $self;
    }
}

{
    package InvalidIdentity3;
    use parent qw/Data::Monad::Base::Monad/;

    sub unit {
        my $class = shift;
        bless [@_], $class
    }

    sub flatten {
        my $self = shift;
        @$self;
    }
}

{
    my $monad = 'InvalidIdentity1';

    my $mm = $monad->unit($monad->unit(qw/x y/));
    eval { $mm->flatten };
    ok $@, "Shouldn't recursive deeply.";

    eval { $monad->unit(qw/3 2/)->map(sub { map { '+' x $_ } @_ }) };
    ok $@, "Shouldn't recursive deeply.";

    eval { $monad->unit(qw/3 2/)
                 ->flat_map(sub { $monad->unit(map { '+' x $_ } @_) }) };
    ok $@, "Shouldn't recursive deeply.";
}

{
    my $monad = 'InvalidIdentity2';

    my $mm = $monad->unit($monad->unit(qw/x y/));
    eval { $mm->flatten };
    ok $@, "Shouldn't recursive deeply.";

    eval { $monad->unit(qw/3 2/)
                 ->flat_map(sub { $monad->unit(map { '+' x $_ } @_) }) };
    ok $@, "Shouldn't recursive deeply.";
}

{
    my $monad = 'InvalidIdentity3';

    eval { $monad->unit(qw/3 2/)->map(sub { map { '+' x $_ } @_ }) };
    ok $@, "Shouldn't recursive deeply.";

    eval { $monad->unit(qw/3 2/)
                 ->flat_map(sub { $monad->unit(map { '+' x $_ } @_) }) };
    ok $@, "Shouldn't recursive deeply.";
}

done_testing;
