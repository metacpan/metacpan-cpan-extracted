use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use lib "t";
use testlib::SampleObject;
use testlib::Identity qw(identical);

note("--- Data::Focus without lenses");

note("-- non-ref values");
foreach my $case (
    {label => "undef", target => undef},
    {label => "num", target => 100},
    {label => "string", target => "hoge"},
) {
    my $f = focus($case->{target});
    isa_ok $f, "Data::Focus";
    is $f->get, $case->{target}, "$case->{label}: get()";
    is_deeply [$f->list], [$case->{target}], "$case->{label}: list()";

    is $f->set("FOOBAR"), "FOOBAR", "$case->{label}: set() result";
    is $f->get, $case->{target}, "$case->{label}: set() not modifying target";

    my @args = ();
    is $f->over(sub { push @args, [@_]; "FOOBAR" }), "FOOBAR", "$case->{label}: over() result";
    is $f->get, $case->{target}, "$case->{label}: over() not modifying target";
    is scalar(@args), 1, "$case->{label}: updater called once";
    is_deeply $args[0], [$case->{target}], "$case->{label}: updater argments";
}

note("-- ref values");
foreach my $case (
    {label => "hash-ref", target => {aaa => "bbb"}},
    {label => "array-ref", target => [10, 20, 30]},
    {label => "scalar-ref", target => \("AAA")},
    {label => "object", target => testlib::SampleObject->new},
) {
    my $t = $case->{target};
    my $f = focus($t);
    isa_ok $f, "Data::Focus";
    identical $f->get, $t, "$case->{label}: get()";
    my @list_ret = $f->list;
    is scalar(@list_ret), 1, "$case->{label}: list() 1 result";
    identical $list_ret[0], $t, "$case->{label}: list() elem";

    is $f->set("FOOBAR"), "FOOBAR", "$case->{label}: set() result";
    identical $f->get, $t, "$case->{label}: set() not modifying the target";

    my @args = ();
    is $f->over(sub { push @args, [@_]; "FOOBAR" }), "FOOBAR", "$case->{label}: over() result";
    identical $f->get, $t, "$case->{label}: over() not modifying target";
    is scalar(@args), 1, "$case->{label}: updater called once";
    identical $args[0][0], $t, "$case->{label}: updater argments";
}

done_testing;
