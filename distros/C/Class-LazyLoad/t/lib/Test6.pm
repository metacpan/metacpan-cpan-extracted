package Test6;

use Class::LazyLoad [ __PACKAGE__, 'my_new' ];

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
