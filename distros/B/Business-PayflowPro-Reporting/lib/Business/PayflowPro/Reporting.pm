package Business::PayflowPro::Reporting;

BEGIN {
    $Business::PayflowPro::Reporting::VERSION = '0.01';
}

# ABSTRACT: Payflow Pro Reporting API

use strict;
use warnings;
use LWP::UserAgent;
use XML::Writer;
use XML::Simple qw/XMLin XMLout/;
use vars qw/$errstr/;

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    # validate
    defined $args->{user}    or do { $errstr = 'user is required';    return };
    defined $args->{vendor}  or do { $errstr = 'vendor is required';  return };
    defined $args->{partner} or do { $errstr = 'partner is required'; return };
    defined $args->{password}
      or do { $errstr = 'password is required'; return };

    if ( $args->{test_mode} ) {
        $args->{url} =
          'https://payments-reports.paypal.com/test-reportingengine';
    }
    else {
        $args->{url} = 'https://payments-reports.paypal.com/reportingengine';
    }

    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = LWP::UserAgent->new(%$ua_args);
    }

    bless $args, $class;
}

sub errstr { $errstr }

sub runReportRequest {
    my $self = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    # we use XML::Writer b/c element order is relevant
    my $xml;
    my $writer = XML::Writer->new( OUTPUT => \$xml );
    $writer->startTag('reportingEngineRequest');
    $writer->startTag('authRequest');
    foreach my $k ( 'user', 'vendor', 'partner', 'password' ) {
        $writer->dataElement( $k, $self->{$k} );
    }
    $writer->endTag('authRequest');
    $writer->startTag('runReportRequest');
    $writer->dataElement( 'reportName', $args->{reportName} );
    if ( $args->{reportName} eq 'DailyActivityReport' ) {
        $writer->startTag('reportParam');
        $writer->dataElement( 'paramName',  'report_date' );
        $writer->dataElement( 'paramValue', $args->{report_date} );
        $writer->endTag('reportParam');
    }
    elsif ( $args->{reportName} eq 'TransactionSummaryReport' ) {
        foreach my $k ( 'start_date', 'end_date' ) {
            $writer->startTag('reportParam');
            $writer->dataElement( 'paramName',  $k );
            $writer->dataElement( 'paramValue', $args->{$k} );
            $writer->endTag('reportParam');
        }
    }
    $writer->dataElement( 'pageSize', $args->{pageSize} || 50 );
    $writer->endTag('runReportRequest');
    $writer->endTag('reportingEngineRequest');

    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . $xml;
    print "<!-- $xml -->\n\n" if $self->{debug};
    my $resp = $self->{ua}->post( $self->{url}, Content => $xml );
    print "<!-- " . $resp->content . " -->\n\n" if $self->{debug};

    my $d = XMLin( $resp->content, SuppressEmpty => '' );
    if ( exists $d->{runReportResponse}->{reportId} ) {
        return $d->{runReportResponse}->{reportId};
    }
    else {
        $errstr = $d->{runReportResponse}->{statusMsg}
          || $d->{baseResponse}->{responseMsg};
        return;
    }
}

sub getResultsRequest {
    my $self = shift;
    my ($reportId) = @_;

    my $xml = $self->_make_reportId_xml( 'getResultsRequest', $reportId );
    my $resp = $self->{ua}->post( $self->{url}, Content => $xml );
    print "<!-- " . $resp->content . " -->\n\n" if $self->{debug};

    my $d = XMLin( $resp->content, SuppressEmpty => '' );
    if ( $d->{baseResponse}->{responseCode} == 100 ) {
        return $d->{getResultsResponse}->{Results};
    }
    else {
        $errstr = $d->{getResultsResponse}->{Results}->{statusMsg}
          || $d->{baseResponse}->{responseMsg};
        return;
    }
}

sub getMetaDataRequest {
    my $self = shift;
    my ($reportId) = @_;

    my $xml = $self->_make_reportId_xml( 'getMetaDataRequest', $reportId );
    my $resp = $self->{ua}->post( $self->{url}, Content => $xml );
    print "<!-- " . $resp->content . " -->\n\n" if $self->{debug};

    my $d = XMLin( $resp->content, SuppressEmpty => '' );
    if ( $d->{baseResponse}->{responseCode} == 100 ) {
        return $d->{getMetaDataResponse};
    }
    else {
        $errstr = $d->{baseResponse}->{responseMsg};
        return;
    }
}

sub _make_reportId_xml {
    my ( $self, $type, $reportId ) = @_;

    # we use XML::Writer b/c element order is relevant
    my $xml;
    my $writer = XML::Writer->new( OUTPUT => \$xml );
    $writer->startTag('reportingEngineRequest');
    $writer->startTag('authRequest');
    foreach my $k ( 'user', 'vendor', 'partner', 'password' ) {
        $writer->dataElement( $k, $self->{$k} );
    }
    $writer->endTag('authRequest');
    $writer->startTag($type);
    $writer->dataElement( 'reportId', $reportId );
    $writer->endTag($type);
    $writer->endTag('reportingEngineRequest');

    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . $xml;
    print "<!-- $xml -->\n\n" if $self->{debug};
    return $xml;
}

sub getDataRequest {
    my $self = shift;
    my ( $reportId, $pageNum ) = @_;

    # we use XML::Writer b/c element order is relevant
    my $xml;
    my $writer = XML::Writer->new( OUTPUT => \$xml );
    $writer->startTag('reportingEngineRequest');
    $writer->startTag('authRequest');
    foreach my $k ( 'user', 'vendor', 'partner', 'password' ) {
        $writer->dataElement( $k, $self->{$k} );
    }
    $writer->endTag('authRequest');
    $writer->startTag('getDataRequest');
    $writer->dataElement( 'reportId', $reportId );
    $writer->dataElement( 'pageNum', $pageNum || 1 );
    $writer->endTag('getDataRequest');
    $writer->endTag('reportingEngineRequest');

    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . $xml;
    print "<!-- $xml -->\n\n" if $self->{debug};
    my $resp = $self->{ua}->post( $self->{url}, Content => $xml );
    print "<!-- " . $resp->content . " -->\n\n" if $self->{debug};

    my $d = XMLin( $resp->content, SuppressEmpty => '' );
    if ( $d->{baseResponse}->{responseCode} == 100 ) {
        my $reportDataRow = $d->{getDataResponse}->{reportDataRow};
        my @reportDataRow =
          ref($reportDataRow) eq 'ARRAY' ? @$reportDataRow : ($reportDataRow);
        return wantarray ? @reportDataRow : \@reportDataRow;
    }
    else {
        $errstr = $d->{baseResponse}->{responseMsg};
        return;
    }
}

1;
__END__

=pod

=head1 NAME

Business::PayflowPro::Reporting - Payflow Pro Reporting API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Business::PayflowPro::Reporting;
    use Data::Dumper;
    
    my $bpr = Business::PayflowPro::Reporting->new(
        user => $cfg{user},
        vendor => $cfg{vendor},
        partner => $cfg{partner},
        password => $cfg{password},
    ) or die $Business::PayflowPro::Reporting::errstr;
    
    my $reportId = $bpr->runReportRequest(
        reportName => 'TransactionSummaryReport',
        start_date => '2010-09-17 00:00:00',
        end_date   => '2010-09-18 23:59:59',
        pageSize => 50, # optional
    ) or die $bpr->errstr;
    print "Get $reportId\n";
    
    my $metadata = $bpr->getMetaDataRequest($reportId) or die $bpr->errstr;
    my $page = $metadata->{numberOfPages};
    my $columnMetaData = $metadata->{columnMetaData}; # col name
    foreach my $p (1 .. $page) {
        my @reportDataRow = $bpr->getDataRequest($reportId, $p); # col value
        print Dumper(\@reportDataRow);
    }

=head1 DESCRIPTION

Payflow Pro Reporting API, read L<https://cms.paypal.com/cms_content/US/en_US/files/developer/PP_Reporting_Guide.pdf> for more details.

WARN: Report Template stuff is not implemented. drop me a note if you need it, I am glad to do it.

=head2 METHODS

=head3 CONSTRUCTION

    my $bpr = Business::PayflowPro::Reporting->new(
        user => $cfg{user},
        vendor => $cfg{vendor},
        partner => $cfg{partner},
        password => $cfg{password},
    ) or die $Business::PayflowPro::Reporting::errstr;

=over 4

=item * user

=item * vendor

=item * partner

=item * password

config keys from PayPal

=item * debug

=item * test_mode

Live or Test Transactions

=item * ua_args

passed to LWP::UserAgent

=item * ua

L<LWP::UserAgent> or L<WWW::Mechanize> instance

=back

=head3 runReportRequest

    # Running a Daily Activity Report
    my $reportId = $bpr->runReportRequest(
        reportName => 'DailyActivityReport',
        report_date => '2010-09-18',
        pageSize => 50, # optional
    ) or die $bpr->errstr;
    
    # or Running a Transaction Summary Report
    my $reportId = $bpr->runReportRequest(
        reportName => 'TransactionSummaryReport',
        start_date => '2010-09-17 00:00:00',
        end_date   => '2010-09-18 23:59:59',
        pageSize => 50, # optional
    ) or die $bpr->errstr;

=head3 getResultsRequest

Getting Results by Report ID

    my $report = $bpr->getResultsRequest($reportId) or die $bpr->errstr;

=head3 getMetaDataRequest

retrieve the format of the data in a previously run report.

    my $metadata = $bpr->getMetaDataRequest($reportId); 

=head3 getDataRequest

    my @reportDataRow = $bpr->getDataRequest($reportId, $pageNum);

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
