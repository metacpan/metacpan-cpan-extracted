#
# Courier::Filter::Module::FakeDate class
#
# (C) 2006-2008 Julian Mehnle <julian@mehnle.net>
# $Id: FakeDate.pm 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::FakeDate - Fake "Date:" message header filter module
for the Courier::Filter framework

=cut

package Courier::Filter::Module::FakeDate;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use Error ':try';

use DateTime::Duration;
use DateTime::Format::Mail;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant forward_tolerance_default  => { hours => 2 };
use constant backward_tolerance_default => { days  => 5 };

=head1 SYNOPSIS

    use Courier::Filter::Module::FakeDate;

    my $module = Courier::Filter::Module::Header->new(
        forward_tolerance   => {
            # years, months, weeks, days, hours, minutes, seconds
            hours       => 2
        },
        backward_tolerance  => {
            # years, months, weeks, days, hours, minutes, seconds
            days        => 5
        },
        
        ignore_unparseable  => 0,
        
        logger      => $logger,
        inverse     => 0,
        trusting    => 0,
        testing     => 0,
        debugging   => 0
    );
    
    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if it has a C<Date> header field that lies too far in the future or the
past, relative to the local system's time.  If the message has a C<Resent-Date>
header field (see RFC 2822, 3.6.6), that one is examined instead, because the
message could simply be an old one that has recently been re-sent, which is
perfectly legitimate behavior.

In the case of a match, the response tells the sender that their C<Date> header
is implausible and that they should check their clock.

I<Note>: Times in different time zones are compared correctly.

I<Note>: When using this filter module, it is essential that the local system's
own clock is set correctly, or there will be an increased risk of legitimate
messages getting rejected.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::FakeDate>

Creates a new B<FakeDate> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<forward_tolerance>

=item B<backward_tolerance>

The maximum durations by which a message's C<Date> or C<Resent-Date> header may
diverge into the future and the past, respectively, from the local system's
time.  Each duration must be specified as a hash-ref containing one or more
time units and their respective quantity/ies, just as specified by
L<DateTime::Duration>.  C<forward_tolerance> defaults to I<2 hours>.
C<backward_tolerance> defaults to I<5 days> to account for transmission
delays.

For example:

    forward_tolerance  => { hours => 4 },
    backward_tolerance => { days  => 1, hours => 12 }

=item B<ignore_unparseable>

A boolean value controlling whether messages whose C<Date> or C<Resent-Date>
header does not loosely conform to RFCs 822 or 2822 should be ignored (B<true>)
or matched (B<false>).  Defaults to B<false>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/new> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $forward_tolerance  = DateTime::Duration->new(
        %{ $options{forward_tolerance}  || $class->forward_tolerance_default  }
    );
    my $backward_tolerance = DateTime::Duration->new(
        %{ $options{backward_tolerance} || $class->backward_tolerance_default }
    );
    
    my $date_parser = DateTime::Format::Mail->new( loose => TRUE );
    
    my $self = $class->SUPER::new(
        %options,
        forward_tolerance   => $forward_tolerance,
        backward_tolerance  => $backward_tolerance,
        date_parser         => $date_parser
    );
    
    return $self;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    my $date_header_field;
    my $date_text;
    foreach ('Resent-Date', 'Date') {
        $date_text = $message->header($_);
        $date_header_field = $_, last
            if defined($date_text);
    }
    
    return undef
        if not defined($date_text);
        # Do not match if there is neither a "Date" nor a "Resent-Date" header field.
    
    my $date = eval { $self->{date_parser}->parse_datetime($date_text) };
    
    if (not defined($date)) {
        $self->warn(sprintf('FakeDate: Unparseable "%s" header detected: "%s". Fix your software!', $date_header_field, $date_text));
        return
            $self->{ignore_unparseable} ?
                undef
            :   sprintf(
                    'FakeDate: Unparseable "%s" header detected: "%s". Fix your software!',
                    $date_header_field, $date_text
                );
    }
    
    $date->set_time_zone('UTC');
    
    my $now  = DateTime->now;
    my $max_date = $now + $self->{forward_tolerance};
    my $min_date = $now - $self->{backward_tolerance};
    
    return sprintf('FakeDate: Implausible "%s" header detected. Check your clock!', $date_header_field)
        if $date < $min_date or $date > $max_date;
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
