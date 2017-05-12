use warnings;
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot::Pie;}

my $temp = "temp.ps";

# Test default setting of title
{
    my $c = Chart::Gnuplot::Pie->new(
        output => $temp,
        title  => 'Testing title',
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "title_1.gp") == 0);
}

###################################################################

# Compare two files
# - return 0 if two files are the same, except the ordering of the lines
# - return 1 otherwise
sub diff
{
    my ($f1, $f2) = @_;
    $f2 = "t/".$f2 if (!-e $f2);

    open(F1, $f1) || return(1);
    open(F2, $f2) || return(1);
    my @c1 = <F1>;
    my @c2 = <F2>;
    close(F1);
    close(F2);
    return(0) if (join("", sort @c1) eq join("", sort @c2));
    return(1);
}
