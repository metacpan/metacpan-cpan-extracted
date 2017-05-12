package Biblio::ILL::ISO::ProtocolVersionNum;

=head1 NAME

Biblio::ILL::ISO::ProtocolVersionNum

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ENUMERATED;

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

Biblio::ILL::ISO::ProtocolVersionNum is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

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

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
protocol-version-num	[0]	IMPLICIT INTEGER, -- {
			-- version-1 (1),
			-- version-2 (2)
			--},

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $condition )

 Creates a new ProtocolVersionNum object. 
 Valid paramaters are listed in the FROM THE ASN DEFINITION section
 (e.g. "version-1").

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"version-1" => 1,
			    "version-2" => 2
			    };
    
    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid ProtocolVersionNum: [$s]";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
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

