package Business::ReportWriter;

use strict;
use POSIX qw(setlocale LC_NUMERIC);

sub new {
    my ( $class, %parms ) = @_;

    my $self = {};
    $self = bless $self, $class;

    return $self;
}

sub process_report {
    my ( $self, $outfile, $report, $head, $list ) = @_;

    my %report = %$report;
    my @list   = @$list;
    push @list, {} if $#list < 1;

# Setting up the report hash with user's configuration
    $self->init_report( $report{report} );
    $self->init_page_header( $report{page}{header} );
    $self->init_body( $report{body} );
    $self->init_graphics( $report{graphics} );
    $self->init_logos( $report{page}{logo} );
    $self->init_breaks( $report{breaks} );
    $self->init_fields( $report{fields} );
    $self->print_list( \@list, \%$head );

    return $outfile ? $self->print_doc($outfile) : $self->get_doc;
}

sub init_report {
    my ( $self, $parms ) = @_;

    $self->{report} = $parms;
}

sub init_page_header {
    my ( $self, $parms ) = @_;
    $self->{report}{page} = $parms;
}

sub init_body {
    my ( $self, $parms ) = @_;

    $self->{report}{body} = $parms;
}

sub init_graphics {
    my ( $self, $parms ) = @_;

    $self->{report}{graphics} = $parms;
}

sub init_logos {
    my ( $self, $parms ) = @_;

    $self->{report}{logo} = $parms;
}

sub init_fields {
    my ( $self, $parms ) = @_;

    $self->{report}{fields} = $parms;
}

sub init_breaks {
    my ( $self, $parms ) = @_;

    $self->{report}{breaks} = $parms;
    my @breakorder;
    for ( keys %$parms ) {
        $breakorder[ $parms->{$_}{order} ] = $_;
    }
    $self->{report}{breaks}{_order} = [@breakorder];
}

# Report writing
sub begin_break {
}

sub begin_line {
}

sub begin_field {
}

sub make_field_headers {
    my ( $self, $fh ) = @_;

    if ( $fh->{show} ne 'off' ) {
        for ( @{ $self->{report}{fields} } ) {
            $self->out_field( $_->{text}, $_, $fh );
        }
    }
}

sub out_field {
}

sub break_fields {
    my ( $self, $break_name, $tot ) = @_;

    my $name = $tot->{name};
    my $rec  = $self->{totals}{$break_name};

    $self->process_field( $tot, $rec );
    $self->{totals}{$break_name}{$name} = 0;
}

sub process_break {
    my ( $self, $break_name ) = @_;

    my $p = $self->{pdf};

    my $break = $self->{report}{breaks}{$break_name};
    $self->begin_line($break);

    if ( defined( $break->{total} ) ) {
        foreach my $tot ( @{ $break->{total} } ) {
            $self->break_fields( $break_name, $tot );
        }
    }
}

sub print_break_header {
    my ( $self, $rec, $break_name ) = @_;

    my $p     = $self->{pdf};
    my $break = $self->{report}{breaks}{$break_name};

    $self->begin_break( $rec, $break );
    $self->begin_line( $rec, $break->{header} );
    for my $bh ( @{ $break->{header}{text} } ) {
        $self->process_field( $bh, $rec );
    }

    $self->begin_line( $rec, $break->{header}{FieldHeaders} );
    $self->make_field_headers( $break->{header}{FieldHeaders} );
}

sub print_break {
    my $self = shift;

    for my $break_name ( @{ $self->{report}{breaks}{_order} } ) {
        my $self_break = $self->{breaks}{$break_name} || '';
        if ( $self_break eq '_break' ) {
            $self->process_break($break_name);
        }
    }
}

sub process_field {
    my ( $self, $fld, $rec ) = @_;

    return
        if ( defined( $fld->{depends} )
        && !eval( $self->make_text( $rec, $fld->{depends} ) ) );
    my $text =
        defined( $fld->{function} )
        ? $self->make_func( $rec, $fld->{function} )
        : $self->make_text( $rec, $fld->{text} );
    $self->out_field( $text, $fld ) if $text;
}

sub make_fieldtext {
    my ( $self, $rec, $text ) = @_;

    my @fields = ( $text =~ /(\w*)/g );
    for my $field (@fields) {
        $text =~ s/$field/$rec->{$field}/eg;
    }

    return $text;
}

sub process_linefield {
    my ( $self, $fld, $rec ) = @_;

    return
        if ( defined( $fld->{depends} )
        && !eval( $self->make_text( $rec, $fld->{depends} ) ) );

    $self->begin_field($fld);
    my $text =
        defined( $fld->{function} )
        ? $self->make_func( $rec, $fld->{function} )
        : $self->make_fieldtext( $rec, $fld->{name} );
    $self->out_field( $text, $fld ) if $text;
}

sub out_textarray {
    my ( $self, $fld, $rec ) = @_;

    for ( @{ $rec->{ $fld->{name} } } ) {
        $self->begin_field($fld);
        $self->out_field( $_, $fld ) if $_;
    }
}

sub print_line {
    my ( $self, $rec ) = @_;

    $self->begin_line($rec);
    for ( @{ $self->{report}{fields} } ) {
        $self->out_textarray( $_, $rec ), next
            if lc( $_->{fieldtype} ) eq 'textarray';
        $self->process_linefield( $_, $rec );
    }
}

sub sum_totals {
    my ($self, $rec) = @_;

    for my $break ( @{ $self->{report}{breaks}{_order} } ) {
        if ( defined( $self->{report}{breaks}{$break}{total} ) ) {
            foreach my $tot ( @{ $self->{report}{breaks}{$break}{total} } ) {
                my $name = $tot->{name};
                $self->{totals}{$break}{$name} += $rec->{$name};
            }
        }
    }
}

sub check_for_break {
    my ($self, $rec, $last) = @_;

    my $brk = '';
    for my $break ( reverse @{ $self->{report}{breaks}{_order} } ) {
        my $self_break = $self->{breaks}{$break} || '';
        my $rec_break  = $rec->{$break}          || '';
        if ( ( $last && !( $break eq '_page' ) )
            || $self_break ne $rec_break )
        {
            $brk = '_break';
        }
        $self->{breaks}{$break} = $brk if $brk;
    }
}

sub save_breaks {
    my $self = shift;

    my ( $rec, $first ) = @_;
    for my $break ( reverse @{ $self->{report}{breaks}{_order} } ) {
        my $self_break = $self->{breaks}{$break} || '';
        my $rec_break  = $rec->{$break}          || '';
        $self->print_break_header( $rec, $break )
            if ( $first and $break ne '_total' and $break ne '_page' )
            || $self_break ne $rec_break;
        $self->{breaks}{$break} = $rec->{$break};
    }
}

sub process_totals {
    my ($self, $rec) = @_;

    my $first = ( !defined( $self->{started} ) );
    $self->{started} = 1;
    my $last = ( ref $rec ne 'HASH' );
    $self->print_totals($rec) if !$first;
    $self->save_breaks( $rec, $first ) if !$last;
    $self->sum_totals($rec) if !$last;
}

sub begin_list {
}

sub check_page {
}

sub print_list {
    my ( $self, $list, $page ) = @_;

    my @list = @$list;
    $self->{pageData} = $page;

    $self->begin_list;

    foreach my $rec (@list) {
        $self->check_page;
        $self->process_totals($rec);
        $self->print_line($rec);
    }
    $self->end_print();
}

sub print_totals {
    my ( $self, $rec ) = @_;

    my $last = ( ref $rec ne 'HASH' );
    $self->check_for_break( $rec, $last );
    $self->print_break();
}

sub end_print {
    my $self = shift;

    $self->process_totals();
}

# Support

sub make_text {
    my ( $self, $rec, $text ) = @_;

    my @fields = ( $text =~ /\$(\w*)/g );
    for my $field (@fields) {
        $text =~ s/\$$field/$rec->{$field}/eg;
    }
    return $text;
}

sub make_func {
    my ( $self, $rec, $func ) = @_;

    my @fields = ( $func =~ /\$(\w*)/g );
    for my $field (@fields) {
        $func =~ s/\$$field/\$rec->{$field}/g;
    }

    my $text;
    setlocale( LC_NUMERIC, $self->{report}{locale} );
    eval( '$text = ' . $func );
    setlocale( LC_NUMERIC, "C" );
    return $text;
}

1;
__END__

=head1 NAME

Business::ReportWriter - A Business Oriented ReportWriter.

=head1 SYNOPSIS

  use Business::ReportWriter::Pdf;

  my $rw = new Business::ReportWriter::Pdf();
  $rw->process_report($outfile, $report, $head, $list);

=head1 DESCRIPTION

Business::ReportWriter is a tool to make a Business Report from an array of
data.  The report output is generated based on a XML description of the report.

The report is written to a file.

=head2 Method calls

=over 4

=item $obj = new()

Creates a Report Writer Object.

=item $obj->process_report($outfile, $report, $head, $list)

Creates a PDF Report and writes it to the file named in $outfile. 

$report is a hash reference to the Report Definition.
$head is a hash containing external data (also called Page Data).
$list is a reference to the array that contains the report data.

=back

=head2 Data Description

=head3 report

A hash reference describing the wanted output. Contains these sections:

=over 4

=item report

=back

Hash with report wide information. Possible entries: 

I<locale> - eg us_EN, da_DK...

I<papersize> - A4, Letter...

=head3 breaks
 
A hash defining the line breaks / report totals. Hash key is the name of
the field to totl, pointing to a new hash containing 

I<order> Sort order of break, starting from 0. Must be unique.

I<font> Font used for the break line. Font is a hash containing face and size.

I<format> printf-like format string.

I<text> Print text for the total line. Any word beginning with a $ character
will be replaced with the corresponding field name.

I<xpos> Horisontal position of the text.

I<total> Array telling which fields are to be totalled.

There are two special break names:


I<_page> will result in a total for each page and _total will give a grand
total at the end of the report.

=head3 fields
 
Array of hashes describing all fields in the body area of the report.
Each element can contain 

I<font> Same as in the breaks section.

I<name> Field name - corresponds to the hash in the Data List.

I<text> Same as in the breaks section.

I<xpos> Same as in the breaks section.

I<align> Alignment of field. Possible values are left, center, right.

I<format> Same as in the breaks section.

I<function> A perl function to replace the field as output. Any word beginning
with a $ character will be replaced by a field.

I<depends> A perl expression. If true, the field will be printed, if false it
will not. Any word beginning with a $ character will be replaced by a field.

=head3 page
 
Hash describing the report outside the body area. Entries are 

I<header> - a hash describing the header. There can be a font entry and then
there's an array containing text elements, each of which can contain depends,
function, text, align, xpos and ypos. These elements do what you'd expect
them to. sameline will allow you to skip xpos and let it inherit ypos from
the previous entry- very useful if there is a depends entry.

I<logo> Telling where to find the logo and where to place it.

Contains a hash with key logo including an array with image descriptions.
Name is the file name including path information, x an y gives upper left corner
and scale indicates which factor to scale the image with.

=head3 body
 
A hash describing the body area (where the report list will go). Contains 

I<font> (well known by now), ypos telling upper edge of the body and heigth

=head3 graphics
 
A hash entry with key width telling line width and a hash with key boxes
containing an array describing ``line graphics'' or boxes. Each box is
defined with the values topx, topy, bottomx and bottomy. 

=head2 Page Data

A hash reference to data that can be used in the page region of the report.
B<pagenr> is automatically included and updated.

=head2 List Data

Array of hash. Each array element represents one line in the final report.
The hash keys can be referenced in the report definition.

=head1 SEE ALSO

 Business::ReportWriter::OOCalc, Business::ReportWriter::Pdf 

=head1 COPYRIGHT

Copyright (C) 2003-2006 Kaare Rasmussen. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kar at jasonic.dk>
