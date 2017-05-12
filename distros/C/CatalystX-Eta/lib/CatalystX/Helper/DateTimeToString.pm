package CatalystX::Helper::DateTimeToString;

use Moose::Role;

sub _ts_as_string {
    my $self = shift;
    my $ts   = shift;
    return undef unless $ts;

    return ( ref $ts eq 'DateTime::Infinite::Past' ? '-infinity' : 'infinity' ) if $ts->is_infinite;
    $ts->datetime;
}

1;

