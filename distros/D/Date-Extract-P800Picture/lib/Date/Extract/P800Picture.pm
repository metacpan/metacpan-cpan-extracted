# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2008-2017, Roland van Ipenburg
package Date::Extract::P800Picture 0.108;

use strict;
use warnings;

use utf8;
use 5.014000;

use Moose;

use POSIX ();
use English qw( -no_match_vars);
use DateTime ();

use Date::Extract::P800Picture::Exceptions ();

use Readonly ();
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY             => q{};
Readonly::Scalar my $EPOCH_YEAR        => 2000;
Readonly::Scalar my $MONTHS_IN_YEAR    => 12;
Readonly::Scalar my $MAX_DAYS_IN_MONTH => 31;
Readonly::Scalar my $HOURS_IN_DAY      => 24;
Readonly::Scalar my $BASE_N            => 36;
Readonly::Scalar my $TZ                => 'UTC';
Readonly::Hash my %ERR                 => (
    'PARSING_YEAR'     => q{Could not parse year char '%s'},
    'PARSING_MONTH'    => q{Could not parse month char '%s'},
    'PARSING_DAY'      => q{Could not parse day char '%s'},
    'PARSING_HOUR'     => q{Could not parse hour char '%s'},
    'MISSING_DATE'     => q{No date found in filename '%s'},
    'MISSING_FILENAME' => q{Filename is not set, nothing to extract},
);
## use critic

## no critic (ProhibitComplexRegexes)
my $PATTERN = qr{
    ^
    (?<year>     [[:alnum:]]   ) # max 36 years: $EPOCH_YEAR 2000 to 2035
    (?<month>    [[:digit:]AB] ) # max 12 months
    (?<day>      [[:digit:]A-U]) # max 31 days
    (?<hour>     [[:digit:]A-N]) # max 24 hours: 0 to 23
    (?<serial>   [[:digit:]]{4}) # max unique up to 10000 pictures per hour
    (?<suffix>   [.]JPG        ) # JPEG extension
    $
}aixsm;
## use critic

## no critic qw(ProhibitCallsToUndeclaredSubs)
has 'filename' => (
## use critic
    'is'  => 'rw',
    'isa' => 'Str',
);

## no critic qw(ProhibitCallsToUndeclaredSubs)
has 'datetime' => (
## use critic
    'is'      => 'rw',
    'isa'     => 'DateTime',
    'default' => sub {
        DateTime->new(
            'year'      => $EPOCH_YEAR,
            'time_zone' => $TZ,
        );
    },
);

sub extract {
    my ( $self, $filename ) = @_;
    ( defined $filename ) && $self->filename($filename);
    if ( defined $self->filename ) {
        $self->filename =~ $PATTERN;
        my ( $year, $month, $day, $hour ) = (
            $LAST_PAREN_MATCH{'year'}, $LAST_PAREN_MATCH{'month'},
            $LAST_PAREN_MATCH{'day'},  $LAST_PAREN_MATCH{'hour'},
        );
        if ( defined $year ) {
            $self->_parse( \$year, $BASE_N, $ERR{'PARSING_YEAR'} )
              && $self->_parse( \$month, $MONTHS_IN_YEAR,
                $ERR{'PARSING_MONTH'} )
              && $self->_parse( \$day, $MAX_DAYS_IN_MONTH, $ERR{'PARSING_DAY'} )
              && $self->_parse( \$hour, $HOURS_IN_DAY, $ERR{'PARSING_HOUR'} )
              && (
                eval {
                    $self->datetime->set(
                        'year'  => $year + $EPOCH_YEAR,
                        'month' => $month + 1,
                        'day'   => $day + 1,
                        'hour'  => $hour,
                    );
                    1;
                } || do {
## no critic (RequireExplicitInclusion)
                    DateExtractP800PictureException->throw(
## use critic
                        'error' => $EVAL_ERROR,
                    );
                }
              );
        }
        else {
## no critic (RequireExplicitInclusion)
            DateExtractP800PictureException->throw(
## use critic
                'error' => sprintf $ERR{'MISSING_DATE'},
                $self->filename,
            );
        }
    }
    else {
## no critic (RequireExplicitInclusion)
        DateExtractP800PictureException->throw(
## use critic
            'error' => $ERR{'MISSING_FILENAME'},
        );
    }
    return $self->datetime;
}

# Converts a character to a number given base. Changes the referenced part
# returns true on succes.

sub _parse {
    my ( $self, $sr_part, $base, $error_message ) = @_;
    my $n_unparsed = 0;
    local $OS_ERROR = 0;
    if ( defined ${$sr_part} ) {
## no critic (ProhibitCallsToUnexportedSubs)
        ( ${$sr_part}, $n_unparsed ) = POSIX::strtol( ${$sr_part}, $base );
## use critic
    }
    if (   !defined ${$sr_part}
        || ${$sr_part} eq $EMPTY
        || $n_unparsed != 0
        || $OS_ERROR )
    {
## no critic (RequireExplicitInclusion)
        DateExtractP800PictureException->throw(
## use critic
            'error' => sprintf $error_message,
            defined ${$sr_part} ? ${$sr_part} : 'undef',
        );
        ${$sr_part} = undef;
    }
    return defined ${$sr_part};
}

1;

__END__

=encoding utf8

=for stopwords Ericsson Filename MERCHANTABILITY POSIX filename timestamp jpg JPG
YMDH DateTime undef perl Readonly perls Ipenburg

=head1 NAME

Date::Extract::P800Picture - extract the date from Sony Ericsson P800 pictures.

=head1 VERSION

This document describes Date::Extract::P800Picture version 0.108.

=head1 SYNOPSIS

    use Date::Extract::P800Picture;

    $filename = "8B360001.JPG"; # 2008-12-04T6:00:00

    $parser = new Date::Extract::P800Picture();
    $parser = new Date::Extract::P800Picture('filename' => $filename);

    $datetime = $parser->extract();
    $datetime = $parser->extract($filename);

=head1 DESCRIPTION

The Sony Ericsson P800 camera phone stores pictures taken with the camera on
the device with a filename consisting of the date and the hour the picture was
taken, followed by a four digit number and the .JPG extension. The format of
the date and the hour is YMDH, in which the single characters are base 36 to
fit a range of about 36 years, 12 months, 31 days and 24 hours since the year
2000 in a case insensitive US-ASCII representation.

=head1 SUBROUTINES/METHODS

=over 4

=item Date::Extract::P800Picture-E<gt>new()

=item Date::Extract::P800Picture-E<gt>new('filename' => $filename)

Constructs a new Date::Extract::P800Picture object.

=item $parser->filename($filename);

Sets the filename to extract the date and hour from.

=item $obj-E<gt>extract()

Extract date and hour from the string and returns it as L<DateTime|DateTime>
object. Returns undef if no valid date could be extracted.

=back

=head1 CONFIGURATION AND ENVIRONMENT

No configuration and environment settings are used.

=head1 DEPENDENCIES

=over 4

=item * perl 5.14 

=item * L<POSIX|POSIX>

=item * L<English|English>

=item * L<DateTime|DateTime>

=item * L<Readonly|Readonly>

=item * L<Moose|Moose>

=item * L<Test::More|Test::More>

=back

=head1 INCOMPATIBILITIES

=over 4

=item * To avoid ambiguity between more common date notations and the
Sony Ericsson P800's date notation this is a separate module. It's highly
unlikely that in any other setting "2000" means the first of January 2002.

=item * For perls earlier than 5.14 version 0.04 of this module provides the
same functionality in a perl 5.6 compatible way.

=back

=head1 DIAGNOSTICS

An exception in the form of an L<Exception::Class|Exception::Class> named
C<DateExtractP800PictureException> is thrown when a date can't be extracted
from the string:

=over 4

=item * Could not parse year char '%s'

=item * Could not parse month char '%s'

=item * Could not parse day char '%s'

=item * Could not parse hour char '%s'

=item * No date found in filename '%s'

=item * Filename is not set, nothing to extract

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * Usually the files are transferred from the P800 to other systems in a
way that hasn't completely preserved the timestamp of the file, so there is no
reliable way to double check the results by comparing the date extracted from
the filename with the timestamp of the file.

=item * There are no error values to provide different exit statuses for
different failure reasons

=back

Please report any bugs or feature requests at
L<RT for rt.cpan.org|
https://rt.cpan.org/Dist/Display.html?Queue=Date-Extract-P800Picture>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2017, Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
