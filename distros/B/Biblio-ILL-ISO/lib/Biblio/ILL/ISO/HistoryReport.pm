package Biblio::ILL::ISO::HistoryReport;

=head1 NAME

Biblio::ILL::ISO::HistoryReport

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::MostRecentService;
use Biblio::ILL::ISO::SystemId;
use Biblio::ILL::ISO::ShippedServiceType;
use Biblio::ILL::ISO::TransactionResults;
use Carp;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.08.13 - allow passing in of text ShippedServiceType
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::HistoryReport is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::ISODate
 Biblio::ILL::ISO::MostRecentService
 Biblio::ILL::ISO::SystemId
 Biblio::ILL::ISO::ShippedServiceType
 Biblio::ILL::ISO::TransactionResults

=head1 USED IN

 Biblio::ILL::ISO::StatusReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 History-Report ::= EXPLICIT SEQUENCE {
	date-requested	[0]	IMPLICIT ISO-Date OPTIONAL,
	author	[1]	ILL-String OPTIONAL,
	title	[2]	ILL-String OPTIONAL,
	author-of-article	[3]	ILL-String OPTIONAL,
	title-of-article	[4]	ILL-String OPTIONAL,
	date-of-last-transition 	[5]	IMPLICIT ISO-Date,
	most-recent-service	[6]	IMPLICIT ENUMERATED {
				iLL-REQUEST			(1),
				fORWARD 			(21),
				fORWARD-NOTIFICATION 		(2),
				sHIPPED 			(3),
				iLL-ANSWER 			(4),
				cONDITIONAL-REPLY 		(5),
				cANCEL 				(6),
				cANCEL-REPLY 			(7),
				rECEIVED 			(8),
				rECALL 				(9),
				rETURNED 			(10),
				cHECKED-IN 			(11),
				rENEW-ANSWER 			(14),
				lOST 				(15),
				dAMAGED 			(16),
				mESSAGE 			(17),
				sTATUS-QUERY 			(18),
				sTATUS-OR-ERROR-REPORT		(19),
				eXPIRED 			(20)
				}
	date-of-most-recent-service	[7]	IMPLICIT ISO-Date,
	initiator-of-most-recent-service	[8]	IMPLICIT System-Id,
	shipped-service-type	[9]	IMPLICIT Shipped-Service-Type OPTIONAL,
		-- If the information is available, i.e. if a SHIPPED or
		-- RECEIVED APDU has been sent or received, then the
		-- value in this parameter shall be supplied.
		-- Value must contain the most current information, e.g. if a
		-- requester has received a SHIPPED APDU and then
		-- invokes a RECEIVED.request, then the value from the
		-- RECEIVED.request is used
	transaction-results	[10]	IMPLICIT Transaction-Results OPTIONAL,
		-- If the information is available, i.e. if an ILL-ANWSER
		-- APDU has been sent or received, then the value in this
		-- parameter shall be supplied.
	most-recent-service-note	[11]	ILL-String OPTIONAL
		-- If the information is available, i.e. if a note has been
		-- supplied in the most recent service primitive, then the
		-- value in this parameter shall be supplied.
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [...a whole bunch of parameters...] )

Creates a new HistoryReport object. 
 Expects either no parameters, or
 date-of-last-transition (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 most-recent-service (Biblio::ILL::ISO::MostRecentService), 
 date-of-most-recent-service (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 initiator-of-most-recent-service (Biblio::ILL::ISO::SystemId),
 (optionally) date-requested (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 (optionally) author (Biblio::ILL::ISO::ILLString or text string),
 (optionally) title  (Biblio::ILL::ISO::ILLString or text string),
 (optionally) author-of-article (Biblio::ILL::ISO::ILLString or text string),
 (optionally) title-of-article (Biblio::ILL::ISO::ILLString or text string),
 (optionally) shipped-service-type (Biblio::ILL::ISO::ShippedServiceType),
 (optionally) transaction-results (Biblio::ILL::ISO::TransactionResults), and
 (optionally) most-recent-service-note (Biblio::ILL::ISO::ILLString or text string)

 Pass empty strings ("") as placeholders.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($dolt, $mrsvc, $date_of_mrsvc, $init_of_mrsvc, 
	    $date_req, $author, $title, $author_of_article, $title_of_article,
	    $sst, $trans_res, $mrsvc_note) = @_;

	croak "missing date-of-last-transition" unless ($dolt);
	if (ref($dolt) eq "Biblio::ILL::ISO::ISODate") {
	    $self->{"date-of-last-transition"} = $dolt;
	} else {
	    # Huh.  Must be in text format - ISODate will let us know if it's not....
	    $self->{"date-of-last-transition"} = new Biblio::ILL::ISO::ISODate($dolt);
	}

	croak "missing most-recent-service" unless ($mrsvc);
	if (ref($mrsvc) eq "Biblio::ILL::ISO::MostRecentService") {
	    $self->{"most-recent-service"} = $mrsvc;
	} else {
	    # Huh.  Must be in text format - MostRecentService will let us know if it's not....
	    $self->{"most-recent-service"} = new Biblio::ILL::ISO::MostRecentService($mrsvc);
	}

	croak "missing date-of-most-recent-service" unless ($date_of_mrsvc);
	if (ref($date_of_mrsvc) eq "Biblio::ILL::ISO::ISODate") {
	    $self->{"date-of-most-recent-service"} = $date_of_mrsvc;
	} else {
	    # Huh.  Must be in text format - ISODate will let us know if it's not....
	    $self->{"date-of-most-recent-service"} = new Biblio::ILL::ISO::ISODate($date_of_mrsvc);
	}

	croak "missing initiator-of-most-recent-service" unless ($init_of_mrsvc);
	croak "invalid initiator-of-most-recent-service" unless (ref($init_of_mrsvc) eq "Biblio::ILL::ISO::SystemId");
	$self->{"initiator-of-most-recent-service"} = $init_of_mrsvc;

	if ($date_req) {
	    if (ref($date_req) eq "Biblio::ILL::ISO::ISODate") {
		$self->{"date-requested"} = $date_req;
	    } else {
		# Huh.  Must be in text format - ISODate will let us know if it's not....
		$self->{"date-requested"} = new Biblio::ILL::ISO::ISODate($date_req);
	    }
	}

	if ($author) {
	    if (ref($author) eq "Biblio::ILL::ISO::ILLString") {
		$self->{"author"} = $author;
	    } else {
		$self->{"author"} = new Biblio::ILL::ISO::ILLString($author);
	    }
	}

	if ($title) {
	    if (ref($title) eq "Biblio::ILL::ISO::ILLString") {
		$self->{"title"} = $title;
	    } else {
		$self->{"title"} = new Biblio::ILL::ISO::ILLString($title);
	    }
	}

	if ($author_of_article) {
	    if (ref($author_of_article) eq "Biblio::ILL::ISO::ILLString") {
		$self->{"author-of-article"} = $author_of_article;
	    } else {
		$self->{"author-of-article"} = new Biblio::ILL::ISO::ILLString($author_of_article);
	    }
	}

	if ($title_of_article) {
	    if (ref($title_of_article) eq "Biblio::ILL::ISO::ILLString") {
		$self->{"title-of-article"} = $title_of_article;
	    } else {
		$self->{"title-of-article"} = new Biblio::ILL::ISO::ILLString($title_of_article);
	    }
	}

	if ($sst) {
	    if (ref($sst) eq "Biblio::ILL::ISO::ShippedServiceType") {
		$self->{"shipped-service-type"} = $sst;
	    } else {
		# Huh.  Must be in text format - ShippedServiceType will let us know if it's not....
		$self->{"shipped-service-type"} = new Biblio::ILL::ISO::ShippedServiceType($sst);
	    }
	}

	croak "invalid transaction-results" unless (ref($trans_res) eq "Biblio::ILL::ISO::TransactionResults");
	$self->{"transaction-results"} = $trans_res;

	if ($mrsvc_note) {
	    if (ref($mrsvc_note) eq "Biblio::ILL::ISO::ILLString") {
		$self->{"most-recent-service-note"} = $mrsvc_note;
	    } else {
		# Huh.  Must be in text format - ILLString will let us know if it's not....
		$self->{"most-recent-service-note"} = new Biblio::ILL::ISO::ILLString($mrsvc_note);
	    }
	}

    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( [...a whole bunch of parameters...] )

Sets the object's  date-of-last-transition (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 most-recent-service (Biblio::ILL::ISO::MostRecentService), 
 date-of-most-recent-service (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 initiator-of-most-recent-service (Biblio::ILL::ISO::SystemId),
 (optionally) date-requested (Biblio::ILL::ISO::ISODate or text string (YYYYMMDD)),
 (optionally) author (Biblio::ILL::ISO::ILLString or text string),
 (optionally) title  (Biblio::ILL::ISO::ILLString or text string),
 (optionally) author-of-article (Biblio::ILL::ISO::ILLString or text string),
 (optionally) title-of-article (Biblio::ILL::ISO::ILLString or text string),
 (optionally) shipped-service-type (Biblio::ILL::ISO::ShippedServiceType),
 (optionally) transaction-results (Biblio::ILL::ISO::TransactionResults), and
 (optionally) most-recent-service-note (Biblio::ILL::ISO::ILLString or text string)

 Pass empty strings ("") as placeholders.

=cut
sub set {
    my $self = shift;

    my ($dolt, $mrsvc, $date_of_mrsvc, $init_of_mrsvc, 
	$date_req, $author, $title, $author_of_article, $title_of_article,
	$sst, $trans_res, $mrsvc_note) = @_;
    
    croak "missing date-of-last-transition" unless ($dolt);
    if (ref($dolt) eq "Biblio::ILL::ISO::ISODate") {
	$self->{"date-of-last-transition"} = $dolt;
    } else {
	# Huh.  Must be in text format - ISODate will let us know if it's not....
	$self->{"date-of-last-transition"} = new Biblio::ILL::ISO::ISODate($dolt);
    }
    
    croak "missing most-recent-service" unless ($mrsvc);
    if (ref($mrsvc) eq "Biblio::ILL::ISO::MostRecentService") {
	$self->{"most-recent-service"} = $mrsvc;
    } else {
	# Huh.  Must be in text format - MostRecentService will let us know if it's not....
	$self->{"most-recent-service"} = new Biblio::ILL::ISO::MostRecentService($mrsvc);
    }
    
    croak "missing date-of-most-recent-service" unless ($date_of_mrsvc);
    if (ref($date_of_mrsvc) eq "Biblio::ILL::ISO::ISODate") {
	$self->{"date-of-most-recent-service"} = $date_of_mrsvc;
    } else {
	# Huh.  Must be in text format - ISODate will let us know if it's not....
	$self->{"date-of-most-recent-service"} = new Biblio::ILL::ISO::ISODate($date_of_mrsvc);
    }
    
    croak "missing initiator-of-most-recent-service" unless ($init_of_mrsvc);
    croak "invalid initiator-of-most-recent-service" unless (ref($init_of_mrsvc) eq "Biblio::ILL::ISO::SystemId");
    $self->{"initiator-of-most-recent-service"} = $init_of_mrsvc;
    
    if ($date_req) {
	if (ref($date_req) eq "Biblio::ILL::ISO::ISODate") {
	    $self->{"date-requested"} = $date_req;
	} else {
	    # Huh.  Must be in text format - ISODate will let us know if it's not....
	    $self->{"date-requested"} = new Biblio::ILL::ISO::ISODate($date_req);
	}
    }
    
    if ($author) {
	if (ref($author) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"author"} = $author;
	} else {
	    $self->{"author"} = new Biblio::ILL::ISO::ILLString($author);
	}
    }
    
    if ($title) {
	if (ref($title) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"title"} = $title;
	} else {
	    $self->{"title"} = new Biblio::ILL::ISO::ILLString($title);
	}
    }
    
    if ($author_of_article) {
	if (ref($author_of_article) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"author-of-article"} = $author_of_article;
	} else {
	    $self->{"author-of-article"} = new Biblio::ILL::ISO::ILLString($author_of_article);
	}
    }
    
    if ($title_of_article) {
	if (ref($title_of_article) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"title-of-article"} = $title_of_article;
	} else {
	    $self->{"title-of-article"} = new Biblio::ILL::ISO::ILLString($title_of_article);
	}
    }
    
    if ($sst) {
	if (ref($sst) eq "Biblio::ILL::ISO::ShippedServiceType") {
	    $self->{"shipped-service-type"} = $sst;
	} else {
	    # Huh.  Must be in text format - ShippedServiceType will let us know if it's not....
	    $self->{"shipped-service-type"} = new Biblio::ILL::ISO::ShippedServiceType($sst);
	}
    }
    
    croak "invalid transaction-results" unless (ref($trans_res) eq "Biblio::ILL::ISO::TransactionResults");
    $self->{"transaction-results"} = $trans_res;
    
    if ($mrsvc_note) {
	if (ref($mrsvc_note) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"most-recent-service-note"} = $mrsvc_note;
	} else {
	    # Huh.  Must be in text format - ILLString will let us know if it's not....
	    $self->{"most-recent-service-note"} = new Biblio::ILL::ISO::ILLString($mrsvc_note);
	}
    }
    
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

	if (($k =~ /^date-requested$/)
	    || ($k =~ /^date-of-last-transition$/)
	    || ($k =~ /^date-of-most-recent-service$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif (($k =~ /^author$/) 
		 || ($k =~ /^title$/)
		 || ($k =~ /^author-of-article$/)
		 || ($k =~ /^title-of-article$/)
		 || ($k =~ /^most-recent-service-note$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^most-recent-service$/) {
	    $self->{$k} = new Biblio::ILL::ISO::MostRecentService();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^initiator-of-most-recent-service$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemId();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^shipped-service-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ShippedServiceType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^transaction-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransactionResults();
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
