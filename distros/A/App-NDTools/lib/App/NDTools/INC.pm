package App::NDTools::INC;

my $added = 0;

sub import {
    return if ($added); # prevent duplicates when invoked more than once

    my $dir = substr(__FILE__, 0, -3);
    unshift @INC, $dir if (-d $dir);

    $added = 1;
}

1;
