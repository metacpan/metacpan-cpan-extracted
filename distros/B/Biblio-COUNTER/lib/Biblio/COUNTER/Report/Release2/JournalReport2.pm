package Biblio::COUNTER::Report::Release2::JournalReport2;

use strict;
use warnings;

use Biblio::COUNTER::Report qw(TURNAWAYS MAY_BE_BLANK NOT_BLANK);

@Biblio::COUNTER::Report::Release2::JournalReport2::ISA = qw(Biblio::COUNTER::Report);

sub canonical_report_name { 'Journal Report 2 (R2)' }
sub canonical_report_description { 'Turnaways by Month and Journal' };
sub canonical_report_code { 'JR2' }
sub release_number { 2 }

sub process_header_rows {
    my ($self) = @_;
    
    # Report name and title
    $self->begin_row
         ->check_report_name
         ->check_report_description
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
         ->check_label('Page type',   qr/^(?i)page\s+type/)
         ->check_period_labels
         ->check_label('YTD Total')
         ->end_row;
    
    # Data summary
    $self->begin_row
         ->check_label('Total for all journals')
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(MAY_BE_BLANK)
         ->check_blank
         ->check_blank
         ->check_blank
         ->check_count_by_periods(Biblio::COUNTER::Report::REQUESTS)
         ->check_ytd_total(Biblio::COUNTER::Report::REQUESTS)
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
         ->check_label('Full-text Turnaways', qr/^(?i)turnaways/)
         ->check_count_by_periods(Biblio::COUNTER::Report::REQUESTS)
         ->check_ytd_total
         ->end_row;
}

1;

=pod

=head1 NAME

Biblio::COUNTER::Report::Release2::JournalReport2 - a JR2 (R2) COUNTER report

=head1 SYNOPSIS

    $report = Biblio::COUNTER::Report::Release2::JournalReport2->new(
        'file' => $file,
    );
    $report->process;

=cut
