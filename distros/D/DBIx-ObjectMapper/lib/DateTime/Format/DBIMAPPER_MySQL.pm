package DateTime::Format::DBIMAPPER_MySQL;
use strict;
use warnings;
use base qw(DateTime::Format::MySQL);

use DateTime::Format::Builder (
    parsers => {
        parse_time => {
            params => [ qw( hour minute second ) ],
            regex => qr/^(\d{2}):(\d{2}):(\d{2})$/,
            extra => { time_zone => 'floating',  year => '1970' },
        }
    }
);

sub format_timestamp {
    my ( $self, $dt ) = @_;
    $self->format_datetime($dt);
}

1;
