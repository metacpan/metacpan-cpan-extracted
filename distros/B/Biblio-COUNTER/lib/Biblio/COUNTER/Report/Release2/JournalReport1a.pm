package Biblio::COUNTER::Report::Release2::JournalReport1a;

use strict;
use warnings;

use Biblio::COUNTER::Report qw(REQUESTS TURNAWAYS MAY_BE_BLANK NOT_BLANK);

@Biblio::COUNTER::Report::Release2::JournalReport1a::ISA = qw(Biblio::COUNTER::Report);

sub canonical_report_name { 'Journal Report 1a (R2)' }
sub canonical_report_description { 'Number of Successful Full-Text Article Requests from an Archive by Month and Journal' };
sub canonical_report_code { 'JR1a' }
sub release_number { 2 }

sub process_header_rows {
    my ($self) = @_;
    
    # Report name and description
    $self->begin_row
         ->check_report_name
         ->check_report_description
         ->end_row;
    
    # Archive title
    $self->begin_row
         ->check_title(NOT_BLANK)
         ->end_row;
    
    # Period covered
    $self->begin_row
         ->check_period_covered
         ->end_row;
    
    # Report criteria
    $self->begin_row
         ->check_report_criteria
         ->end_row;
    
    # Date run label
    $self->begin_row
         ->check_label('Date run:')
         ->end_row;
    
    # Date run
    $self->begin_row
         ->check_date_run
         ->end_row;
    
    # Data column labels
    $self->begin_row
         ->check_blank
         ->check_label('Publisher',   qr/^(?i)pub/)
         ->check_label('Platform',    qr/^(?i)plat/)
         ->check_label('Print ISSN',  qr/^(?i)print issn/)
         ->check_label('Online ISSN', qr/^(?i)online issn/)
         ->check_period_labels
         ->check_label('YTD Total')
         ->check_label('YTD HTML')
         ->check_label('YTD PDF')
         ->end_row;
    
    # Data summary
    $self->begin_row
         ->check_label('Total for all journals')
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(MAY_BE_BLANK)
         ->check_blank
         ->check_blank
         ->check_count_by_periods(REQUESTS)
         ->check_ytd_total(REQUESTS)
         ->check_ytd_html(REQUESTS)
         ->check_ytd_pdf(REQUESTS)
         ->end_row;
}

sub process_record {
    my ($self) = @_;
    $self->begin_row
         ->check_title(NOT_BLANK)
         ->check_publisher(NOT_BLANK)
         ->check_platform(NOT_BLANK)
         ->check_print_issn
         ->check_online_issn
         ->check_count_by_periods(REQUESTS)
         ->check_ytd_total
         ->check_ytd_html
         ->check_ytd_pdf
         ->end_row;
}

1;

=pod

=head1 NAME

Biblio::COUNTER::Report::Release2::JournalReport1 - a JR1a (R2) COUNTER report

=head1 SYNOPSIS

    $report = Biblio::COUNTER::Report::Release2::JournalReport1a->new(
        'file' => $file,
    );
    $report->process;

=cut
