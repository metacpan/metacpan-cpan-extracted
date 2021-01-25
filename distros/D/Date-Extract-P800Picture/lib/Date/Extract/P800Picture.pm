# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2008-2020, Roland van Ipenburg
package Date::Extract::P800Picture v1.1.6;

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
Readonly::Scalar my $EPOCH_YEAR        => 2000;
Readonly::Scalar my $MONTHS_IN_YEAR    => 12;
Readonly::Scalar my $MAX_DAYS_IN_MONTH => 31;
Readonly::Scalar my $HOURS_IN_DAY      => 24;
Readonly::Scalar my $BASE_N            => 36;
Readonly::Scalar my $TZ                => 'UTC';
Readonly::Hash my %ERR                 => (
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
            $self->_parse( \$year,  $BASE_N );
            $self->_parse( \$month, $MONTHS_IN_YEAR );
            $self->_parse( \$day,   $MAX_DAYS_IN_MONTH );
            $self->_parse( \$hour,  $HOURS_IN_DAY );
            $self->datetime->set(
                'year'  => $year + $EPOCH_YEAR,
                'month' => $month + 1,
                'day'   => $day + 1,
                'hour'  => $hour,
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

# Converts a character to a number given base. Changes the referenced part.

sub _parse {
    my ( $self, $sr_part, $base ) = @_;
    my $n_unparsed = 0;

## no critic (ProhibitCallsToUnexportedSubs)
    return ( ${$sr_part}, $n_unparsed ) = POSIX::strtol( ${$sr_part}, $base );
## use critic
}

1;

__END__

=encoding utf8

=for stopwords Bitbucket Ericsson Filename MERCHANTABILITY POSIX filename timestamp jpg JPG
YMDH DateTime undef perl Readonly P800 P900 P910 perls Ipenburg

=head1 NAME

Date::Extract::P800Picture - extract the date from Sony Ericsson P800 pictures

=head1 VERSION

This document describes Date::Extract::P800Picture version C<v1.1.6>.

=head1 SYNOPSIS

    use Date::Extract::P800Picture;

    $filename = "8B360001.JPG"; # 2008-12-04T6:00:00

    $parser = new Date::Extract::P800Picture();
    $parser = new Date::Extract::P800Picture('filename' => $filename);

    $datetime = $parser->extract();
    $datetime = $parser->extract($filename);

=head1 DESCRIPTION

The Sony Ericsson L<P800|https://en.wikipedia.org/wiki/Sony_Ericsson_P800>,
L<P900|https://en.wikipedia.org/wiki/Sony_Ericsson_P900> and
L<P910|https://en.wikipedia.org/wiki/Sony_Ericsson_P910> camera phones store
pictures taken with the camera on the device with a filename consisting of the
date and the hour the picture was taken, followed by a four digit number and
the .JPG extension. The format of the date and the hour is YMDH, in which the
single characters are base 36 to fit a range of about 36 years, 12 months, 31
days and 24 hours since the year 2000 in a case insensitive US-ASCII
representation.

A L<web implementation of this parser|https://rolandvanipenburg.com/p800/> can
be used without installing this module.

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
C<DateExtractP800PictureException> is thrown when a date can not be extracted
from the string:

=over 4

=item * No date found in filename '%s'

=item * Filename is not set, nothing to extract

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * The date could be from another timezone, based on the device settings
and when and where the picture was taken.

=item * Usually the files are transferred from the P800 to other systems in a
way that has not completely preserved the timestamp of the file, so there is
no reliable way to double check the results by comparing the date extracted
from the filename with the timestamp of the file.

=item * There are no error values to provide different exit statuses for
different failure reasons

=back

Please report any bugs or feature requests at
L<Bitbucket|
https://bitbucket.org/rolandvanipenburg/date-extract-p800picture/issues>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2021, Roland van Ipenburg

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
