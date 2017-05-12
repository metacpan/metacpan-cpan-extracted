package Biblio::ILL::ISO::ServiceDateTime;

=head1 NAME

Biblio::ILL::ISO::ServiceDateTime

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::DateTime;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ServiceDateTime is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::DateTime

=head1 USED IN

 Biblio::ILL::ISO::Answer
 Biblio::ILL::ISO::Cancel
 Biblio::ILL::ISO::CancelReply
 Biblio::ILL::ISO::CheckedIn
 Biblio::ILL::ISO::Damaged
 Biblio::ILL::ISO::Expired
 Biblio::ILL::ISO::ForwardNotification
 Biblio::ILL::ISO::Lost
 Biblio::ILL::ISO::Message
 Biblio::ILL::ISO::Overdue
 Biblio::ILL::ISO::Recall
 Biblio::ILL::ISO::Received
 Biblio::ILL::ISO::RenewAnswer
 Biblio::ILL::ISO::Renew
 Biblio::ILL::ISO::Request
 Biblio::ILL::ISO::Returned
 Biblio::ILL::ISO::Shipped
 Biblio::ILL::ISO::StatusOrErrorReport
 Biblio::ILL::ISO::StatusQuery

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Service-Date-Time ::= SEQUENCE {
	date-time-of-this-service 	[0]	IMPLICIT Date-Time,
	-- Time is mandatory for 2nd and subsequent services
	-- invoked for a given ILL-transaction on the same day
	date-time-of-original-service	[1]	IMPLICIT Date-Time OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $service_date [, $original_date] )

Creates a new ServiceDateTime object. 
 Expects a date/time for the service (Biblio::ILL::ISO::DateTime), and
 (optionally) a date/time for the original service (Biblio::ILL::ISO::DateTime).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($refdtthis, $refdtorig) = @_;

	croak "missing date-time-of-this-service" unless ($refdtthis);
	croak "invalid DateTime for this service" unless ((ref($refdtthis) eq "Biblio::ILL::ISO::DateTime"));
	if ($refdtorig) {
	    croak "invalid DateTime for original service" unless ((ref($refdtorig) eq "Biblio::ILL::ISO::DateTime"));
	}
	
	$self->{"date-time-of-this-service"} = $refdtthis;
	$self->{"date-time-of-original-service"} = $refdtorig if ($refdtorig);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $service_date [, $original_date] )

Sets the object's date-time-of-this-service (Biblio::ILL::ISO::DateTime), and
 (optionally) date-time-of-original-service (Biblio::ILL::ISO::DateTime).

=cut
sub set {
    my $self = shift;
    my ($refdtthis, $refdtorig) = @_;
    
    croak "missing date-time-of-this-service" unless ($refdtthis);
    croak "invalid DateTime for this service" unless ((ref($refdtthis) eq "Biblio::ILL::ISO::DateTime"));
    if ($refdtorig) {
	croak "invalid DateTime for original service" unless ((ref($refdtorig) eq "Biblio::ILL::ISO::DateTime"));
    }
    
    $self->{"date-time-of-this-service"} = $refdtthis;
    $self->{"date-time-of-original-service"} = $refdtorig if ($refdtorig);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if (($k =~ /^date-time-of-this-service$/)
	    || ($k =~ /^date-time-of-original-service$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::DateTime();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=cut

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
