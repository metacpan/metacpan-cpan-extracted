package DateTime::Format::Human::Duration;

use warnings;
use strict;
require DateTime::Format::Human::Duration::Locale;

our $VERSION = '0.64';

use Carp qw/croak/;

sub new {
    bless { 'locale_cache' => {} }, 'DateTime::Format::Human::Duration';  
}

sub format_duration_between {
    my ($span, $dt, $dtb, %args) = @_;
    my $dur = $dt - $dtb;

    if (!exists $args{'locale'}) {
        my $locale_obj = $dt->locale;
        if (UNIVERSAL::can($locale_obj, 'code')) {
            $args{'locale'} = $locale_obj->code; # DateTime::Locale v1
        } else {
            $args{'locale'} = $locale_obj->id;   # DateTime::Locale v0
        }
    }
    
    return $span->format_duration($dur, %args);    
}

sub format_duration {
    my ($span, $duration, %args) = @_;
    
    my @default_units = qw(years months weeks days hours minutes seconds nanoseconds);

    my @units = $args{'units'} ? @{ $args{'units'} } : @default_units;
    if ($args{'precision'}) {
        # Reduce time resolution to requested precision
        for (my $i = 0; $i < scalar(@units); $i++) {
            next unless ($units[$i] eq $args{'precision'});
            splice(@units, $i + 1);
        }
        croak('Useless precision') unless (@units);
    }

    my @duration_vals = $duration->in_units( @units ); 
    my $i = 0;
    my %duration_vals = map { ($_ => $duration_vals[$i++]) } @units;
    my %positive_duration_vals = map { ($_ => abs $duration_vals{$_}) } keys %duration_vals;

    my $say = '';
    
    # $dta - $dtb:
    #   if dta < dtb means past -> future (Duration units will have negatives)
    #   else its either this absolute instant (no_time) or the past
    if ( grep { $_ < 0 } @duration_vals ) {
        if ( exists $args{'future'} ) {
            $say = $args{'future'}    
        }        
    }
    else {
        if ( exists $args{'past'} ) {
            $say = $args{'past'}    
        }
    }
    
    ####
    ## this is essentially the hashref that is returned from DateTime::Format::Human::Duration::en::get_human_span_hashref() : #
    ####
    my $setup = {
        'no_oxford_comma' => 0,
        'no_time' => 'no time', # The wait will be $formatted_duration   
        'and'     => 'and',    
        'year'  => 'year',
        'years' => 'years',
        'month'  => 'month',
        'months' => 'months',
        'week'  => 'week',
        'weeks' => 'weeks',
        'day'  => 'day',
        'days' => 'days',
        'hour'  => 'hour',
        'hours' => 'hours',
        'minute'  => 'minute',
        'minutes' => 'minutes',
        'second'  => 'second',
        'seconds' => 'seconds',
        'nanosecond'  => 'nanosecond',
        'nanoseconds' => 'nanoseconds',        
    };

    my $locale = DateTime::Format::Human::Duration::Locale::calc_locale($span, $args{'locale'});
 
    if($locale) {
        if ( ref $locale eq 'HASH' ) {
            %{ $setup } = (
                %{ $setup },
                %{ $locale },
            );            
        }
        # get_human_span_from_units_array is deprecated, but we will still
        # support it.
        elsif ( my $get1 = $locale->can('get_human_span_from_units_array') ) {
            my @n = map { $positive_duration_vals{$_} } @default_units;
            return $get1->( @n, \%args );
        }
        elsif ( my $get2 = $locale->can('get_human_span_from_units') ) {
            return $get2->( \%duration_vals, \%args );
        }
    }

    my @parts;
    for my $unit (@units) {
        my $val = $positive_duration_vals{$unit};
        next unless $val;

        my $setup_key = $unit;
        if ($val == 1) {
            $setup_key =~ s/s$//;
        }

        push(@parts, $val . ' ' . $setup->{$setup_key});
        if (exists $args{'significant_units'}) {
            last if scalar(@parts) == $args{'significant_units'};
        }
    }
    
    my $no_time = exists $args{'no_time'} ? $args{'no_time'} : $setup->{'no_time'};
    return $no_time if !@parts;

    my $last = @parts > 1 ? pop(@parts): '';

    ## We want to use the so-called Oxford comma to avoid ambiguity. 
    ## For that reason we make locale's specifically tell us they do not want it.
    my $string = $setup->{'no_oxford_comma'} 
        ? join(', ', @parts) . ($last ? " $setup->{'and'} $last" : '')
        : join(', ', @parts) . (@parts > 1  ? ',' : '') . ($last ? " $setup->{'and'} $last" : '')
        ;

    if ( $say ) {
       $string = $say =~ m{%s} ? sprintf($say, $string): "$say $string";    
    }

    return $string;
}

1; 

__END__

=encoding utf8

=head1 NAME

DateTime::Format::Human::Duration - Get a locale specific string describing the span of a given duration

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Format::Human::Duration

    my $span = DateTime::Format::Human::Duration->new();
    my $dur = $dta - $dtb;
    print $span->format_duration($dur); # 1 year, 2 months, 3 minutes, and 1 second
  
    print $span->format_duration_between($dta, $dtb); # 1 year, 2 months, 3 minutes, and 1 second

=head1 DESCRIPTION

Get a localized string representing the duration.

For example:

    1 second
    2 minutes and 3 seconds
    3 weeks, 1 day, and 5 seconds
    4 years, 1 month, 2 days, 6 minutes, 1 second, and 345000028 nanoseconds

=head1 INTERFACE 

=head2 new()

Create span object, no args

=head2 format_duration()

First argument is a DateTime::Duration object

After that you can optionally pass some L</standard args> as a hash as described below

=head2 format_duration_between()

First two args are DateTime objects

After that you can optionally pass some L</standard args> as a hash as described below

=head2 standard args

=over 4

=item 1. 'locale' 

locale of the $dt object will be used if you do not specify this

Valid values are a string of the locale (E.g 'fr'), a DateTime object, or a DateTime object's 'locale' key.

=item 2. Since we're working with 2 DateTime objects of known points we can have past and future tenses.

=over 4

=item * past

String to use if duration is past tense. Can have a sprintf '%s' or else is prepended with a trailing space.

=item * future

String to use if duration is future tense. Can have a sprintf '%s' or else is prepended with a trailing space.

=item * no_time 

Override the 'no_time' in the locale hash.

=back

If duration is baseless (IE ambiguous) then 'past' and 'future' is used based on if $dur->in_units has negatives or not.

Also by nature it's not split into type groups:

An example is

  DateTime::Duration->new('seconds'=> 62)
  
Will result in '62 seconds' not '1 minute and 2 seconds'

For more sane results always be specific by using 2 datetime object to get a duration object

    print $dt->format_duration_between(
        $dta,
        $dtb, 
        'past'   => 'Your account expired %s ago.', 
        'future' => 'Your account expires in %s.', 
        'no_time'=> 'Your account just expired.',
    );

This facilitates, for example, this L<Locale::Maketext> vernacular which becomes:

   'Your account [duration,_1,_2,expired %s ago,expires in,just expired].' => '[Votre compte [duration,_1,_2,a expiré il ya,expire dans,vient d'expirer].'

=item 3. Time Resolution and Units

=over 4

=item * units

Specify units to format duration with. Arguments will be passed to DateTime::Format's in_unit() method.

Example:

    my $fmt = DateTime::Format::Human::Duration->new();
    my $d = DateTime::Duration->new(...);
  
    my $s = $fmt->format_duration($d, 'units' => [qw/years months days/] );
    # $s == '1 year, 7 months, and 16 days'

Possible values include: years months weeks days hours minutes seconds nanoseconds

=item * precision

By default, the duration will be formatted using nanosecond resolution. Resolution can be reduced by passing
'years', 'months', 'weeks', 'days', 'hours', 'minutes', or 'seconds' to the 'precision' argument.

Example:

    my $fmt = DateTime::Format::Human::Duration->new();
    my $d = DateTime::Duration->new(...);
  
    print $fmt->format_duration($d);
    # '1 year, 7 months, 2 weeks, 2 days, 13 hours, 43 minutes, and 15 seconds'
  
    print $fmt->format_duration($d, 'precision' => 'days');
    # '1 year, 7 months, 2 weeks, and 2 days'

=item * significant_units

By default, the duration will be formatted using all specified units.  To restrict the number of units output, set this to a value of one or more.

Example:

    my $fmt = DateTime::Format::Human::Duration->new();
    my $d = DateTime::Duration->new(...);
  
    print $fmt->format_duration($d, 'significant_units' => 1);
    # '3 days'
    print $fmt->format_duration($d, 'significant_units' => 2);
    # '3 days and 10 hours'
    print $fmt->format_duration($d, 'significant_units' => 3);
    # '3 days, 10 hours, and 27 minutes'

=back

=back

=head1 LOCALIZATION

Localization is provided by the included DateTime::Format::Human::Duration::Locale modules.

Included are DateTime::Format::Human::Duration::Locale::es, DateTime::Format::Human::Duration::Locale::fr, DateTime::Format::Human::Duration::Locale::pt,
DateTime::Format::Human::Duration::Locale::de, DateTime::Format::Human::Duration::Locale::it

More will be included as time permits/folks volunteer/CLDR becomes an option

They are setup this way:

DateTime::Format::Human::Duration::Locale::XYZ where 'XYZ' is the ISO code of DateTime::Locale

It can have one of 2 functions:

=over 4

=item get_human_span_hashref()

Takes no arguments, should return a hashref of this structure:

    sub get_human_span_hashref {
        return {
            'no_oxford_comma' => 1,
            'no_time' => 'pas le temps',
            'and'     => 'et',    
            'year'  => 'an',
            'years' => 'ans',
            'month'  => 'mois',
            'months' => 'mois',
            'week'  => 'semaine',
            'weeks' => 'semaines',
            'day'  => 'jour',
            'days' => 'jours',
            'hour'  => 'heure',
            'hours' => 'heures',
            'minute'  => 'minute',
            'minutes' => 'minutes',
            'second'  => 'seconde',
            'seconds' => 'seconds',
            'nanosecond'  => 'nanoseconde',
            'nanoseconds' => 'nanosecondes',      
        };
    }

=item get_human_span_from_units()

Try to use L</get_human_span_hashref()> if the locale allows for it since it's much easier. If you cannot, however, then this will give you the maximum level of configurability.

This function receives a hashref of duration values, and a hashref of the L</standard args>. It should return the localized string.

    sub get_human_span_from_units {
        my ($duration_values_hr, $args_hr) = @_;
        ...;
        return $string; # 1 year, 2days, 4 hours, and 17 minutes
    }

Please see the example in C<t/lib/DateTime/Format/Human/Duration/Locale/nb.pm>.

=back

=head1 LOCALIZATION of DateTime::Format modules

L<DateTime> does an excellent job at implementing localization. Often L<DateTime::Format> based class's either don't support localization or they implement it haphazardly and inconsistently.

With this module I hope to model a localization scheme that is inline with L<DateTime> and is consistent and reuseable between <DateTime::Format> based classes.

The idea is to determine the locale to use based on a DateTime object.

XYZ::Locale should handle looking up (and caching if appropriate) the locale and loading the necessary locale module XYZ::Locale::fr

The specific locale module holds the data and possibly logic necessary to do what XYZ does in the vernacular of the given locale.

=head2 TODO 

Eventually the generic logic will be re-broken out into its own module for re-use by your class and I'll have more detailed POD about how to do it.

In the meantime if you're interested please contact me and I'd be happy to help and/or expediate this TODO.

Also, Dave Rolksy has mentioned to me that this sort of locale data might be appropriate for DateTime::Locale directly from CLDR. If that happens this module will be changed to use that if possible.

=head1 FAQ

=head2 Why would I want to use this?

So you can localize your application's output of time periods without having to do a lot of logic each time you wanted to say it.

L<Locale::Maketext::Utils> has/will have a duration() bracket notation method which prompted this module's existence

duration() was prompted by its datetime() brother, all of which uses the most excellent DateTime project!

=head2 Why did my duration say '62 seconds' instead of '1 minute and 2 seconds'

Because you used an ambiguous duration (one without a base) so there is no way to 
apply date math and accurately represent the number of each given item in that 
duration since it may or may not span leap-[second, days, years, etc..]

In other words do this (so that your duration can be specifically calculated):

    $dtb = $dta->clone->add('seconds'=> 62);
    my $duration = $dta - $dtb; # has a base, its not ambiguous
    print $span->format_duration($duration); # 1 minutes and 2 seconds

not this:

    my $duration = DateTime::Duration->new('seconds'=> 62); # no base, it is ambiguous
    print $span->format_duration($duration); # 62 seconds

Note L</format_duration_between>(), does not suffer from this since we're using a specific DateTime object already.

    print $span->format_duration_between( $dt, $dt->clone()->add('seconds'=> 62) ); # 1 minute and 2 seconds

=head2 Why do you put a comma before the 'and' in a group of more than 2 items?

We want to use the so-called Oxford comma to avoid ambiguity.

=head2 My DateTime::Format::Human::Duration::Locale::XX still outputs in English!

That is because it defined neither the L</get_human_span_hashref()> or the L</get_human_span_from_units()> functions

It must define one of them or defaults are used.

=head2 Why didn't you just use 'DateTime::Format::Duration'

Essencially DateTime::Format::Duration is an object representing a single strftime() type string to apply to any given duration. This is not flexible enough for the intent of this module.

DateTime::Format::Duration is not a bad module its just for a different purpose than DateTime::Format::Human::Duration

=over 4

=item * It was not localizable

You either got '2 days' or '1 days' which a) forces it to be in English and b) doesn't even make sense in English.

You could get around that by adding logic each time you wanted to call it but that is just messy.

=item * Had to keep an item even if it was zero

If 'days' was in there you got '0 days', we only want items with a value to show.

That'd also require a lot of logic each time you wanted to call which is again messy.

=item * This module has no need for reparsing output back into an object

Since the datetime info for 2 points in time are generally in a form easily rendered into a DateTime object it'd be silly to even attempt to store and parse the output of this module back into an object. 

Plus since it all depends on the locale it is in it'd be difficult.

=back

The purpose of DateTime::Format::Human::Duration was to generate a localized human language description of a duration without the caller needing to supply any logic.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own

=head1 CONFIGURATION AND ENVIRONMENT

DateTime::Format::Human::Duration requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-datetime-format-span@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
