package DBIx::MoCo::Column::UTCDateTime;
use strict;
use warnings;
use DateTime;
use DateTime::Format::MySQL;

sub UTCDateTime {
    my $self = shift;
    return if not $$self;
    return if $$self =~ /0000/o;
    my $dt = DateTime::Format::MySQL->parse_datetime($$self);
    $dt->set_time_zone('UTC');
    return $dt;
}

sub UTCDateTime_as_string {
    my $class = shift;
    my $dt = shift or return;
    $dt->set_time_zone('UTC');
    return DateTime::Format::MySQL->format_datetime($dt);
}

1;
