package Test2;

sub new
{
    bless \my ($x), shift;
}

sub hello
{
    return "World\n";
}

1;
__END__
