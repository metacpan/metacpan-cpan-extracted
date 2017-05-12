package Biblio::COUNTER::Report::Release2::DatabaseReport2;

use strict;
use warnings;

use Biblio::COUNTER::Report qw(TURNAWAYS MAY_BE_BLANK NOT_BLANK);

@Biblio::COUNTER::Report::Release2::DatabaseReport2::ISA = qw(Biblio::COUNTER::Report);

sub canonical_report_name { 'Database Report 2 (R2)' }
sub canonical_report_description { 'Turnaways by Month and Database' };
sub canonical_report_code { 'DB2' }
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
         ->check_label('Publisher', qr/^(?i)pub/)
         ->check_label('Platform',  qr/^(?i)plat/)
         ->check_label('Page type', qr/^(?i)page type/)
         ->check_period_labels
         ->check_label('YTD Total')
         ->end_row;
    
    # Data summary
    $self->begin_row
         ->check_label('Total for all databases', qr/(?i)total.+all databases/)
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(MAY_BE_BLANK)
         ->check_blank
         ->check_count_by_periods(TURNAWAYS)
         ->check_ytd_total(TURNAWAYS)
         ->end_row;
}

sub process_record {
    my ($self) = @_;
    $self->begin_row
         ->check_title(NOT_BLANK)
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(NOT_BLANK)
         ->check_label('Database turnaways', qr/^(?i)turnaways/)
         ->check_count_by_periods(TURNAWAYS)
         ->check_ytd_total(TURNAWAYS)
         ->end_row;
}

1;

=pod

=head1 NAME

Biblio::COUNTER::Report::Release2::DatabaseReport2 - a DB2 (R2) COUNTER report

=head1 SYNOPSIS

    $report = Biblio::COUNTER::Report::Release2::DatabaseReport2->new(
        'file' => $file,
    );
    $report->process;

=cut
