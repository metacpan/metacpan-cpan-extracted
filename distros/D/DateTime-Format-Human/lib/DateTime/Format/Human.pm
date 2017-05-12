# Copyright (C) 2004  Joshua Hoblitt
# Copyright (C) 2001  Simon Cozens
#
# $Id: Human.pm,v 1.1.1.1 2004/10/17 00:44:32 jhoblitt Exp $

package DateTime::Format::Human;

use strict;

use vars qw( $VERSION );
$VERSION = '0.01';

use DateTime;
use Params::Validate qw( validate validate_pos SCALAR OBJECT );

my %templates = (

    English => {
        numbers  => [ qw(one two three four five six seven eight nine ten eleven twelve) ],
        vagueness=> [ "exactly", "just after", "a little after", "coming up to", "almost" ],
        daytime  => [ "in the morning", "in the afternoon", "in the evening", "at night" ],
        minutes  => [ "five past", "ten past", "quarter past", "twenty past",
                    "twenty-five past", "half past", "twenty-five to",
                    "twenty to", "quarter to", "ten to", "five to" ],
        oclock   => "o'clock",
        midnight => "midnight",
        midday   => "midday",
        format   => "%v %m %h %d",
    }
);

my $language = "English";
my $evening = 18;
my $night = 22;

sub new {
    my $class = shift;

    my %args = validate( @_,
        {
            evening => {
                type        => SCALAR,
                callbacks   => {
                    'is >= 0 <= 23' => sub { $_[0] >= 0 && $_[0] <= 23 },
                    'is integer'    => sub { $_[0] =~ /^\d+$/ },
                },
                default => $evening,
            },
            night   => {
                type        => SCALAR,
                callbacks   => {
                    'is >= 0 <= 23' => sub { $_[0] >= 0 && $_[0] <= 23 },
                    'is integer'    => sub { $_[0] =~ /^\d+$/ },
                },
                default => $night,
            },

        }, 
    );

    my $self = {
        language    => $language,
        evening     => $args{ 'evening' },
        night       => $args{ 'night' },
    };

    bless $self, ref $class || $class;

    return $self;
}

sub format_datetime {
    my $self = shift;

    my @args = validate_pos( @_,
        {
            type    => OBJECT,
            can     => 'utc_rd_values',
        }
    );

    my $dt = DateTime->from_object( object => $args[0] );
    $dt->set_time_zone( 'local' );

    my $hour = $dt->hour;
    my $minute = $dt->minute;

    my $vague = $minute % 5;
    my $close_minute = $minute-$vague;
    my $t = $templates{ $self->{ 'language' } };
    my $say_hour;
    my $daytime ="";
    if ($vague > 2) {$close_minute += 5} 
    if ($close_minute >30) { $hour++; $hour %=24; }
    $close_minute /= 5;
    $close_minute %= 12;
    if ($hour ==0) {
        $say_hour = $t->{midnight};
    } elsif ($hour == 12) {
        $say_hour = $t->{midday};
    } else {
        $say_hour = $t->{numbers}[$hour%12-1];
        $daytime = $hour <= 12 ? ($t->{daytime}[0]) :
                    $hour >= $self->{ 'night' } ? $t->{daytime}[3] :
                    ($hour >= $self->{ 'evening' } ? $t->{daytime}[2] :
                    $t->{daytime}[1]); # Afternoon
    }
    if ($close_minute==0) {
        $say_hour .= " ". $t->{oclock} unless $hour ==0 or $hour == 12;
    }
    my $say_min = $close_minute ==0? "" : $t->{minutes}[$close_minute-1];
    my $rv = $t->{format};

    $rv =~ s/%v/$t->{vagueness}[$vague]/eg;
    # remove the extra space caused by an empty $say_mih
    $rv =~ s/ %m|%m//g unless $say_min;
    $rv =~ s/%m/$say_min/g;
    $rv =~ s/%h/$say_hour/g;
    # remove the extra space caused by an empty $daytime
    $rv =~ s/ %d|%d//g unless $daytime;
    $rv =~ s/%d/$daytime/g;
    return $rv;
}

1;

__END__
