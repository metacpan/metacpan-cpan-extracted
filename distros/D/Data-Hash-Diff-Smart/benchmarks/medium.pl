# medium.pl
{
    my $old = {
        user => {
            name => 'Nigel',
            roles => [qw(admin editor)],
            prefs => { theme => 'dark', tz => 'UTC' },
        },
        items => [ map { { id => $_, val => $_ * 2 } } 1..50 ],
    };

    my $new = {
        user => {
            name => 'N. Horne',
            roles => [qw(admin editor reviewer)],
            prefs => { theme => 'light', tz => 'UTC' },
        },
        items => [ map { { id => $_, val => $_ * 3 } } 1..50 ],
    };

    ($old, $new);
}
