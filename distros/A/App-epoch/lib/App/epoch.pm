use strict;
use warnings;
package App::epoch;

our $VERSION = 1.001;
# ABSTRACT: Converts fuzzy time into local time

=head1 NAME

App::epoch - Convert between fuzzy times in other timezones

=head1 SYNOPSYS

    $ epoch tomorrow 2pm GMT
    2012-03-03 08:00:00 CST

    $ epoch tomorrow 2pm GMT -- hh:mm:ss
    08:00:00

=head1 DESCRIPTION

C<App::epoch> installs a command called, oddly enough, C<epoch> that converts
fuzzy time strings (see L<Time::ParseDate>) into local times, formatted by
L<Time::Format>.

=head1 COMMAND LINE USAGE

    $ epoch --help
    epoch: Fuzzy time conversion to localtime

    Usage:
        epoch time [--] [format]

        `time` can be any string that Time::ParseDate accepts
        `format` can be any string that Time::Format::time_format accepts

=cut

use Time::ParseDate;
use Time::Format qw(time_format);

use Exporter qw(import);

our @EXPORT_OK = qw(parse_time format_time);

sub parse_time {
    parsedate(join(' ',@_)) || time;
}

sub format_time {
    my $time = shift;
    my $formatstr = join(' ',@_) || 'yyyy-mm{on}-dd hh:mm{in}:ss tz';
    time_format $formatstr, $time;
}

1;
