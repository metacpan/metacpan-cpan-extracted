package Biblio::ILL::ISO::ErrorReport;

=head1 NAME

Biblio::ILL::ISO::ErrorReport

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ReportSource;
use Biblio::ILL::ISO::UserErrorReport;
use Biblio::ILL::ISO::ProviderErrorReport;

use Carp;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.08.13 - properly handle either/or nature of report
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ErrorReport is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::ReportSource
 Biblio::ILL::ISO::UserErrorReport
 Biblio::ILL::ISO::ProviderErrorReport

=head1 USED IN

 Biblio::ILL::ISO::StatusOrErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Error-Report ::= EXPLICIT SEQUENCE {
	correlation-information	[0]	ILL-String,
	report-source	[1]	IMPLICIT Report-Source,
	user-error-report	[2]	User-Error-Report OPTIONAL,
		-- mandatory if report-source is "user"; not present otherwise
	provider-error-report	[3]	Provider-Error-Report OPTIONAL
		-- mandatory if report-source is "provider"; not
		-- present otherwise
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $correlation_info, $report_source, $report)

Creates a new ErrorReport object. 
 Expects either no parameters or
 correlation-information (Biblio::ILL::ISO::ILLString or text string),
 report-source (Biblio::ILL::ISO::ReportSource or text string), and
 either a Biblio::ILL::ISO::UserErrorReport or a Biblio::ILL::ISO::ProviderErrorReport.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($corr, $report_source, $report) = @_;

	croak "missing correlation-information" unless ($corr);
	if (ref($corr) eq "Biblio::ILL::ISO::ILLString") {
	    $self->{"correlation-information"} = $cost;
	} else {
	    $self->{"correlation-information"} = new Biblio::ILL::ISO::ILLString($corr);
	}

	croak "missing report-source" unless ($report_source);
	if (ref($report_source) eq "Biblio::ILL::ISO::ReportSource") {
	    $self->{"report-source"} = $report_source;
	} else {
	    $self->{"report-source"} = new Biblio::ILL::ISO::ReportSource($report_source);
	}

	croak "missing report" unless ($report);
	if (ref($report) eq "Biblio::ILL::ISO::UserErrorReport") {
	    $self->{"user-error-report"} = $report;
	} elsif (ref($report) eq "Biblio::ILL::ISO::ProviderErrorReport") {
	    $self->{"provider-error-report"} = $report;
	} else {
	    croak "invalid report type";
	}
	
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $correlation_info, $report_source, $report)

Sets the object's  correlation-information (Biblio::ILL::ISO::ILLString or text string),
 report-source (Biblio::ILL::ISO::ReportSource or text string), and
 either a Biblio::ILL::ISO::UserErrorReport or a Biblio::ILL::ISO::ProviderErrorReport.

=cut
sub set {
    my $self = shift;

    my ($corr, $report_source, $report) = @_;
    
    croak "missing correlation-information" unless ($corr);
    if (ref($corr) eq "Biblio::ILL::ISO::ILLString") {
	$self->{"correlation-information"} = $cost;
    } else {
	$self->{"correlation-information"} = new Biblio::ILL::ISO::ILLString($corr);
    }
    
    croak "missing report-source" unless ($report_source);
    if (ref($report_source) eq "Biblio::ILL::ISO::ReportSource") {
	$self->{"report-source"} = $report_source;
    } else {
	$self->{"report-source"} = new Biblio::ILL::ISO::ReportSource($report_source);
    }
    
    croak "missing report" unless ($report);
    if (ref($report) eq "Biblio::ILL::ISO::UserErrorReport") {
	$self->{"user-error-report"} = $report;
    } elsif (ref($report) eq "Biblio::ILL::ISO::ProviderErrorReport") {
	$self->{"provider-error-report"} = $report;
    } else {
	croak "invalid report type";
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

	if ($k =~ /^correlation-information$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^report-source$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ReportSource();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^user-error-report$/) {
	    $self->{$k} = new Biblio::ILL::ISO::UserErrorReport();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^provider-error-report$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ProviderErrorReport();
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
