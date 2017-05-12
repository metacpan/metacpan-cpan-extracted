package DateTime::Format::Mail;
# $Id$
$DateTime::Format::Mail::VERSION = '0.403';
use strict;
use 5.005;
use Carp;
use DateTime 1.04;
use Params::Validate qw( validate validate_pos SCALAR );
use vars qw( $VERSION );

my %validations = (
    year_cutoff =>  {
        type => SCALAR,
        callbacks => {
            'greater than or equal to zero, less than 100' => sub {
                defined $_[0]
                    and $_[0] =~ /^ \d+ $/x
                    and $_[0] >= 0
                    and $_[0] < 100
            },
        },
    }
);

# Timezones for strict parser.
my %timezones = qw(
    EDT -0400   EST -0500       CDT -0500       CST -0600
    MDT -0600   MST -0700       PDT -0700       PST -0800
    GMT +0000   UT  +0000
);
my $tz_RE = join( '|', sort keys %timezones );
$tz_RE= qr/(?:$tz_RE)/;
$timezones{UTC} = $timezones{UT};

# Strict parser regex

# Lovely regex. Mostly a translation of the BNF in 2822.
# XXX - need more thorough tests to ensure it's *strict*.

my $strict_RE = qr{
    ^ \s* # optional
    # [day-of-week "," ]
    (?:
      (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun) ,
      \s+
    )?
    # date => day month year
    (\d{1,2})  # day => 1*2DIGIT
    \s+
    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) # month-name
    \s*
    ((?:\d\d)?\d\d) # year
    # FWS
    \s+
    # time
    (\d\d):(\d\d):(\d\d) # time
    (?:
        \s+ (
            [+-] \d{4}  # standard form
            | $tz_RE    # obsolete form (mostly ignored)
            | [A-IK-Za-ik-z]  # including military (no 'J')
            ) # time zone (optional)
    )?
    \s* $
}ox;

# Loose parser regex
my $loose_RE = qr{
    ^ \s* # optional
    (?i:
        (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun|[A-Z][a-z][a-z]) ,? # Day name + comma
    )?
        # (empirically optional)
    \s*
    (\d{1,2})  # day of month
    [-\s]*
    (?i: (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ) # month
    [-\s]*
    ((?:\d\d)?\d\d) # year
    \s+
    (\d?\d):(\d?\d) (?: :(\d?\d) )? # time
    (?:
        \s+ "? (
            [+-] \d{4}  # standard form
            | [A-Z]+    # obsolete form (mostly ignored)
            | GMT [+-] \d+      # empirical (converted)
            | [A-Z]+\d+ # bizarre empirical (ignored)
            | [a-zA-Z/]+        # linux style (ignored)
            | [+-]{0,2} \d{3,5} # corrupted standard form
            ) "? # time zone (optional)
    )?
        (?: \s+ \([^\)]+\) )? # (friendly tz name; empirical)
    \s* \.? $
}x;

sub _set_parse_method
{
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    $self->{parser_method} = shift;
    return $self;
}

sub _get_parse_method
{
    my $self = shift;
    my $method = ref($self) ? $self->{parser_method} : '';
    $method ||= '_parse_strict';
}

sub new
{
    my $class = shift;
    my %args = validate( @_, {
            loose => {
                type => SCALAR,
                default => 0,
            },
            year_cutoff => {
                %{ $validations{year_cutoff} },
                default => $class->default_cutoff,
            },
        }
    );

    my $self = bless {}, ref($class)||$class;
    if (ref $class)
    {
        # If called on an object, clone
        $self->_set_parse_method( $class->_get_parse_method );
        $self->set_year_cutoff( $class->year_cutoff );
        # and that's it. we don't store much info per object
    }
    else
    {
        my $parser = $args{loose} ? "loose" : "strict";
        $self->$parser();
        $self->set_year_cutoff( $args{year_cutoff} ) if $args{year_cutoff};
    }

    $self;
}

sub clone
{
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    return $self->new();
}

sub loose
{
    my $self = shift;
    croak "loose() takes no arguments!" if @_;
    return $self->_set_parse_method( '_parse_loose' );
}

sub strict
{
    my $self = shift;
    croak "strict() takes no arguments!" if @_;
    return $self->_set_parse_method( '_parse_strict' );
}

sub _parse_strict
{
    my $self = shift;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my @parsed = $date =~ $strict_RE;
    croak "Invalid format for date!" unless @parsed;
    my %when;
    @when{qw( day month year hour minute second time_zone)} = @parsed;
    return \%when;
}

sub _parse_loose
{
    my $self = shift;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my @parsed = $date =~ $loose_RE;
    croak "Invalid format for date!" unless @parsed;
    my %when;
    @when{qw( day month year hour minute second time_zone)} = @parsed;
    $when{month} = "\L\u$when{month}";
    $when{second} ||= 0;
    return \%when;
}

sub parse_datetime
{
    my $self = shift;
    croak "No date specified for parse_datetime." unless @_;
    croak "Too many arguments to parse_datetime." if @_ != 1;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my $method = $self->_get_parse_method();
    my %when = %{ $self->$method($date) };
    $when{time_zone} ||= '-0000';

    my %months = do { my $i = 1;
        map { $_, $i++ } qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    };
    $when{month} = $months{$when{month}}
        or croak "Invalid month `$when{month}'.";

    $when{year} = $self->fix_year( $when{year} );
    $when{time_zone} = _determine_timezone( $when{time_zone} );
    $when{time_zone} = 'floating' if $when{time_zone} eq '-0000';

    my $date_time = DateTime->new( %when );

    return $date_time;
}

sub _determine_timezone
{
    my $tz = shift;
    return '-0000' unless defined $tz; # return quickly if nothing needed
    return $tz if $tz =~ /^[+-]\d{4}$/;

    $tz =~ s/ ^ [+-] (?=[+-]) //x; # for when there are two signs

    if (exists $timezones{$tz}) {
        $tz = $timezones{$tz};
    } elsif (substr($tz, 0, 3) eq 'GMT' and length($tz)  > 4) {
        $tz = sprintf "%5.5s", substr($tz,3)."0000";
    } elsif ( $tz =~ /^ ([+-]?) (\d+) $/x) {
        my $p = $1||'+';
        $tz = sprintf "%s%04d", $p, $2;
    } else {
        $tz = "-0000";
    }

    return $tz;
}

sub set_year_cutoff
{
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    validate_pos( @_, $validations{year_cutoff} );
    croak "Wrong number of arguments (should be 1) to set_year_cutoff"
        unless @_ == 1;
    my $cutoff = shift;
    $self->{year_cutoff} = $cutoff;
    return $self;
}

# rfc2822, 4.3. Obsolete Date and Time
#   Where a two or three digit year occurs in a date, the year is to be
#   interpreted as follows: If a two digit year is encountered whose
#   value is between 00 and 49, the year is interpreted by adding 2000,
#   ending up with a value between 2000 and 2049.  If a two digit year is
#   encountered with a value between 50 and 99, or any three digit year
#   is encountered, the year is interpreted by adding 1900.
sub default_cutoff
{
    49;
}

sub year_cutoff
{
    my $self = shift;
    croak "Too many arguments (should be 0) to year_cutoff" if @_;
    (ref $self and $self->{year_cutoff}) or $self->default_cutoff;
}

sub fix_year
{
    my $self = shift;
    my $year = shift;
    return $year if length $year >= 4; # Return quickly if we can

    my $cutoff = $self->year_cutoff;
    $year += $year > $cutoff ? 1900 : 2000;
    return $year;
}

sub format_datetime
{
    my $self = shift;
    croak "No DateTime object specified." unless @_;
    my $dt = $_[0]->clone;
    $dt->set_locale('en_US');

    my $rv = $dt->strftime( "%a, %e %b %Y %H:%M:%S %z" );
    $rv =~ s/\+0000$/-0000/ if $dt->time_zone->is_floating;
    $rv;
}

1;

__END__

=head1 NAME

DateTime::Format::Mail - Convert between DateTime and RFC2822/822 formats

=head1 SYNOPSIS

    use DateTime::Format::Mail;

    # From RFC2822 via class method:

    my $datetime = DateTime::Format::Mail->parse_datetime(
        "Sat, 29 Mar 2003 22:11:18 -0800"
    );
    print $datetime->ymd('.'); # "2003.03.29"

    #  or via an object
    
    my $pf = DateTime::Format::Mail->new();
    print $pf->parse_datetime(
        "Fri, 23 Nov 2001 21:57:24 -0600"
    )->ymd; # "2001-11-23"

    # Back to RFC2822 date
    
    use DateTime;
    my $dt = DateTime->new(
        year => 1979, month => 7, day => 16,
        hour => 16, minute => 45, second => 20,
        time_zone => "Australia/Sydney"
    );
    my $str = DateTime::Format::Mail->format_datetime( $dt );
    print $str; # "Mon, 16 Jul 1979 16:45:20 +1000"

    # or via an object
    $str = $pf->format_datetime( $dt );
    print $str; # "Mon, 16 Jul 1979 16:45:20 +1000"

=head1 DESCRIPTION

RFCs 2822 and 822 specify date formats to be used by email. This
module parses and emits such dates.

RFC2822 (April 2001) introduces a slightly different format of
date than that used by RFC822 (August 1982). The main correction
is that the preferred format is more limited, and thus easier to
parse programmatically.

Despite the ease of generating and parsing perfectly valid RFC822 and
RFC2822 people still get it wrong. So this module provides four things
for those handling mail dates:

=over 4

=item 1

A strict parser that will only accept RFC2822 dates, so you can
see where you're right.

=item 2

A strict formatter, so you can generate the right stuff
to begin with.

=item 3

A I<loose> parser, so you can take the misbegotten output
from other programs and turn it into something useful.
This includes various minor errors as well as some somewhat more
bizarre mistakes. The file F<t/sample_dates> in this module's
distribution should give you an idea of what's valid, while
F<t/invalid.t> should do the same for what's not. Those regarded
as invalid are just a bit B<too> strange to allow.

=item 4

Interoperation with the rest of the L<DateTime> suite. These are
a collection of modules to handle dates in a modern and accurate
fashion. In particular, they make it trivial to parse, manipulate
and then format dates. Shifting timezones is a doddle, and
converting between formats is a cinch.

=back

As a future direction, I'm contemplating an even stricter
parser that will only accept dates with no obsolete elements.

=head1 CONSTRUCTORS

=head2 new

Creates a new C<DateTime::Format::Mail> instance. This is
generally not required for simple operations. If you wish to use
a different parsing style from the default, strict, parser then
you'll need to create an object.

   my $parser = DateTime::Format::Mail->new()
   my $copy = $parser->new();

If called on an existing object then it clones the object.

It has two optional named parameters.

=over 4

=item *

C<loose> should be a true value if you want a loose parser,
else either don't specify it or give it a false value.

=item *

C<year_cutoff> should be an integer greater than or equal to zero
specifying the cutoff year. See L<"set_year_cutoff"> for details.

=back

    my $loose = DateTime::Format::Mail->new( loose => 1 );

    my $post_2049 = DateTime::Format::Mail->new(
        year_cutoff => 60
    );

=head2 clone

For those who prefer to explicitly clone via a method called C<clone()>.
If called as a class method it will die.

   my $clone = $original->clone();

=head1 PARSING METHODS

These methods work on either our objects or as class methods.

=head2 loose, strict

These methods set the parsing strictness.

    my $parser = DateTime::Format::Mail->new;
    $parser->loose;
    $parser->strict; # (the default)

    my $p = DateTime::Format::Mail->new->loose;

=head2 parse_datetime

Given an RFC2822 or 822 datetime string, return a C<DateTime> object
representing that date and time. Unparseable strings will cause
the method to die.

See the L<synopsis|/SYNOPSIS> for examples.

=head2 set_year_cutoff

Two digit years are treated as valid in the loose translation and are
translated up to a 19xx or 20xx figure. By default, following the
specification of RFC2822, if the year is
greater than '49', it's treated as being in the 20th century (19xx).
If lower, or equal, then the 21st (20xx). That is, 50 becomes
1950 while 49 is 2049.

C<set_year_cutoff()> allows you to modify this behaviour by specifying
a different cutoff.

The return value is the object itself.

    $parser->set_year_cutoff( 60 );

=head2 year_cutoff

Returns the current cutoff. Can be used as either a class or object method.

    my $cutoff = $parser->set_year_cutoff;

=head2 default_cutoff

Returns the default cutoff. A useful method to override for
subclasses.

    my $default = $parser->default_cutoff;

=head2 fix_year

Takes a year and returns it normalized.

   my $fixed = $parser->fix_year( 3 );

=head1 FORMATTING METHODS

=head2 format_datetime

Given a C<DateTime> object, return it as an RFC2822 compliant string.

    use DateTime;
    use DateTime::Format::Mail;
    my $dt = DateTime->new(
        year => 1979, month => 7, day => 16, time_zone => 'UTC'
    );
    my $mail = DateTime::Format::Mail->format_datetime( $dt );
    print $mail, "\n";

    # or via an object
    my $formatter = DateTime::Format::Mail->new();
    my $rfcdate = $formatter->format_datetime( $dt );
    print $rfcdate, "\n";

=head1 THANKS FROM SPOON

Dave Rolsky (DROLSKY) for kickstarting the DateTime project.

Roderick A. Anderson for noting where the documentation was incomplete
in places.

Joshua Hoblitt (JHOBLITT) for inspiring me to check what the
standard said about interpreting two digit years.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<http://datetime.perl.org/mailing_list.html> for more details.

Alternatively, log them via the CPAN RT system via the web or email:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Format-Mail
    bug-datetime-format-mail@rt.cpan.org

This makes it much easier for me to track things and thus means
your problem is less likely to be neglected.

=head1 LICENCE AND COPYRIGHT

Copyright E<copy> Iain Truskett, 2003. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the licences can be found in the F<LICENSE> file
included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=head1 AUTHORS

Originally written by Iain Truskett <spoon@cpan.org>, who died on
December 29, 2003.

Maintained by Dave Rolsky <autarch@urth.org> from 2003 to 2013.

Maintained by Philippe Bruhat (BooK) <book@cpan.org> since 2014.

=head1 SEE ALSO

C<datetime@perl.org> mailing list.

L<http://datetime.perl.org/>

L<perl>, L<DateTime>

RFCs 2822 and 822.

=cut
