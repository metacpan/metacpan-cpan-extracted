# large.pl
{
    my $old = {
        data => [ map { { id => $_, val => $_ * 2 } } 1..5000 ],
    };

    my $new = {
        data => [ map { { id => $_, val => $_ * 3 } } 1..5000 ],
    };

    ($old, $new);
}
