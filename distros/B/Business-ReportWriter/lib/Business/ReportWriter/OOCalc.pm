package Business::ReportWriter::OOCalc;

use strict;
use POSIX qw(setlocale LC_NUMERIC);
use utf8;
use OpenOffice::OOCBuilder;

use base 'Business::ReportWriter';

sub begin_line {
    my ( $self, $rec ) = @_;

    $self->{rownr}++;
    $self->{fieldnr} = 0;
}

sub out_field {
    my ( $self, $text, $field ) = @_;

    $self->{fieldnr}++;
    $self->out_text($text);
}

sub begin_list {
    my ($self) = @_;

    my $sheet = OpenOffice::OOCBuilder->new();
    $self->{sheet} = $sheet;
}

sub print_doc {
    my ( $self, $filename ) = @_;

    my $sheet = $self->{sheet};
    if ($filename) {
        $sheet->generate($filename);
    }
}

sub out_text {
    my ( $self, $text ) = @_;

    my $sheet = $self->{sheet};
    $sheet->goto_xy( $self->{fieldnr}, $self->{rownr} );
    utf8::decode($text);
    $sheet->set_data($text);
    print "$self->{rownr} $self->{fieldnr}: $text\n";
}

1;
__END__

=head1 NAME

Business::ReportWriter::OOCalc - A Business Oriented ReportWriter.

=head1 SYNOPSIS

  use Business::ReportWriter::OOCalc;

  my $rw = new Business::ReportWriter::OOCalc();
  $rw->process_report($outfile, $report, $head, $list);

=head1 DESCRIPTION

Business::ReportWriter is a tool to make a Business Report from an array of
data.  The report output is generated based on a XML description of the report.

The report is written to a OpenOffice Calc file.

=head1 SEE ALSO

 Business::ReportWriter

=head1 COPYRIGHT

Copyright (C) 2003-2006 Kaare Rasmussen. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kar at jasonic.dk>
