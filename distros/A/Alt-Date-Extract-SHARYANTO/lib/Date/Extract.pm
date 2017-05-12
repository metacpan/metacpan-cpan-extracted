package Date::Extract;
use strict;
use warnings;
use DateTime::Format::Natural;
use List::Util 'reduce';
use parent 'Class::Data::Inheritable';

our $VERSION = '0.05.01'; # VERSION
our $DATE = '2014-06-09'; # DATE

__PACKAGE__->mk_classdata($_) for qw/scalar_downgrade handlers regex/;

sub _croak {
    require Carp;
    Carp::croak @_;
}

sub new {
    my $class = shift;
    my %args = (
        format => 'DateTime',
        returns => 'first',
        prefers => 'nearest',
        time_zone => 'floating',
        @_,
    );

    if ($args{format} ne 'DateTime'
     && $args{format} ne 'verbatim'
     && $args{format} ne 'epoch'
     && $args{format} ne 'combined') {
        _croak "Invalid `format` passed to constructor: expected `DateTime', `verbatim', `epoch', `combined'.";
    }

    if ($args{returns} ne 'first'
     && $args{returns} ne 'last'
     && $args{returns} ne 'earliest'
     && $args{returns} ne 'latest'
     && $args{returns} ne 'all'
     && $args{returns} ne 'all_cron') {
        _croak "Invalid `returns` passed to constructor: expected `first', `last', `earliest', `latest', `all', or `all_cron'.";
    }

    if ($args{prefers} ne 'nearest'
     && $args{prefers} ne 'past'
     && $args{prefers} ne 'future') {
        _croak "Invalid `prefers` passed to constructor: expected `nearest', `past', or `future'.";
    }

    my $self = bless \%args, ref($class) || $class;

    return $self;
}

# This method will combine the arguments of parser->new and extract. Modify the
# "to" hash directly.

sub _combine_args {
    shift;

    my $from = shift;
    my $to = shift;

    $to->{format}    ||= $from->{format};
    $to->{prefers}   ||= $from->{prefers};
    $to->{returns}   ||= $from->{returns};
    $to->{time_zone} ||= $from->{time_zone};
}

sub extract {
    my $self = shift;
    my $text = shift;
    my %args = @_;

    # using extract as a class method
    $self = $self->new
        if !ref($self);

    # combine the arguments of parser->new and this
    $self->_combine_args($self, \%args);

    # when in scalar context, downgrade
    $args{returns} = $self->_downgrade($args{returns})
        unless wantarray;

    # do the work
    my @ret = $self->_extract($text, %args);

    # munge the output to match the desired return type
    return $self->_handle($args{returns}, @ret);
}

# build the giant regex used for parsing. it has to be a single regex, so that
# the order of matches is correct.
sub _build_regex {
    my $self = shift;

    my $relative          = '(?:today|tomorrow|yesterday)';

    my $long_weekday      = '(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)';
    my $short_weekday     = '(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)';
    my $weekday           = "(?:$long_weekday|$short_weekday)";

    my $relative_weekday  = "(?:(?:next|previous|last)\\s*$weekday)";

    my $long_month        = '(?:January|February|March|April|May|June|July|August|September|October|November|December)';
    my $short_month       = '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)';
    my $month             = "(?:$long_month|$short_month)";

    # 1 - 31
    my $cardinal_monthday = "(?:[1-9]|[12][0-9]|3[01])";
    my $monthday          = "(?:$cardinal_monthday(?:st|nd|rd|th)?)";

    my $day_month         = "(?:$monthday\\s*$month)";
    my $month_day         = "(?:$month\\s*$monthday)";
    my $day_month_year    = "(?:(?:$day_month|$month_day)\\s*,?\\s*\\d\\d\\d\\d)";

    my $yyyymmdd          = "(?:\\d\\d\\d\\d[-/]\\d\\d[-/]\\d\\d)";
    my $ddmmyy            = "(?:\\d\\d[-/]\\d\\d[-/]\\d\\d)";
    my $ddmmyyyy          = "(?:\\d\\d[-/]\\d\\d[-/]\\d\\d\\d\\d)";

    my $other             = $self->_build_more_regex;
    $other = "|$other"
        if $other;

    my $regex = qr{
        \b(
            $relative         # today
          | $relative_weekday # last Friday
          | $weekday          # Monday
          | $day_month_year   # November 13th, 1986
          | $day_month        # November 13th
          | $month_day        # 13 Nov
          | $yyyymmdd         # 1986/11/13
          | $ddmmyy           # 11-13-86
          | $ddmmyyyy         # 11-13-1986
            $other            # anything from the subclass
        )\b
    }ix;

    $self->regex($regex);
}

# this is to be used in subclasses for adding more stuff to the regex
# for example, to add support for $foo_bar and $baz_quux, return
# "$foo_bar|$baz_quux"
sub _build_more_regex { '' }

# build the list->scalar downgrade types
sub _build_scalar_downgrade {
    my $self = shift;

    $self->scalar_downgrade({
        all      => 'first',
        all_cron => 'earliest',
    });
}

# build the handlers that munge the list of dates to the desired order
sub _build_handlers {
    my $self = shift;

    $self->handlers({
        all_cron => sub {
            sort { DateTime->compare_ignore_floating($a, $b) } @_
        },
        all      => sub { @_ },

        earliest => sub { reduce { $a < $b ? $a : $b } @_ },
        latest   => sub { reduce { $a > $b ? $a : $b } @_ },
        first    => sub { $_[0]  },
        last     => sub { $_[-1] },
    });
}

# actually perform the scalar downgrade
sub _downgrade {
    my $self    = shift;
    my $returns = shift;

    my $downgrades = $self->scalar_downgrade || $self->_build_scalar_downgrade;
    return $downgrades->{$returns} || $returns;
}

sub _handle {
    my $self    = shift;
    my $returns = shift;

    my $handlers = $self->handlers || $self->_build_handlers;
    my $handler = $handlers->{$returns};
    return defined $handler ? $handler->(@_) : @_
}

sub _extract {
    my $self = shift;
    my $text = shift;
    my %args = @_;

    my $fmt = $self->{format};

    my $regex = $self->regex || $self->_build_regex;
    my @combined;
    while ($text =~ /$regex/g) {
        push @combined, {
            pos => $-[0],
            verbatim => $1,
        };
    }

    return (map {$_->{verbatim}} @combined) if $fmt eq 'verbatim';

    my %dtfn_args;
    $dtfn_args{prefer_future} = 1
        if $args{prefers} && $args{prefers} eq 'future';
    $dtfn_args{time_zone} = $args{time_zone};

    my $parser = DateTime::Format::Natural->new(%dtfn_args);
    for (@combined) {
        my $dt = $parser->parse_datetime($_->{verbatim});
        if ($parser->success) {
            $dt->set_time_zone($args{time_zone});
            $_->{DateTime} = $dt;
        }
    }

    if ($fmt eq 'epoch') {
        return map { $_->{DateTime}->epoch } @combined;
    } elsif ($fmt eq 'combined') {
        return @combined;
    } else {
        return map {$_->{DateTime}} @combined;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Extract

=head1 VERSION

version 0.05.01

=head1 SYNOPSIS

    my $parser = Date::Extract->new();
    my $dt = $parser->extract($arbitrary_text)
        or die "No date found.";
    return $dt->ymd;

=head1 NAME

Date::Extract - extract probable dates from strings

=head1 MOTIVATION

There are already a few modules for getting a date out of a string.
L<DateTime::Format::Natural> should be your first choice. There's also
L<Time::ParseDate> which fits many formats. Finally, you can coerce
L<Date::Manip> to do your bidding.

But I needed something that will take an arbitrary block of text, search it for
something that looks like a date string, and extract it. This module fills this
niche. By design it will produce few false positives. This means it will not
catch nearly everything that looks like a date string. So if you have the string
"do homework for class 2019" it won't return a L<DateTime> object with the year
set to 2019. This is what your users would probably expect.

=head1 METHODS

=head2 new PARAMHASH => C<Date::Extract>

=head3 arguments

=over 4

=item format

Choose what format the extracted date(s) will be. The default is "DateTime",
which will return L<DateTime> object(s). Other option include "verbatim" (return
the original text), "epoch" (return Unix timestamp), or "combined" (return
hashref containing these keys "verbatim", "DateTime", "pos" [position of date
string in the text]).

=item time_zone

Only relevant when C,format> is set to "DateTime".

Forces a particular time zone to be set (this actually matters, as "tomorrow"
on Monday at 11 PM means something different than "tomorrow" on Tuesday at 1
AM).

By default it will use the "floating" time zone. See the documentation for
L<DateTime>.

This controls both the input time zone and output time zone.

=item prefers

This argument decides what happens when an ambiguous date appears in the
input. For example, "Friday" may refer to any number of Fridays. The valid
options for this argument are:

=over 4

=item nearest

Prefer the nearest date. This is the default.

=item future

Prefer the closest future date.

=item past

Prefer the closest past date. B<NOT YET SUPPORTED>.

=back

=item returns

If the text has multiple possible dates, then this argument determines which
date will be returned. By default it's 'first'.

=over 4

=item first

Returns the first date found in the string.

=item last

Returns the final date found in the string.

=item earliest

Returns the date found in the string that chronologically precedes any other
date in the string.

=item latest

Returns the date found in the string that chronologically follows any other
date in the string.

=item all

Returns all dates found in the string, in the order they were found in the
string.

=item all_cron

Returns all dates found in the string, in chronological order.

=back

=back

=head2 extract text, ARGS => dates

Takes an arbitrary amount of text and extracts one or more dates from it. The
return value will be zero or more dates, which by default are L<DateTime>
objects (but can be customized with the C<format> argument). If called in scalar
context, only one will be returned, even if the C<returns> argument specifies
multiple possible return values.

See the documentation of C<new> for the configuration of this method. Any
arguments passed into this method will trump those from the constructor.

You may reuse a parser for multiple calls to C<extract>.

You do not need to have an instantiated C<Date::Extract> object to call this
method. Just C<< Date::Extract->extract($foo) >> will work.

=head1 FORMATS HANDLED

=over 4

=item * today; tomorrow; yesterday

=item * last Friday; next Monday; previous Sat

=item * Monday; Mon

=item * November 13th, 1986; Nov 13, 1986

=item * 13 November 1986; 13 Nov 1986

=item * November 13th; Nov 13

=item * 13 Nov; 13th November

=item * 1986/11/13; 1986-11-13

=item * 11-13-86; 11/13/1986

=back

=head1 CAVEATS

This module is I<intentionally> very simple. Surprises are I<not> welcome
here.

=head1 SEE ALSO

L<DateTime::Format::Natural>, L<Time::ParseDate>, L<Date::Manip>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
