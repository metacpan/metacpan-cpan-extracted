package Business::SLA;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.05';

=head1 NAME

Business::SLA - 

=head1 SYNOPSIS

  use Business::SLA;

  my $SLAObj = Business::SLA->new(
    BusinessHours     => new Business::Hours,
    InHoursDefault    => '2 real hours',
    OutOfHoursDefault => '1 business hour',
  );

  # or set/change options later
  $SLAObj->SetBusinessHours( new Business::Hours );
  $SLAObj->SetInHoursDefault('2 real hours');
  $SLAObj->SetOutOfHoursDefault('1 business hour');

  # add service levels
  $SLAObj->Add( '2 real hours' => RealMinutes => 2*60 );
  $SLAObj->Add( '1 business hour' => BusinessMinutes => 60 );
  $SLAObj->Add( 'next business minute' );

=head1 DESCRIPTION

This module is a simple tool for handling operations related to
Service Level Agreements.

=head1 METHODS

=head2 new

Creates and returns new Business::SLA object.

Takes a hash with values of L</BusinessHours>, L</InHoursDefault>
and L</OutOfHoursDefault> options. You can ommit these options
and set them latter using methods (see below).

=cut

sub new {
    my $class = shift;

    my $self = bless( { @_ }, ref($class) || $class );

    return ($self);
}

=head2 SetBusinessHours

Sets a L<Business::Hours> object to use for calculations.
This module works without this option, but looses most functionality
you can get with it.

It's possible use any object that API-compatible with L<Business::Hours>.

=cut

sub SetBusinessHours {
    my $self     = shift;
    my $bizhours = shift;

    return $self->{'BusinessHours'} = $bizhours;
}

=head2 BusinessHours

Returns the current L<Business::Hours> object or undef if
it's not set.

=cut

sub BusinessHours {
    my $self = shift;

    return $self->{'BusinessHours'};
}

=head2 SetInHoursDefault

Sets the default service level for times inside of business hours.

Takes a service level.

=cut

sub SetInHoursDefault {
    my $self = shift;
    my $sla  = shift;

    return $self->{'InHoursDefault'} = $sla;
}

=head2 InHoursDefault

Returns the default service level for times inside of business hours.

=cut

sub InHoursDefault {
    my $self = shift;

    return $self->{'InHoursDefault'};
}

=head2 SetOutOfHoursDefault

Sets the default service level for times outside of business hours.

Takes a service level.

Note that L</BusinessHours> are used for calculations, so this
option makes not much sense without L<business hours have been
set|/SetBusinessHours>.

=cut

sub SetOutOfHoursDefault {
    my $self = shift;
    my $sla  = shift;

    $self->{'OutOfHoursDefault'} = $sla;
}

=head2 OutOfHoursDefault

Returns the default service level for times outside of business hours.

=cut

sub OutOfHoursDefault {
    my $self = shift;

    return $self->{'OutOfHoursDefault'};
}

=head2 IsInHours

Returns true if the date passed in is in business hours, and false otherwise.
If no L<business hours have been set|/SetBusinessHours>, returns true by default.

Takes a date in Unix time format (number of seconds since the epoch).

=cut

sub IsInHours {
    my $self = shift;
    my $date = shift;

    # if no business hours are set, by definition we're in hours
    if ( my $bhours = $self->BusinessHours ) {
        return $bhours->first_after($date) == $date? 1 : 0;
    }
    return 1;
}

=head2 SLA

Returns the default servise level for the specified time.

Takes a date in Unix time format (number of seconds since the epoch).

=cut

sub SLA {
    my $self = shift;
    my $date = shift;

    if ( $self->IsInHours($date) ) {
        return $self->InHoursDefault;
    }
    else {
        return $self->OutOfHoursDefault;
    }
}

=head2 Add

Adds or replaces a service level definition.

Takes a service level and a hash with agreements. In the hash you
can define BusinessMinutes, RealMinutes and StartImmediately boolean
option.

=cut

sub Add {
    my $self = shift;
    my $sla  = shift;

    return $self->{'hash'}->{$sla} = { @_ };
}

=head2 AddRealMinutes

The number of real minutes to add for the specified SLA.

Takes a service level.

=cut

sub AddRealMinutes {
    my $self = shift;
    my $sla  = shift;

    return 0 unless exists $self->{'hash'}{ $sla }{'RealMinutes'};
    return $self->{'hash'}{ $sla }{'RealMinutes'} || 0;
}

=head2 AddBusinessMinutes

The number of business minutes to add for the specified SLA.

Takes a service level.

=cut

sub AddBusinessMinutes {
    my $self = shift;
    my $sla  = shift;

    return undef unless $self->BusinessHours;
    return 0 unless exists $self->{'hash'}{ $sla }{'BusinessMinutes'};
    return $self->{'hash'}{ $sla }{'BusinessMinutes'} || 0;
}

=head2 StartImmediately

Returns true if things should be started immediately for a service
level. See also L<Add> and L</Starts>.

Takes the service level.

=cut

sub StartImmediately {
    my $self = shift;
    my $sla  = shift;

    return $self->{'hash'}{ $sla }{'StartImmediately'} || 0;
}

=head2 Starts

Returns the starting time, given a date and a service level.

If the service level's been defined as L<StartImmediately> then returns
the same date, as well this also happens if L<business hours are
not set|/SetBusinessHours>.

Takes a date in Unix time format (number of seconds since the epoch)
and a service level.

=cut

sub Starts {
    my $self = shift;
    my $date = shift;
    my $sla  = shift || $self->SLA( $date );

    return $date if $self->StartImmediately( $sla );

    if ( my $bhours = $self->BusinessHours ) {
        return $bhours->first_after( $date );
    }
    else {
        return $date;
    }
}

=head2 Due

Returns the due time, given an SLA and a date.

Takes a date in Unix time format (number of seconds since the epoch)
and the hash key for the SLA.

=cut

sub Due {
    my $self = shift;
    my $date = shift;
    my $sla  = shift || $self->SLA( $date );

    # find start time
    my $due = $self->Starts($date, $sla);

    # don't add business minutes unless we have some set
    if ( my $bminutes = $self->AddBusinessMinutes($sla) ) {
        $due = $self->BusinessHours->add_seconds( $due, 60 * $bminutes );
    }

    $due += ( 60 * $self->AddRealMinutes($sla) );

    return $due;
}

=head1 SUPPORT

Send email to bug-business-sla@rt.cpan.org

=head1 AUTHOR

    Linda Julien
    Best Practical Solutions, LLC 
    leira@bestpractical.com
    http://www.bestpractical.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), L<Business::Hours>.

=cut


1;
