package Test3;

use Class::LazyLoad;

sub new
{
    my $class = shift;
    my $type = shift;

    if ($type eq 'scalar') {
        return bless \my ($x), $class;
    } elsif ($type eq 'array') {
        my $x = [];
        return bless $x, $class;
    } elsif ($type eq 'hash') {
        my $x = {};
        return bless $x, $class;
    } elsif ($type eq 'sub') {
        my $x = sub { 'foo' };
        return bless $x, $class;
    }

    die "Unknown type '$type'\n";
}

1;
__END__
