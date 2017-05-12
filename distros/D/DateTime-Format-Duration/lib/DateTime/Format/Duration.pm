package DateTime::Format::Duration; # git description: v1.03a-16-g3f2a121
# ABSTRACT: Format and parse DateTime::Durations

use Params::Validate qw( validate SCALAR OBJECT ARRAYREF HASHREF UNDEF );
use Carp;
use DateTime::Duration;


use constant MAX_NANOSECONDS => 1000000000;  # 1E9 = almost 32 bits
use strict;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/strpduration strfduration/;
our %EXPORT_TAGS = (ALL => [qw/strpduration strfduration/]);

our $VERSION = '1.04';

#---------------------------------------------------------------------------
# CONSTRUCTORS
#---------------------------------------------------------------------------

sub new {
    my $class = shift;
    my %args = validate( @_, {
        pattern      => { type => SCALAR, optional => 1 },
        base         => { type => OBJECT | UNDEF, default => undef },
        normalise    => { type => SCALAR, default => 0 },
        normalize    => { type => SCALAR, default => 0 },
    });

    $args{normalise} ||= delete $args{normalize};
    $args{normalise} = 1 if $args{base};

    return bless \%args, $class;
}


#---------------------------------------------------------------------------
# SETTERS AND ACCESSORS
#---------------------------------------------------------------------------

sub pattern { croak("No arguments should be passed to pattern. Use set_pattern() instead.") if $_[1]; $_[0]->{pattern} or undef }
sub set_pattern {
    my $self = shift;
    my $newpattern = shift;
    $self->{parser} = '';
    $self->{pattern} = $newpattern;
    return $self;
}

sub base { croak("No arguments should be passed to base. Use set_base() instead.") if $_[1]; $_[0]->{base} or undef }
sub set_base {
    my $self = shift;
    my $newbase = shift;
    croak("Argument to set_base() must be a DateTime object.") unless ref($newbase) eq 'DateTime';
    $self->{base} = $newbase;
    return $self;
}

sub normalising { croak("No arguments should be passed to normalising. Use set_normalising() instead.") if $_[1]; ($_[0]->{normalise}) ? 1 : 0 }
*normalizing = \&normalising; *normalizing = \&normalising;
sub set_normalising {
    my $self = shift;
    my $new = shift;
    $self->{normalise} = ($new) ? 1 : 0;
    return $self;
}
*set_normalizing = \&set_normalising; *set_normalizing = \&set_normalising;


#---------------------------------------------------------------------------
# DATA
#---------------------------------------------------------------------------


my %formats =
    ( 'C' => sub { int( $_[0]->{years} / 100 ) },
      'd' => sub { sprintf( '%02d', $_[0]->{days} ) },
      'e' => sub { sprintf( '%d', $_[0]->{days} ) },
      'F' => sub { sprintf( '%04d-%02d-%02d', $_[0]->{years}, $_[0]->{months}, $_[0]->{days} ) },
      'H' => sub { sprintf( '%02d', $_[0]->{hours} ) },
      'I' => sub { sprintf( '%02d', $_[0]->{hours} ) },
      'j' => sub { $_[1]->as_days($_[0]) },
      'k' => sub { sprintf( '%2d', $_[0]->{hours} ) },
      'l' => sub { sprintf( '%2d', $_[0]->{hours} ) },
      'm' => sub { sprintf( '%02d', $_[0]->{months} ) },
      'M' => sub { sprintf( '%02d', $_[0]->{minutes} ) },
      'n' => sub { "\n" }, # should this be OS-sensitive?"
      'N' => sub { _format_nanosecs(@_) },
      'p' => sub { ($_[0]->{negative}) ? '-' : '+' },
      'P' => sub { ($_[0]->{negative}) ? '-' : '' },
      'r' => sub { sprintf('%02d:%02d:%02d', $_[0]->{hours}, $_[0]->{minutes}, $_[0]->{seconds} ) },
      'R' => sub { sprintf('%02d:%02d', $_[0]->{hours}, $_[0]->{minutes}) },
      's' => sub { $_[1]->as_seconds($_[0]) },
      'S' => sub { sprintf( '%02d', $_[0]->{seconds} ) },
      't' => sub { "\t" }, #"
      'T' => sub { sprintf('%s%02d:%02d:%02d', ($_[0]->{negative}) ? '-' : '', $_[0]->{hours}, $_[0]->{minutes}, $_[0]->{seconds} ) },
      'u' => sub { $_[1]->as_days($_[0]) % 7 },
      'V' => sub { $_[1]->as_weeks($_[0]) },
      'W' => sub { int(($_[1]->as_seconds($_[0]) / (60*60*24*7))*1_000_000_000) / 1_000_000_000 },
      'y' => sub { sprintf( '%02d', substr( $_[0]->{years}, -2 ) ) },
      'Y' => sub { return $_[0]->{years} },
      '%' => sub { '%' },
    );


#---------------------------------------------------------------------------
# METHODS
#---------------------------------------------------------------------------

sub format_duration {
    my $self = shift;

    my $duration;
    my @formats;

    if ( scalar(@_) == 1 ) {
        $duration = shift;
        @formats = ($self->pattern) if $self->pattern;
    } else {
        my %args = validate( @_, {
            pattern        => { type => SCALAR | ARRAYREF, default => $self->pattern },
            duration    => { type => OBJECT },
        });
        $duration = $args{duration};
        @formats = ref($args{pattern}) ? @{$args{pattern}} : ($args{pattern});
    }

    croak("No formats defined") unless @formats;

    my %duration = ($self->normalising)
        ? $self->normalise( $duration )
        : $duration->deltas;

    return $self->format_duration_from_deltas(
        pattern => [@formats],
        %duration
    );
}


sub format_duration_from_deltas {
    my $self = shift;

    my %args = validate( @_, {
        pattern        => { type => SCALAR | ARRAYREF, default => $self->pattern },
        negative    => { type => SCALAR, default => 0 },
        years        => { type => SCALAR, default => 0 },
        months        => { type => SCALAR, default => 0 },
        days        => { type => SCALAR, default => 0 },
        hours        => { type => SCALAR, default => 0 },
        minutes        => { type => SCALAR, default => 0 },
        seconds        => { type => SCALAR, default => 0 },
        nanoseconds    => { type => SCALAR, default => 0 },
    });

    my @formats = ref($args{pattern}) ? @{$args{pattern}} : ($args{pattern});
    delete $args{pattern};
    my %duration = ($self->normalising)
        ? $self->normalise( %args )
        : %args;

    my @r;
    foreach my $f (@formats)
    {
        # regex from Date::Format - thanks Graham!
        $f =~ s/
        %(\d*)([%a-zA-MO-Z]) # N returns from the left rather than the right
           /
        $formats{$2}
            ? ($1)
                ? sprintf("%0$1d", substr($formats{$2}->(\%duration, $self),$1*-1) )
                : $formats{$2}->(\%duration, $self)
            : $1

           /sgex;

        # %3N
        $f =~ s/
            %(\d*)N
               /
            $formats{N}->(\%duration, $1)
               /sgex;

        return $f unless wantarray;

        push @r, $f;
    }

    return @r;
}


sub parse_duration {
    my $self = shift;
    DateTime::Duration->new(
        $self->parse_duration_as_deltas(@_)
    );
}

sub parse_duration_as_deltas {
    my ( $self, $time_string ) = @_;

    local $^W = undef;

    # Variables from the parser
    my ( $centuries,$years,   $months,
         $weeks,    $days,    $hours,
         $minutes,  $seconds, $nanoseconds
       );

    # Variables for DateTime
    my ( $Years, $Months,  $Days,
         $Hours, $Minutes, $Seconds, $Nanoseconds,
       ) = ();

    # Run the parser
    my $parser = $self->{parser} || $self->_build_parser;
    eval($parser);
    die "Parser ($parser) died:$@" if $@;

    $years += ($centuries * 100);
    $days  += ($weeks     * 7  );

    return (
        years       => $years       || 0,
        months      => $months      || 0,
        days        => $days        || 0,
        hours       => $hours       || 0,
        minutes     => $minutes     || 0,
        seconds     => $seconds     || 0,
        nanoseconds => $nanoseconds || 0,
    );

}


#---------------------------------------------------------------------------
# UTILITY FUNCTIONS
#---------------------------------------------------------------------------

sub normalise {
    my $self = shift;

    return $self->normalise_no_base(@_)
        if (
            ($self->{normalising} and $self->{normalising} =~ /^ISO$/i)
            or not $self->base
        );

    my %delta = (ref($_[0]) =~/^DateTime::Duration/)
        ? $_[0]->deltas
        : @_;

    if (delete $delta{negative}) {
        foreach (keys %delta) { $delta{$_} *= -1 }
    }

    if ($self->{diagnostic}) {require Data::Dumper; print 'Pre Normalise: ' . Data::Dumper::Dumper( \%delta );}

    my $start = $self->base->clone;
    my $end   = $self->base->clone;
    # Can't just add the hash as ->add(%delta) because of mixed positivity:
    foreach (qw/years months days hours minutes seconds nanoseconds/) {
        $end->add( $_ => $delta{$_}||0 );
        print "Adding $delta{$_} $_: " . $end->datetime . "\n" if $self->{diagnostic};
    }


    my %new_delta;
    my $set_negative = 0;
    if ($start > $end) {
        ($start, $end) = ($end, $start);
        $set_negative = 1;
    }

    # Creeping method:
    $new_delta{years} = $end->year - $start->year;
    printf("Adding %d years: %s\n", $new_delta{years}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{months} = $end->month - $start->month;
    printf("Adding %d months: %s\n", $new_delta{months}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{days} = $end->day - $start->day;
    printf("Adding %d days: %s\n", $new_delta{days}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{hours} = $end->hour - $start->hour;
    printf("Adding %d hours: %s\n", $new_delta{hours}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{minutes} = $end->minute - $start->minute;
    printf("Adding %d minutes: %s\n", $new_delta{minutes}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{seconds} = $end->second - $start->second;
    printf("Adding %d seconds: %s\n", $new_delta{seconds}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    $new_delta{nanoseconds} = $end->nanosecond - $start->nanosecond;
    printf("Adding %d nanoseconds: %s\n", $new_delta{nanoseconds}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};

    if( $new_delta{nanoseconds} < 0 ){
        $new_delta{nanoseconds} += MAX_NANOSECONDS;
        $new_delta{seconds}--;
        printf("Oops: Adding %d nanoseconds, %d seconds: %s\n", $new_delta{nanoseconds}, $new_delta{seconds}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    if( $new_delta{seconds} < 0 ){
        $new_delta{seconds} += $end->clone->truncate( to => 'minute' )->subtract( seconds => 1 )->second + 1;
        $new_delta{minutes}--;
        printf("Oops: Adding %d seconds, %d minutes: %s\n", $new_delta{seconds}, $new_delta{minutes}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    if( $new_delta{minutes} < 0 ){
        $new_delta{minutes} += 60;
        $new_delta{hours}--;
        printf("Oops: Adding %d minutes, %d hours: %s\n", $new_delta{minutes}, $new_delta{hours}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    if( $new_delta{hours} < 0 ){
        $new_delta{hours} += _hours_in_day($end->clone->truncate( to => 'day' )->subtract( seconds => 5 ));
        $new_delta{days}--;
        printf("Oops: Adding %d hours, %d days: %s\n", $new_delta{hours}, $new_delta{days}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    if( $new_delta{days} < 0 ){
# Thought this was correct .. I was wrong, but I want to leave it here anyway
#        $new_delta{days} += $end->clone->truncate( to => 'month' )->subtract( seconds => 5 )->day;
        $new_delta{days} += $start->clone->truncate( to => 'month' )->add(months => 1)->subtract( seconds => 5 )->day;
        $new_delta{months}--;
        printf("Oops: Adding %d days, %d months: %s\n", $new_delta{days}, $new_delta{months}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    if( $new_delta{months} < 0 ){
        $new_delta{months} += 12;
        $new_delta{years}--;
        printf("Oops: Adding %d months, %d years: %s\n", $new_delta{months}, $new_delta{years}, $start->clone->add( %new_delta )->datetime) if $self->{diagnostic};
    }

    $new_delta{negative} = $set_negative;

    if ($self->{diagnostic}) {require Data::Dumper; print 'Post Normalisation: ' . Data::Dumper::Dumper( \%new_delta );}

    return %new_delta
}
*normalize = \&normalise;
*normalize = \&normalise;

sub normalise_no_base {
    my $self = shift;
    my %delta = (ref($_[0]) =~/^DateTime::Duration/) ? $_[0]->deltas : @_;

    if (delete $delta{negative}) {
        foreach (keys %delta) { $delta{$_} *= -1 }
    }
    foreach(qw/years months days hours minutes seconds nanoseconds/) {
        $delta{$_} ||= 0;
    }

    if ($self->{diagnostic}) {
        require Data::Dumper;
        print 'Pre Baseless Normalise: ' . Data::Dumper::Dumper( \%delta );
    }

    # Remove any decimals:
    $delta{nanoseconds} += (MAX_NANOSECONDS * ($delta{seconds} - int($delta{seconds})));
    $delta{seconds} = int($delta{seconds});
    $delta{seconds} += (60 * ($delta{minutes} - int($delta{minutes})));
    $delta{minutes} = int($delta{minutes});
    $delta{minutes} += (60 * ($delta{hours} - int($delta{hours})));
    $delta{hours} = int($delta{hours});
    $delta{hours} += (24 * ($delta{days} - int($delta{days})));
    $delta{days} = int($delta{days});
    $delta{days} += (30 * ($delta{months} - int($delta{months})));
    $delta{months} = int($delta{months});

    ($delta{nanoseconds}, $delta{seconds})  = _set_max($delta{nanoseconds}, MAX_NANOSECONDS, $delta{seconds});
    ($delta{seconds},     $delta{minutes})  = _set_max($delta{seconds},     60,          $delta{minutes});
    ($delta{minutes},     $delta{hours})    = _set_max($delta{minutes},     60,          $delta{hours}  );
    ($delta{hours},       $delta{days})     = _set_max($delta{hours},       24,          $delta{days}   );
    ($delta{days},    $delta{months})   = _set_max($delta{days},    30,          $delta{months} )
        if $self->{normalise} =~ /^iso$/i;
    ($delta{months},      $delta{years})    = _set_max($delta{months},      12,          $delta{years}  );

    if ($self->{diagnostic}) {
        require Data::Dumper;
        print 'Post Baseless Normalise: ' . Data::Dumper::Dumper( \%delta );
    }

    %delta = _denegate( %delta );

    if ($self->{diagnostic}) {
        require Data::Dumper;
        print 'Post Denegation: ' . Data::Dumper::Dumper( \%delta );
    }

    return %delta;
}
*normalize_no_base = \&normalise_no_base;
*normalize_no_base = \&normalise_no_base;

sub as_weeks {
    my $self = shift;
    return int($self->as_seconds($_[0]) / (7*24*60*60));
}

sub as_days {
    my $self = shift;
    return int($self->as_seconds($_[0]) / (24*60*60));
}

sub as_seconds {
    my $self = shift;

    my %delta = (ref($_[0])) ? %{$_[0]} : @_;
    if (delete $delta{negative}) {foreach( keys %delta ) { $delta{$_} *= -1 }};

    unless ($self->base) {
        my $seconds = $delta{nanoseconds} / MAX_NANOSECONDS;
        $seconds += $delta{seconds};
        $seconds += $delta{minutes} * 60;
        $seconds += $delta{hours}   * (60*60);
        $seconds += $delta{days}    * (24*60*60);
        $seconds += $delta{months}  * (30*24*60*60);
        $seconds += $delta{years}   * (12*30*24*60*60);
        return $seconds;
    }

    my $dt1 = $self->base + DateTime::Duration->new( %delta );
    return int(($dt1->{utc_rd_days} - $self->base->{utc_rd_days}) * (24*60*60))
            + ($dt1->{utc_rd_secs} - $self->base->{utc_rd_secs});
}


sub debug_level{
    my $self = shift;
    my $level = shift;
    if ($level > 0) {
        Params::Validate::validation_options(
            on_fail => \&Carp::confess,
        );
    } else {
        Params::Validate::validation_options(
            on_fail => undef,
        );
    }
    $self->{diagnostic} = ($level) ? $level-1 : 0;
}



#---------------------------------------------------------------------------
# EXPORTABLE FUNCTIONS
#---------------------------------------------------------------------------

sub strfduration { #format
    my %args = validate( @_, {
        pattern        => { type => SCALAR | ARRAYREF },
        duration    => { type => OBJECT },
        normalise    => { type => SCALAR, optional => 1 },
        base        => { type => OBJECT, optional => 1 },
        debug        => { type => SCALAR, default => 0 },
    });
    my $new = DateTime::Format::Duration->new(
        pattern => $args{pattern},
        base    => $args{base},
        normalise=> $args{normalise},
    );
    $new->debug_level( $args{debug } );
    return $new->format_duration( $args{duration} );
}

sub strpduration { #parse
    my %args = validate( @_, {
        pattern        => { type => SCALAR | ARRAYREF },
        duration    => { type => SCALAR },
        base        => { type => OBJECT, optional => 1 },
        as_deltas    => { type => SCALAR, default => 0 },
        debug        => { type => SCALAR, default => 0 },
    });
    my $new = DateTime::Format::Duration->new(
        pattern => $args{pattern},
        base    => $args{base},
    );
    $new->debug_level( $args{debug} );
    return $new->parse_duration( $args{duration} ) unless $args{as_deltas};

    return $new->parse_duration_as_deltas( $args{duration} );
}



#---------------------------------------------------------------------------
# INTERNAL FUNCTIONS
#---------------------------------------------------------------------------

sub _format_nanosecs {
    my %deltas = %{+shift};
    my $precision = shift;

    my $ret = sprintf( "%09d", $deltas{nanoseconds} );
    return $ret unless $precision;   # default = 9 digits

    my ( $int, $frac ) = split(/[.,]/, $deltas{nanoseconds});
    $ret .= $frac if $frac;

    return substr( $ret, 0, $precision );
}

sub _build_parser {
    my $self = shift;
    my $regex = my $field_list = shift || $self->pattern;
    my @fields = $field_list =~ m/(%\{\w+\}|%\d*.)/g;
    $field_list = join('',@fields);

    my $tempdur = DateTime::Duration->new( seconds => 0 ); # Created just so we can do $tempdt->can(..)

    # I'm absoutely certain there's a better way to do this:
    $regex=~s|([\/\.\-])|\\$1|g;

    $regex =~ s/%[Tr]/%H:%M:%S/g;
    $field_list =~ s/%[Tr]/%H%M%S/g;
    # %T is the time as %H:%M:%S.

    $regex =~ s/%R/%H:%M/g;
    $field_list =~ s/%R/%H%M/g;
    #is the time as %H:%M.

    $regex =~ s|%F|%Y\\-%m\\-%d|g;
    $field_list =~ s|%F|%Y%m%d|g;
    #is the same as %Y-%m-%d

    # Negative and Positive
    $regex =~ s/%P/[+-]?/g;
    $field_list =~ s/%P//g;#negative#/g;


    # Numerated places:

    # Centuries:
    $regex =~ s/%(\d*)[C]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[C]/#centuries#/g;

    # Years:
    $regex =~ s/%(\d*)[Yy]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[Yy]/#years#/g;

    # Months:
    $regex =~ s/%(\d*)[m]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[m]/#months#/g;

    # Weeks:
    $regex =~ s/%(\d*)[GV]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[GV]/#weeks#/g;
    $regex =~ s/%\d*[W]/" *([+-]?\\d+\\.?\\d*)"/eg;
    $field_list =~ s/%\d*[W]/#weeks#/g;

    # Days:
    $regex =~ s/%(\d*)[deju]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[deju]/#days#/g;

    # Hours:
    $regex =~ s/%(\d*)[HIkl]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[HIkl]/#hours#/g;

    # Minutes:
    $regex =~ s/%(\d*)[M]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[M]/#minutes#/g;

    # Seconds:
    $regex =~ s/%(\d*)[sS]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[sS]/#seconds#/g;

    # Nanoseconds:
    $regex =~ s/%(\d*)[N]/($1) ? " *([+-]?\\d{$1})" : " *([+-]?\\d+)"/eg;
    $field_list =~ s/%(\d*)[N]/#nanoseconds#/g;


    # Any function in DateTime.
    $regex =~ s|%\{(\w+)}|($tempdur->can($1)) ? "(.+)" : ".+"|eg;
    $field_list =~ s|(%\{(\w+)})|($tempdur->can($2)) ? "#$2#" : $1 |eg;

    # White space:
    $regex =~ s/%(\d*)[tn]/($1) ? "\\s{$1}" : "\\s+"/eg;
    $field_list =~ s/%(\d*)[tn]//g;

    # is replaced by %.
    $regex =~ s/%%/%/g;
    $field_list =~ s/%%//g;

    $field_list=~s/#([a-z0-9_]+)#/\$$1, /gi;
    $field_list=~s/,\s*$//;

    croak("Unknown symbols in parse: $1") if $field_list=~/(\%\w)/g;

    $self->{parser} = qq|($field_list) = \$time_string =~ /$regex/|;
}

sub _set_max {
    #$$_[0] should roll over to the next $$_[2] when it reaches $_[1]
    #seconds should roll over to the next minute when it reaches 60.
    my ($small, $max, $large) = @_;
    #warn "$small should roll over to the next $large when it reaches $max\n";
    $large += int($small / $max);
    $small = ($small < 0)
        ? $small %  -$max
        : $small % $max;
    return ($small, $large);
}

sub _denegate {
    my %delta = @_;
    my ($negatives, $positives);
    foreach(qw/years months days hours minutes seconds nanoseconds/) {
        if ($delta{$_} < 0) {
            $negatives++;
        } elsif ($delta{$_} > 0) {
            $positives++;
        } # ignore == 0
    }
    if ($negatives and not $positives) {
        foreach(qw/years months days hours minutes seconds nanoseconds/) {
            if ($delta{$_} < 0) {
                $delta{$_} *= -1
            }
            $delta{$_} ||= 0;
        }
        $delta{negative} = 1;
    } elsif ($negatives and $positives) {
        # Work to match largest component
        my $make = '';
        foreach(qw/years months days hours minutes seconds nanoseconds/) {
            if ($delta{$_} < 0) {
                $make = 'negative';
                last;
            } elsif ($delta{$_} > 0) {
                $make = 'positive';
                last;
            }
        }
        if ($make) {
            ($delta{seconds}, $delta{minutes}) = _make($make,$delta{seconds}, 60, $delta{minutes});
            ($delta{minutes}, $delta{hours})   = _make($make,$delta{minutes}, 60, $delta{hours}  );
            ($delta{hours},   $delta{days})    = _make($make,$delta{hours},   24, $delta{days}   );
            ($delta{months},  $delta{years})   = _make($make,$delta{months},  12, $delta{years}  );
            %delta = _denegate(%delta);
        }
    }
    return %delta
}

sub _make {
    my ($make, $small, $max, $large) = @_;
    while ($small < 0 and $make eq 'positive') {
        $small += $max;
        $large -= 1;
    }
    while ($small > 0 and $make eq 'negative') {
        $small -= $max;
        $large += 1;
    }
    return ($small, $large);
}

sub _hours_in_day{
    my $day = shift;

    return (
        $day->clone->truncate( to => 'day' )->add( days => 1 )->epoch
        -
        $day->clone->truncate( to => 'day' )->epoch
    ) / (60 * 60)

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Duration - Format and parse DateTime::Durations

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    use DateTime::Format::Duration;

    $d = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days, '.
                '%H hours, %M minutes, %S seconds'
    );

    print $d->format_duration(
        DateTime::Duration->new(
            years   => 3,
            months  => 5,
            days    => 1,
            hours   => 6,
            minutes => 15,
            seconds => 45,
            nanoseconds => 12000
        )
    );
    # 3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds


    $duration = $d->parse_duration(
        '3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds'
    );
    # Returns DateTime::Duration object


    print $d->format_duration_from_deltas(
        years   => 3,
        months  => 5,
        days    => 1,
        hours   => 6,
        minutes => 15,
        seconds => 45,
        nanoseconds => 12000
    );
    # 3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds

    %deltas = $d->parse_duration_as_deltas(
          '3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds'
    );
    # Returns hash:
    # (years=>3, months=>5, days=>1, hours=>6, minutes=>15, seconds=>45)

=head1 ABSTRACT

This module formats and parses L<DateTime::Duration> objects
as well as other durations representations.

=head1 CONSTRUCTOR

This module contains a single constructor:

=over 4

=item * C<new( ... )>

The C<new> constructor takes the following attributes:

=over 4

=item * C<< pattern => $string >>

This is a strf type pattern detailing the format of the duration.
See the L</Patterns> sections below for more information.

=item * C<< normalise => $one_or_zero_or_ISO >>

=item * C<< normalize => $one_or_zero_or_ISO >>

This determines whether durations are 'normalised'. For example, does
120 seconds become 2 minutes?

Setting this value to true without also setting a C<base> means we will
normalise without a base. See the L</Normalising without a base> section
below.

=item * C<< base => $datetime_object >>

If a base DateTime is given then that is the normalisation date. Setting
this attribute overrides the above option and sets normalise to true.

=back

=back

=head1 METHODS

L<DateTime::Format::Duration> has the following methods:

=over 4

=item * C<format_duration( $datetime_duration_object )>

=item * C<< format_duration( duration => $dt_duration, pattern => $pattern ) >>

Returns a string representing a L<DateTime::Duration> object in the format set
by the pattern. If the first form is used, the pattern is taken from the
object. If the object has no pattern then this method will croak.

=item * C<format_duration_from_deltas( %deltas )>

=item * C<< format_duration_from_deltas( %deltas, pattern => $pattern ) >>

As above, this method returns a string representing a duration in the format
set by the pattern. However this method takes a hash of values. Permissible
hash keys are C<years, months, days, hours, minutes, seconds> and C<nanoseconds>
as well as C<negative> which, if true, inverses the duration. (C<< years => -1 >> is
the same as C<< years => 1, negative=>1 >>)

=item * C<parse_duration( $string )>

This method takes a string and returns a L<DateTime::Duration> object that is the
equivalent according to the pattern.

=item * C<parse_duration_as_deltas( $string )>

Once again, this method is the same as above, however it returns a hash rather
than an object.

=item * C<normalise( $duration_object )>

=item * C<normalize( %deltas )>

Returns a hash of deltas after normalising the input. See the L</NORMALISE>
section below for more information.

=back

=head1 ACCESSORS

=over 4

=item * C<pattern()>

Returns the current pattern.

=item * C<base()>

Returns the current base.

=item * C<normalising()>

Indicates whether or not the durations are being normalised.

=back

=head1 SETTERS

All setters return the object so that they can be strung together.

=over 4

=item * C<set_pattern( $new_pattern )>

Sets the pattern and returns the object.

=item * C<set_base( $new_DateTime )>

Sets the base L<DateTime> and returns the object.

=item * C<set_normalising( $true_or_false_or_ISO )>

Turns normalising on or off and returns the object.

=back

=head1 NOTES

=head2 Patterns

This module uses a similar set of patterns to L<strftime|strftime(3)>. These patterns
have been kept as close as possible to the original time-based patterns.

=over 4

=item * %C

The number of hundreds of years in the duration. 400 years would return 4.
This is similar to centuries.

=item * %d

The number of days zero-padded to two digits. 2 days returns 02. 22 days
returns 22 and 220 days returns 220.

=item * %e

The number of days.

=item * %F

Equivalent of %Y-%m-%d

=item * %H

The number of hours zero-padded to two digits.

=item * %I

Same as %H

=item * %j

The duration expressed in whole days. 36 hours returns 1

=item * %k

The hours without any padding

=item * %l

Same as %k

=item * %m

The months, zero-padded to two digits

=item * %M

The minutes, zero-padded to two digits

=item * %n

A linebreak when formatting and any whitespace when parsing

=item * %N

Nanoseconds - see note on precision at end

=item * %p

Either a '+' or a '-' indicating the positiveness of the duration

=item * %P

A '-' for negative durations and nothing for positive durations.

=item * %r

Equivalent of %H:%M:%S

=item * %R

Equivalent of %H:%M

=item * %s

Returns the value as seconds. 1 day, 5 seconds return 86405

=item * %S

Returns the seconds, zero-padded to two digits

=item * %t

A tab character when formatting or any whitespace when parsing

=item * %T

Equivalent of %P%H:%M:%S

=item * %u

Days after weeks are removed. 4 days returns 4, but 22 days returns 1
(22 days is three weeks, 1 day)

=item * %V

Duration expressed as weeks. 355 days returns 52.

=item * %W

Duration expressed as floating weeks. 10 days, 12 hours returns 1.5 weeks.

=item * %y

Years in the century. 145 years returns 45.

=item * %Y

Years, zero-padded to four digits

=item * %%

A '%' symbol

=back

B<Precision> can be changed for any and all the above values. For all but
nanoseconds (%N), the precision is the zero-padding. To change the precision
insert a number between the '%' and the letter. For example: 1 year formatted
with %6Y would return 000001 rather than the default 0001. Likewise, to remove
padding %1Y would just return a 1.

Nanosecond precision is the other way (nanoseconds are fractional and thus
should be right padded). 123456789 nanoseconds formatted with %3N would return
123 and formatted as %12N would return 123456789000.

=head2 Normalisation

This module contains a complex method for normalising durations. The method
ensures that the values for all components are as close to zero as possible.
Rather than returning 68 minutes, it is normalised to 1 hour, 8 minutes.

The complexity comes from three places:

=over 4

=item * Mixed positive and negative components

The duration of 1 day, minus 2 hours is easy to normalise in your head to
22 hours. However consider something more complex such as -2 years, +1 month,
+22 days, +11 hours, -9 minutes.

This module works from lowest to highest precision to calculate the duration.
So, based on a C<base> of 2004-03-28T00:00:00 the following transformations take
place:

    2003-01-01T00:00:00 - 2 years   = 2001-01-01T00:00:00 === -2 years
    2001-01-01T00:00:00 + 1 month   = 2001-02-01T00:00:00 === -1 year, 11 months
    2001-02-01T00:00:00 + 22 days   = 2001-02-23T00:00:00 === -1yr, 10mths, 6days
    2001-02-22T00:00:00 + 11 hours  = 2001-02-23T11:00:00 === -1y, 10m, 6d, 13h
    2001-02-22T11:00:00 - 9 minutes = 2001-02-23T10:51:00 === -1y, 10m, 6d, 13h, 9m

=for comment TODO: replace via Pod::Weaver with the base64'd inline image; see Pod::Weaver::Section::Ditaa

=for html <img src="https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure1.gif">

=for man See: https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure1.gif

Figure 1 illustrates that, with the given base, -2 years, +1 month,
+22 days, +11 hours, -9 minutes is normalised to -1 year, 10 months, 6 days,
13 hours and 9 minutes.

=item * Months of unequal length.

Unfortunately months can have 28, 29, 30 or 31 days and it can change from year
to year. Thus if I wanted to normalise 2 months it could be any of 59 (Feb-Mar),
60 (Feb-Mar in a leap year), 61 (Mar-Apr, Apr-May, May-Jun, Jun-Jul, Aug-Sep,
Sep-Oct, Oct-Nov or Nov-Dec) or 62 days (Dec-Jan or Jul-Aug). Because of this
the module uses a base datetime for its calculations. If we use the base
2003-01-01T00:00:00 then two months would be 59 days (2003-03-01 - 2003-01-01)

=item * The order of components

Components will always be assessed from lowest to highest precision (years, months,
days, hours, minutes, seconds, nanoseconds). This can really change things.

Consider the duration of 1 day, 24 hours. Normally this will normalise to 2 days.
However, consider changes to Daylight Savings. On the changes to and from DST
days have 25 and 23 hours.

If we take the base DateTime as midnight on the day DST ends (when there's 25
hours in the day), and add 1 day, 24 hours we end up at midnight 2 days later.
So our duration normalises to two days.

However, if we add 24 hours, 1 day we end up at 11pm on the next day! Why is this?
Because midnight + 24 hours = 11pm (there's 25 hours on this day!), then we add 1
day and end up at 11pm on the following day.

=for html <img src="https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure2.gif">

=for man See: https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure2.gif

Figure 2 illustrates the above problem on timelines.

=item * Leap years and leap seconds

Leap years and seconds further add to the confusion in normalisation. Leap
seconds mean there are minutes that are 61 seconds long, thus 130 seconds can
be 2 minutes, 10 seconds or 2 minutes 9 seconds, depending on the base DateTime.
Similarly leap years mean a day can have 23, 24 or 25 hours.

=for html <img src="https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure3.gif">

=for man See: https://raw.githubusercontent.com/karenetheridge/DateTime-Format-Duration/master/docs/figure3.gif

Figure 3 shows how leaps are calculated on timelines.

=back

=head2 Normalising without a base

This module includes two ways to normalise without a base.

=over 4

=item * Standard Normalisation

Using standard normalisation without a base, 45 days will stay as 45 days as there
is no way to accurately convert to months. However the following assumptions will
be made: There are 24 hours in a day and there are 60 seconds in a minute.

=item * ISO Normalisation

In ISO8601v2000, Section 5.5.3.2 says that "The values used must not exceed the
'carry-over points' of 12 months, 30 days, 24 hours, 60 minutes and 60 seconds".
Thus if you set the normalise option of the constructor, or use set_normalising
to 'ISO', months will be normalised to 30 days.

=back

=head2 Deltas vs Duration Objects

This module can bypass duration objects and just work with delta hashes.
This used to be of greatest value with earlier versions of DateTime::Duration
when DateTime::Duration assumed a duration with one negative component was a
negative duration (that is, -2 hours, 34 minutes was assumed to be -2 hours,
-34 minutes).

These extra methods have been left in here firstly for backwards-compatibility
but also as an added 'syntactic sugar'. Consider these two equivalent
expressions:

    $one = $o->format_duration(
        DateTime::Duration->new(
            years => -2,
            days  => 13,
            hours => -1
        )
    );

    $two = $o->format_duration_from_deltas(
        years => -2,
        days  => 13,
        hours => -1
    );

These both create the same string in $one and $two, but if you don't already
have a DateTime::Duration object, the later looks cleaner.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Duration>
(or L<bug-DateTime-Format-Duration@rt.cpan.org|mailto:bug-DateTime-Format-Duration@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/datetime.html>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Rick Measham <rickm@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2003 by Rick Measham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
