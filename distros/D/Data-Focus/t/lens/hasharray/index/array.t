use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

note("edges cases for array targets");

{
    foreach my $immutable (0, 1) {
        foreach my $case (
            {label => "single", index => -10},
            {label => "boundary", index => -5},
            {label => "slice", index => [0, 2, -5, 3]},
        ) {
            my $target = [0,1,2,3];
            my $lens = Data::Focus::Lens::HashArray::Index->new(
                index => $case->{index},
                immutable => $immutable
            );
            my $label = "$case->{label}, immutable=$immutable";
            like(
                exception { focus($target)->set($lens, 10) },
                qr/negative out-of-range index/i,
                "$label: set to negative out-of-range index raises an exception"
            );
        }
    }
}

{
    my $target = [0,1,2,3];
    my $lens = Data::Focus::Lens::HashArray::Index->new(index => -4);
    is(
        exception { focus($target)->set($lens, "zero") },
        undef,
        "index -4 is negative in-range index, so it's ok"
    );
    is_deeply $target, ["zero", 1, 2, 3];
}

{
    my @warns = ();
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $lens = Data::Focus::Lens::HashArray::Index->new(index => "str");
    my $got = focus([0,1,2,3])->set($lens, "AAA");
    is_deeply $got, ["AAA", 1,2,3], "string index cast to 0";
    note("warns:");
    note(explain \@warns);
}

done_testing;
