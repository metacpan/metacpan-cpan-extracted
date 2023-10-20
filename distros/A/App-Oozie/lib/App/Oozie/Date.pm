package App::Oozie::Date;
$App::Oozie::Date::VERSION = '0.010';
use 5.014;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    DATE_PATTERN
    SHORTCUT_METHODS
);
use Carp qw( croak );
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;
use Moo;
use Types::Standard qw( Str );

has strp => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        DateTime::Format::Strptime->new(
                pattern   => DATE_PATTERN,
                time_zone => $self->timezone,
                on_error  => 'croak',
            );
    },
    lazy => 1,
);

has strp_silent => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        DateTime::Format::Strptime->new(
                pattern   => DATE_PATTERN,
                time_zone => $self->timezone,
            );
    },
    lazy => 1,
);

has timezone => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

sub today {
    my $self  = shift;
    return $self->_stringify_dt( DateTime->today );
}

sub tomorrow {
    my $self  = shift;
    my $today = DateTime->today;
    $today->add( days => 1 );
    return $self->_stringify_dt( $today );
}

sub yesterday {
    my $self  = shift;
    my $today = DateTime->today;
    $today->subtract( days => 1 );
    return $self->_stringify_dt( $today );
}

sub diff {
    my $self   = shift;
    my $date_1 = shift || croak "First date is missing";
    my $date_2 = shift || croak "Second date is missing";

    my $dt1 = $self->strp->parse_datetime( $date_1 );
    my $dt2 = $self->strp->parse_datetime( $date_2 );
    my $dur = $dt1->subtract_datetime( $dt2 );

    my $days = DateTime::Format::Duration
                ->new( pattern => '%j')
                ->format_duration( $dur );
    return $days;
}

sub is_valid {
    my $self = shift;
    my $date = shift || croak "Date is missing";
    my $rv = $self->strp_silent->parse_datetime( $date );
    if ( ! $rv ) {
        warn sprintf "The date value `%s` is invalid: %s",
                        $date,
                        $self->strp->errmsg;
    }
    return $rv;
}

sub move {
    my $self = shift;
    my $date = shift || croak "No date parameter was specified";
    my $by   = shift || croak "No days to shift by were specified";

    my $dt = $self->strp->parse_datetime( $date );
    $dt->add( days => $by );

    return $self->_stringify_dt( $dt );
}

sub _stringify_dt {
    my $self = shift;
    my $dt   = shift;
    return sprintf '%d-%02d-%02d',
                    map { $dt->$_ }
                    qw( year month day );
}

sub intersection {
    state $usage = sub {
        my $missing = shift;
        my $msg = "Usage: intersection(first_start, first_end, second_start, second_end)";
        $msg .= ". You didn't specify `$missing`" if $missing;
        croak $msg;
    };

    my $self          = shift;
    my $x_start       = shift || $usage->('first_start');
    my $x_end         = shift || $usage->('first_end');
    my $y_start       = shift || $usage->('second_start');
    my $y_end         = shift || $usage->('second_end');
    my $strp          = $self->strp;
    my $x_start_epoch = $strp->parse_datetime( $x_start )->epoch;
    my $x_end_epoch   = $strp->parse_datetime( $x_end   )->epoch;
    my $y_start_epoch = $strp->parse_datetime( $y_start )->epoch;
    my $y_end_epoch   = $strp->parse_datetime( $y_end   )->epoch;

    return if  $x_start_epoch > $x_end_epoch
            || $y_start_epoch > $y_end_epoch
            || $y_start_epoch > $x_end_epoch
            || $x_start_epoch > $y_end_epoch
    ;

    my $start = 0 < ($x_start_epoch <=> $y_start_epoch) ? $x_start_epoch : $y_start_epoch;
    my $end   = 0 > ($x_end_epoch   <=> $y_end_epoch  ) ? $x_end_epoch   : $y_end_epoch;

    return {
        start => $self->_stringify_dt( DateTime->from_epoch( epoch => $start ) ),
        end   => $self->_stringify_dt( DateTime->from_epoch( epoch => $end   ) ),
    };
}

sub epoch_yyyy_mm_dd_hh_mm_ss {
    my $self  = shift;
    my $epoch = shift || Carp::confess "Epoch not specified!";
    my $strp  = DateTime::Format::Strptime->new(
                    pattern   => '%Y-%m-%d %H:%M:%S %Z',
                    time_zone => $self->timezone,
                    on_error  => 'croak',
                );
    return $strp->format_datetime(
                DateTime->from_epoch(
                    epoch     => $epoch,
                    time_zone => $self->timezone,
                )
            );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Date

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use App::Oozie::Date;
    my $d = App::Oozie::Date->new;

=head1 DESCRIPTION

Date related functions.

=head1 NAME

App::Oozie::Date - Date related functions.

=head1 Methods

=head2 diff

=head2 epoch_yyyy_mm_dd_hh_mm_ss

=head2 intersection

=head2 is_valid

=head2 move

=head2 today

=head2 tomorrow

=head2 yesterday

=head1 Accessors

=head2 Overridable from sub-classes

=head3 strp

=head3 strp_silent

=head3 timezone

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
