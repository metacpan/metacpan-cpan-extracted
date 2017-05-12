package Biblio::ILL::ISO::StatusReport;

=head1 NAME

Biblio::ILL::ISO::StatusReport

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::HistoryReport;
use Biblio::ILL::ISO::CurrentState;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::StatusReport is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::HistoryReport
 Biblio::ILL::ISO::CurrentState

=head1 USED IN

 Biblio::ILL::ISO::StatusOrErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Status-Report ::= EXPLICIT SEQUENCE {
	user-status-report	[0]	IMPLICIT History-Report,
	provider-status-report 	[1]	IMPLICIT Current-State
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $user_status, $provider_status )

Creates a new StatusReport object. 
 Expects a user-status-report (Biblio::ILL::ISO::HistoryReport), and
 a provider-status-report (Biblio::ILL::ISO::CurrentState).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($user_status, $provider_status) = @_;

	croak "missing status-report user-status-report" unless ($user_status);
	croak "invalid status-report user-status-report" unless (ref($user_status) eq "Biblio::ILL::ISO::HistoryReport");

	croak "missing status-report provider-status-report" unless ($provider_status);
	croak "invalid status-report provider-status-report" unless (ref($provider_status) eq "Biblio::ILL::ISO::CurrentState");

	$self->{"user-status-report"} = $user_status;
	$self->{"provider-status-report"} = $provider_status;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $user_status, $provider_status )

Sets the object's user-status-report (Biblio::ILL::ISO::HistoryReport), and
 provider-status-report (Biblio::ILL::ISO::CurrentState).

=cut
sub set {
    my $self = shift;

	my ($user_status, $provider_status) = @_;

	croak "missing status-report user-status-report" unless ($user_status);
	croak "invalid status-report user-status-report" unless (ref($user_status) eq "Biblio::ILL::ISO::HistoryReport");

	croak "missing status-report provider-status-report" unless ($provider_status);
	croak "invalid status-report provider-status-report" unless (ref($provider_status) eq "Biblio::ILL::ISO::CurrentState");

	$self->{"user-status-report"} = $user_status;
	$self->{"provider-status-report"} = $provider_status;
    
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

	if ($k =~ /^user-status-report$/) {
	    $self->{$k} = new Biblio::ILL::ISO::HistoryReport();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^provider-status-report$/) {
	    $self->{$k} = new Biblio::ILL::ISO::CurrentState();
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
