use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus::Applicative::Const::List;
use lib "t";
use testlib::ApplicativeUtil qw(make_applicative_methods test_functor_basic test_const_basic);

my $c = "Data::Focus::Applicative::Const::List";

make_applicative_methods($c, sub {
    my ($da, $db) = map { $_->get_const } @_;
    return (@$da == @$db) && (grep { $da->[$_] eq $db->[$_] } 0 .. $#$da) == @$da;
});

test_functor_basic($c, builder_called => 0);
test_const_basic($c);

is_deeply($c->pure(100)->get_const, []);

note("-- mconcat");
foreach my $case (
    {label => "empty", input => [], exp => []},
    {label => "empty list", input => [[]], exp => []},
    {label => "single", input => [[10,20]], exp => [10, 20]},
    {label => "multi", input => [[], [10], [20,30], [40,50,60], [undef]],
     exp => [10,20,30,40,50,60,undef]},
) {
    is_deeply($c->build(sub {}, map { $c->new($_) } @{$case->{input}})->get_const,
              $case->{exp},
              "mconcat: $case->{label}");
}

is_deeply($c->fmap_ap(sub { die "this should not be called" },
                      map { $c->new($_) } [], [1,"aaa",2], [undef, "bbb"])->get_const,
          [1,"aaa",2,undef,"bbb"],
          "fmap_ap");

done_testing;

