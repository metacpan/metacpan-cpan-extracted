use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus::Applicative::Const::First;
use lib "t";
use testlib::ApplicativeUtil qw(make_applicative_methods test_functor_basic test_const_basic);

my $c = "Data::Focus::Applicative::Const::First";

make_applicative_methods($c, sub {
    my ($da, $db) = map { $_->get_const } @_;
    return (defined($da) && defined($db)) ? $da eq $db : !(defined($da) xor defined($db));
});

test_functor_basic($c, builder_called => 0);
test_const_basic($c);

is($c->pure(10)->get_const, undef);

note("--- mconcat");
foreach my $case (
    {label => "empty", input => [], exp => undef},
    {label => "all undef", input => [undef, undef, undef], exp => undef},
    {label => "single num", input => [\(10)], exp => 10},
    {label => "single array", input => [\([1,2,3])], exp => [1,2,3]},
    {label => "single hash", input => [\({a => "hoge"}), \(10)], exp => {a => "hoge"}},
    {label => "multi", input => [undef, \(20), \(30), undef, \(50)], exp => 20},
    {label => "multi strings", input => [\("AAA"), \("BBB"), undef], exp => "AAA"},
    {label => "valid undef", input => [undef, \(undef), \("aa")], exp => undef},
) {
    my $ret = $c->build(sub { }, map { $c->new($_) } @{$case->{input}})->get_const;
    $ret = defined($ret) ? $$ret : undef;
    is_deeply($ret, $case->{exp}, "mconcat: $case->{label}");
}

{
    my $killer = sub { die "this should not be called" };
    my $f_result = $c->fmap_ap($killer, map { $c->new($_) } undef, undef, \(30), \(20), \(10));
    is(${$f_result->get_const},
       30,
       "fmap_ap");
}

done_testing;
