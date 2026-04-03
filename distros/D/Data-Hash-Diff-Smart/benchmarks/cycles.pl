# cycles.pl
{
    my $a = { value => 1 };
    $a->{self} = $a;

    my $b = { value => 2 };
    $b->{self} = $b;

    ($a, $b);
}
