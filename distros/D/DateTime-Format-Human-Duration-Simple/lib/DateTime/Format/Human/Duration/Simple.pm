package DateTime::Format::Human::Duration::Simple;
use Moose;
use namespace::autoclean;

use Class::Load qw( try_load_class );

=head1 NAME

DateTime::Format::Human::Duration::Simple - Get a locale specific string
describing the span of a given datetime duration.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use DateTime::Format::Human::Duration::Simple;
    use DateTime;

    my $from = DateTime->now;
    my $to   = $from->clone->add(
        years   => 1,
        months  => 2,
        days    => 3,
        hours   => 4,
        minutes => 5,
        seconds => 6,
    );

    my $duration = DateTime::Format::Human::Duration::Simple->new(
        from           => $from, # required
        to             => $to,   # required
        # locale       => 'en',  # optional, default is 'en' (English)
        # serial_comma => 1,     # optional, default is 1 (true)
    );

    say $duration->formatted;
    # 1 year, 2 months, 3 days, 4 hours, 5 minutes, and 6 seconds

=head1 DESCRIPTION

This is a simple class for getting a localized string representing the duration
between two L<DateTime> objects.

This class is inspired by L<DateTime::Format::Human::Duration>, and shares its
namespace. I feel, however, that L<DateTime::Format::Human::Duration> is a bit
"heavy", and it's not updated very often. I also don't like its interface, so I
created this class for an alternative that better suited me. If it will suit
others, I don't know (or care), but there's always nice with alternatives. :)

=head1 METHODS

=head2 new( %args )

Constructs a new DateTime::Format::Human::Duration::Simple object;

    my $duration = DateTime::Format::Human::Duration::Simple->new(
        from           => DateTime->new( ... ), # required
        to             => DateTime->new( ... ), # required
        locale         => 'de',                 # optional (default = 'en')
        # serial_comma => 1,                    # optional, default is 1 (true)
    );

=cut

has 'from' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

has 'to' => (
    isa      => 'DateTime',
    is       => 'ro',
    required => 1,
);

has 'locale' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => 'en',
);

has 'locale_class' => (
    isa     => 'DateTime::Format::Human::Duration::Simple::Locale',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_locale_class',
);

sub _build_locale_class {
    my $self = shift;

    foreach my $locale ( $self->locale, 'en' ) {
        my $locale_class = 'DateTime::Format::Human::Duration::Simple::Locale::' . $locale;

        if ( try_load_class($locale_class) ) {
            return $locale_class->new;
        }
        else {
            warn "Failed to load localization class: " . $locale_class;
        }
    }

    die "Failed to create an instance of a localization class!";
}

has 'serial_comma' => (
    isa     => 'Bool',
    is      => 'ro',
    default => sub { shift->locale_class->serial_comma; }
);

=head2 duration

Returns the current L<DateTime::Duration> object, which is used by this class
behind the scenes to generate the localized output.

=cut

has 'duration' => (
    isa     => 'DateTime::Duration',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_duration',
);

sub _build_duration {
    my $self = shift;

    return $self->to - $self->from;
}

=head2 formatted

Returns the locale specific string describing the span of the duration in
question.

=cut

has 'formatted' => (
    isa     => 'Maybe[Str]',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_formatted',
);

sub _build_formatted {
    my $self = shift;

    my ( $years, $months, $weeks, $days, $hours, $minutes, $seconds, $nanoseconds ) = $self->duration->in_units( 'years', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds', 'nanoseconds' );

    # Convert the values to absolute values in case there
    # are negatives.
    $years       = abs( $years       );
    $months      = abs( $months      );
    $weeks       = abs( $weeks       );
    $days        = abs( $days        );
    $hours       = abs( $hours       );
    $minutes     = abs( $minutes     );
    $seconds     = abs( $seconds     );
    $nanoseconds = abs( $nanoseconds );

    # Calculate the number of milliseconds.
    my $milliseconds = 0;

    if ( $nanoseconds > 0 ) {
        $milliseconds = int( $nanoseconds * 0.000001 );
        $nanoseconds -= $milliseconds * 1_000_000;
    }

    if ( $years > 0 ) {
        $months = int( $months / $years );
    }

    if ( my $locale_class = $self->locale_class ) {

        # Localize the units.
        my @formatted = ();

        push( @formatted, $years        . ' ' . $locale_class->get_translation_for_value('year',        $years)   ) if ( $years        > 0 );
        push( @formatted, $months       . ' ' . $locale_class->get_translation_for_value('month',       $months)  ) if ( $months       > 0 );
        push( @formatted, $weeks        . ' ' . $locale_class->get_translation_for_value('week',        $weeks)   ) if ( $weeks        > 0 );
        push( @formatted, $days         . ' ' . $locale_class->get_translation_for_value('day',         $days)    ) if ( $days         > 0 );
        push( @formatted, $hours        . ' ' . $locale_class->get_translation_for_value('hour',        $hours)   ) if ( $hours        > 0 );
        push( @formatted, $minutes      . ' ' . $locale_class->get_translation_for_value('minute',      $minutes) ) if ( $minutes      > 0 );
        push( @formatted, $seconds      . ' ' . $locale_class->get_translation_for_value('second',      $seconds) ) if ( $seconds      > 0 );
        push( @formatted, $milliseconds . ' ' . $locale_class->get_translation_for_value('millisecond', $seconds) ) if ( $milliseconds > 0 );
        push( @formatted, $nanoseconds  . ' ' . $locale_class->get_translation_for_value('nanosecond',  $seconds) ) if ( $nanoseconds  > 0 );

        my $and       = $locale_class->get_translation_for_value( 'and' );
        my $formatted = join( ', ', @formatted );

        # Use a serial comma?
        if ( scalar(@formatted) == 2 || not $self->serial_comma ) {
            $formatted =~ s/(.+),/$1 \Q$and\E/;
        }
        else {
            $formatted =~ s/(.+,)/$1 \Q$and\E/;
        }

        # Return.
        return $formatted;

    }
}

=head1 What is the "serial comma"?

The "serial comma", also called the "oxford comma", is an optional comma before
the word "and" (and/or other separating words) at the end of the list. Consider
not using a serial comma:

    1 hour, 2 minutes and 3 seconds

...vs. using a serial comma:

    1 hour, 2 minutes, and 3 seconds

This value is defined per locale, i.e. from what's most normal (...) in each
locale, but you can override when generating an instance of this class;

    my $human = DateTime::Format::Human::Duration::Simple->new(
        from         => $from_datetime,
        to           => $to_datetime,
        serial_comma => 0, # turn it off for all locales
    );

You can read more about the serial comma L<on Wikipedia|https://en.wikipedia.org/wiki/Serial_comma>.

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Dist/Display.html?Name=DateTime-Format-Human-Duration-Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime-Format-Human-Duration-Simple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Format-Human-Duration-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Format-Human-Duration-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Format-Human-Duration-Simple/>

=back

=head1 SEE ALSO

=over 4

=item * L<DateTime>

=item * L<DateTime::Duration>

=item * L<DateTime::Format::Human::Duration>

=back

=head1 LICENSE AND COPYRIGHT

The MIT License (MIT)

Copyright (c) 2015 Tore Aursand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=cut

__PACKAGE__->meta->make_immutable;

1;
