package DateTime::Format::Duration::DurationString;

use Moo;
use Carp;
use DateTime::Duration;
use MooX::Types::MooseLike::Numeric 'PositiveOrZeroInt';

=head1 NAME

DateTime::Format::Duration::DurationString - JIRA style parsing of duration

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  package MyApp;
  use DateTime::Format::Duration::DurationString;
  
  my $seconds  = DateTime::Format::Duration::DurationString->new()->parse('1d 3h')->to_seconds;
  my $duration = DateTime::Format::Duration::DurationString->new()->parse('1d 3h')->to_duration;


=head1 DESCRIPTION

C<DateTime::Format::Duration::DurationString> parses a string and returns a duration.

=cut

# Constants:

use constant SECOND => 1;
use constant MINUTE => 60 * SECOND;
use constant HOUR   => 60 * MINUTE;
use constant DAY    => 24 * HOUR;
use constant WEEK   => 7 * DAY;
# use constant MONTH  => 31 * DAY;
# use constant YEAR   => 365 * DAY;

has 'seconds' => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
has 'minutes' => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
has 'hours'   => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
has 'days'    => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
has 'weeks'   => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
# has 'months'  => (is => 'rw', isa => PositiveOrZeroInt, default => 0);
# has 'years'   => (is => 'rw', isa => PositiveOrZeroInt, default => 0);

=head2 to_seconds

Return this object as seconds

=cut

sub to_seconds {
    my $self = shift;
    
    return ($self->seconds * SECOND)
         + ($self->minutes * MINUTE)
         + ($self->hours   * HOUR)
         + ($self->days    * DAY)
         + ($self->weeks   * WEEK);
#         + ($self->months  * MONTH)
#         + ($self->years   * YEAR);
    
}

=head2 to_duration

Return this object as a DateTime::Duration

=cut

sub to_duration {
    my $self = shift;
    
    return DateTime::Duration->new( weeks   => $self->weeks,
                                    days    => $self->days,
                                    hours   => $self->hours,
                                    minutes => $self->minutes,
                                    seconds => $self->seconds,
                                  );
}

=head2 parse

Parse a string

=cut

sub parse {
    my $self = shift;
    my ($str) = @_;
    
    foreach my $token (split(/\s+/,$str)) {
        $self->_parse_token($token);
    }
    
    return $self;
}

sub _parse_token {
    my $self = shift;
    my ($token) = @_;
    
    if ($token =~ /^(\d+)(\D?)$/) {
        my $num = $1;
        my $typ = $2;
        
        if ($typ eq 's') {
            $self->seconds($self->seconds + $num);
        }
        elsif (($typ eq 'm')) {
            $self->minutes($self->minutes + $num);
        } 
        elsif (($typ eq 'h')||($typ eq '')) {
            $self->hours($self->hours + $num);
        } 
        elsif ($typ eq 'd'){
            $self->days($self->days + $num);
        }
        elsif ($typ eq 'w'){
            $self->weeks($self->weeks + $num);
        }
        else {
            croak "$token has unknown type $typ";
        }
    } 
    else {
        croak "$token not wellformed. <duration><wdhms>";
    }
    return $self;
}

1; # Return something nice to the caller

=head1 TODO

Parsestring in constructor?

=head1 SEE ALSO

L<DateTime>, L<DateTime::Duration> and L<DateTime::Format::Duration>

=head1 AUTHOR

Bjorn-Olav Strand E<lt>bo@startsiden.noE<gt>

=head1 LICENSE

Copyright 2009 by ABC Startsiden AS, BjE<oslash>rn-Olav Strand <bo@startsiden.no>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

