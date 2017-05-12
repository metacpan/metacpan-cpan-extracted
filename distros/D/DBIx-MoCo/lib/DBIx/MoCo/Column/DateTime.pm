package DBIx::MoCo::Column::DateTime;
use strict;
use warnings;
use DateTime;
use DateTime::Format::MySQL;

sub DateTime {
    my $self = shift;
    return if not $$self;
    return if $$self =~ /0000/o;
    my $dt = DateTime::Format::MySQL->parse_datetime($$self);
    return $dt;
}

sub DateTime_as_string {
    my $class = shift;
    my $dt = shift or return;
    return DateTime::Format::MySQL->format_datetime($dt);
}

1;
