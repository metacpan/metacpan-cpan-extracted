package Test7;

sub my_new
{
    bless \my ($x), shift;
}

sub hello
{
    return "World\n";
}

1;
__END__
