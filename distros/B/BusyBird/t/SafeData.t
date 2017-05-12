use strict;
use warnings;
use Test::More;
use BusyBird::SafeData qw(safed);
use Storable qw(dclone);

{
    note("--- example");
    my $data = {
        foo => {
            bar => [
                0, 1, 2
            ],
            buzz => { hoge => 100 }
        }
    };

    my $exp_orig = dclone($data);
    my $sd = safed($data);
    
    is_deeply $sd->original, $exp_orig, "original() ok";
    
    is $sd->val("foo", "bar", 1), 1;
    is $sd->val("foo", "buzz", "FOO"), undef;
    is $sd->val("foo", "quux", "hoge"), undef;
    is $sd->val("foo", "bar", "FOO"), undef;
    is $sd->val("foo", "buzz", "hoge", "FOO"), undef;
    is_deeply $sd->original, $exp_orig, "original() not autovivified ok";
    
    is_deeply [$sd->array("foo", "bar")], [0, 1, 2];
    is_deeply [$sd->array("foo", "buzz")], [];
    is_deeply [$sd->array("foo", "bar", 1)], [];
}

{
    note("--- val() returning undef, array() returning empty");
    my @cases = (
        {label => "root undef", orig => undef,
         paths => [ [], ["foo"], ["foo", 1], [2, 1, "foo"] ]},
        {label => "root string", orig => "hoge",
         paths => [ ["foo"], ["foo", 1], [2, 1, "foo"] ]},
        {label => "undef key in the middle of the path",
         orig => {
             a => { b => [0, 1, 2] },
             b => [0, {c => 10}, 3]
         },
         paths => [ [qw(c)], [qw(c d e)], [qw(a b c)], [qw(a c d 1)], [qw(b c c)], [qw(b 0 d)], [qw(b 1 c d)],
                    [qw(b 4)], [qw(b 4 8)]]}
    );
    foreach my $case (@cases) {
        my $exp_orig = ref($case->{orig}) ? dclone($case->{orig}) : $case->{orig};
        my $sd = safed($case->{orig});
        foreach my $path (@{$case->{paths}}) {
            my $label = "$case->{label}: (" . join("/", @$path) . ")";
            my $got_val = $sd->val(@$path);
            is $got_val, undef, "$label: val() should be undef";
            is_deeply [$sd->array(@$path)], [], "$label: array() should be empty";
            my $got_orig = $sd->original();
            is_deeply $got_orig, $exp_orig, "$label: original() should return the original data unchanged";
        }
    }
}

{
    note("--- array() returning empty");
    my @cases = (
        {label => "string", orig => {a => "A"}, path => ["a"]},
        {label => "hash-ref", orig => {a => "A", b => "B"}, path => []},
    );
    foreach my $case (@cases) {
        my $exp_orig = dclone($case->{orig});
        my $sd = safed($case->{orig});
        is_deeply [$sd->array(@{$case->{path}})], [], "$case->{label}: array() should be empty";
        is_deeply $sd->original, $exp_orig, "$case->{label}: origial() preserved";
    }
}

done_testing;
