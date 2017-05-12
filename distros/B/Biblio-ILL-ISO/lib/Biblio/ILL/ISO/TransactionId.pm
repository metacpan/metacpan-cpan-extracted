package Biblio::ILL::ISO::TransactionId;

=head1 NAME

Biblio::ILL::ISO::TransactionId

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::ILLString;

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

Biblio::ILL::ISO::TransactionId is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SystemId
 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::Answer
 Biblio::ILL::ISO::Cancel
 Biblio::ILL::ISO::CancelReply
 Biblio::ILL::ISO::CheckedIn
 Biblio::ILL::ISO::ConditionalReply
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
 
 Transaction-Id ::= SEQUENCE {
	initial-requester-id	     [0]	IMPLICIT System-Id OPTIONAL,
		-- mandatory for sub-transactions; not called
		-- "requester-id" to distinguish id of initial-requester
		--from id of requester of sub-transaction if there is one
	transaction-group-qualifier  [1]	ILL-String,
	transaction-qualifier	     [2]	ILL-String,
	sub-transaction-qualifier    [3]	ILL-String OPTIONAL
		-- mandatory for sub-transactions
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $tgq, $tq [,$stq [,$systemid]] )

 Creates a new TransactionId object. 
 Expects a transaction group qualifier (Biblio::ILL::ISO::ILLString),
 a transaction qualifier (Biblio::ILL::ISO::ILLString), 
 (optionally) a sub-transaction qualifier (Biblio::ILL::ISO::ILLString), and 
 (optionally) an initial-requester id (Biblio::ILL::ISO::SystemId).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($tgq, $tq, $stq, $systemid) = @_;

	croak "missing transaction-group-qualifier" unless ($tgq);
	croak "missing transaction-qualifier" unless ($tq);
	if ($systemid) {
	    croak "invalid initial-requester-id" unless (ref($systemid) eq "Biblio::ILL::ISO::SystemId");
	}
	
	$self->{"transaction-group-qualifier"} = new Biblio::ILL::ISO::ILLString($tgq);
	$self->{"transaction-qualifier"} = new Biblio::ILL::ISO::ILLString($tq);
	$self->{"sub-transaction-qualifier"} = new Biblio::ILL::ISO::ILLString($stq) if ($stq);
	$self->{"initial-requester-id"} = $systemid if ($systemid);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $tgq, $tq [,$stq [,$systemid]] )

 Sets the object's transaction-group-qualifier (Biblio::ILL::ISO::ILLString),
 transaction-qualifier (Biblio::ILL::ISO::ILLString), 
 (optionally) sub-transaction-qualifier (Biblio::ILL::ISO::ILLString), and 
 (optionally) initial-requester-id (Biblio::ILL::ISO::SystemId).

=cut
sub set {
    my $self = shift;
    my ($tgq, $tq, $stq, $systemid) = @_;

    croak "missing transaction-group-qualifier" unless ($tgq);
    croak "missing transaction-qualifier" unless ($tq);
    if ($systemid) {
	croak "invalid initial-requester-id" unless (ref($systemid) eq "Biblio::ILL::ISO::SystemId");
    }
    
    $self->{"transaction-group-qualifier"} = new Biblio::ILL::ISO::ILLString($tgq);
    $self->{"transaction-qualifier"} = new Biblio::ILL::ISO::ILLString($tq);
    $self->{"sub-transaction-qualifier"} = new Biblio::ILL::ISO::ILLString($stq) if ($stq);
    $self->{"initial-requester-id"} = $systemid if ($systemid);

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

	if ($k =~ /^initial-requester-id$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^transaction-group-qualifier$/)
		 || ($k =~ /^transaction-qualifier$/)
		 || ($k =~ /^sub-transaction-qualifier$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
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
