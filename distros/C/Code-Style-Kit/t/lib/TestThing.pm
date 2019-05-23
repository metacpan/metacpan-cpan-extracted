package TestThing;

sub import {
    my ($class) = @_;
    my $caller = caller;
    *{"${caller}::thing"} = sub { 'thing' };
    return;
}

1;
