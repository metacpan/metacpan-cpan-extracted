#!/usr/bin/perl -w
use strict;
use Test::More (tests => 4);

BEGIN {use Chart::Gnuplot;}

# Test copying Chart object
{
    my $original = Chart::Gnuplot->new(
        output => "temp.ps",
        title  => 'original',
    );
    my $clone = $original->copy;

    $original->title("original title changed");
    $clone->title("clone title");

    $original->_setChart();
    $clone->_setChart();

    my $diff = 0;
    $diff += &diff($original->{_script}, "copy_1.gp");
    $diff += &diff($clone->{_script}, "copy_2.gp");
    ok($diff == 0);
}


# Test multi-copying Chart object
{
    my $original = Chart::Gnuplot->new(
        output => "temp.ps",
        title  => 'original',
    );
    my @clone = $original->copy(3);

    # Modify objects after cloning
    $original->title("original title changed");
    for (my $i = 0; $i < @clone; $i++)
    {
        $clone[$i]->title("clone title $i");
    }

    # Write gnuplot script
    $original->_setChart();
    for (my $i = 0; $i < @clone; $i++)
    {
        $clone[$i]->_setChart();
    }

    # Check if there is difference
    my $diff = 0;
    $diff += &diff($original->{_script}, "copy_1.gp");
    for (my $i = 0; $i < @clone; $i++)
    {
        my $j = $i+3;
        $diff += &diff($clone[$i]->{_script}, "copy_$j.gp");
    }
    ok($diff == 0);
}


# Test copying DataSet object
{
    my $original = Chart::Gnuplot::DataSet->new(
        func  => 'sin(x)',
        style => 'points',
    );
    my $clone = $original->copy;

    $original->func("cos(x)");
    $clone->ydata([1 .. 10]);

    my $cos = $original->_thaw();
    $clone->_thaw();

    my $diff = 0;
    $diff++ if ($cos ne "cos(x) title \"\" with points");
    $diff += &diff($clone->{_data}, "copy_1.dat");
    ok($diff == 0);
}


# Test multi-copying DataSet object
{
    my $original = Chart::Gnuplot::DataSet->new(
        func  => 'sin(x)',
        title => "original"
    );
    my @clone = $original->copy(3);

    # Modify objects after cloning
    $original->title("original title changed");
    for (my $i = 0; $i < @clone; $i++)
    {
        $clone[$i]->title("clone title $i");
    }

    # Save data
    my $origStr = $original->_thaw();
    my (@cloneStr) = ();
    for (my $i = 0; $i < @clone; $i++)
    {
        push(@cloneStr, $clone[$i]->_thaw());
    }

    # Check if there is difference
    my $diff = 0;
    $diff++ if ($origStr ne 'sin(x) title "original title changed"');
    for (my $i = 0; $i < @clone; $i++)
    {
        $diff++ if ($cloneStr[$i] ne "sin(x) title \"clone title $i\"")
    }
    ok($diff == 0);
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
