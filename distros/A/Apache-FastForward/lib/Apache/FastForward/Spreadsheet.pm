package Apache::FastForward::Spreadsheet;
# Copyright 2006 Jerzy Wachowiak

use strict;
use warnings;
use Carp; 
use Text::CSV_XS;
 
use vars qw( $VERSION );
$VERSION = '1.01'; 

# Perl tie methods: DELETE, CLEAR, EXISTS, FIRSTKEY, NEXTKEY, 
# SCALAR, UNTIE, DESTROY  are not implemented as the package 
# mimics a spreadsheet array of array behaviour

sub TIEHASH {

    my $class = shift;
    my $self = {};
    $self->{VERSION} = $VERSION;
    $self->{template} = []; 
    bless ( $self, $class );
    return $self 
}

sub LoadTemplate {
  
#Contract: 
#   [1] Path to a CSV file and CSV parameters as input
#   [2] Method can either suceed (true) or everything dies...

    my $self  = shift;
    my $path = shift;
    my $csv_atrributes = shift;

    defined( $csv_atrributes ) or 
     croak 'Missing CSV parameters for spreadsheet template';
    my $csv = Text::CSV_XS->new( $csv_atrributes );
        
    open( TEMPLATE, '< '.$path ) or 
     croak "Spreadsheet template $path -> $!";
    while ( defined( my $line = <TEMPLATE> ) ){
        $csv->parse( $line ) or
         croak "Spreadsheet template $path -> The file cannot be parsed";
        push( @{ $self->{template} }, [ $csv->fields() ] );
    }
    close( TEMPLATE )    
}

sub FETCH {

#Contract: 
#   [1] ('A12') spreadsheet address or row & column number eg ('12,1') as input
#   [2] Cell value or undef if adresse does not exist

   my $self = shift;
   my $cell_address = shift;
   
   my $coordinate = convert_spreadsheet_address( $cell_address );
   
   return $self->{template}->[$coordinate->{x}][$coordinate->{y}]   
}

sub STORE {

#Contract: 
#   [1] ('A12') spreadsheet address or row & column number eg ('12,1') as input
#   [2] Method can only suceed as array can always be expanded...

   my $self = shift;
   my $cell_address = shift;
   my $cell_value = shift;
   
   my $coordinate = convert_spreadsheet_address( $cell_address );
   
   $self->{template}->[$coordinate->{x}][$coordinate->{y}] = $cell_value
}


sub DumpAsCSV {

#Contract: 
#	[1] CSV file parameters as input
#   [2] Method can return result string or everything dies...

    my $self  = shift;
    my $csv_atrributes = shift;

    defined( $csv_atrributes ) or 
     croak 'Missing CSV parameters for spreadsheet template';
    my $csv = Text::CSV_XS->new( $csv_atrributes );
    
    my $csv_string = '';
    foreach my $row ( @{$self->{template}} ){
        if ( $csv->combine( @$row ) ){
            $csv_string .= $csv->string()."\n";
        }
        else{
            croak 'The spreadsheet cannot be dumped for value '.$csv->error_input();    
        }
    }
    return $csv_string
}

sub ShiftRow {

#Contract: 
#   [1] No input
#   [2] Similar to shift @ARRAY
#   [3] Returns shifted row

    my $self = shift;
    my $row_number = shift;
    
    return @{ shift( @{$self->{template}} ) }    
}

sub PopRow {
  
#Contract: 
#   [1] No input
#   [2] Similar to pop @ARRAY
#   [3] Returns poped row

    my $self = shift;
    my $row_number = shift;
    
    return @{ pop( @{$self->{template}} ) }  
}

sub PushRow{

#Contract: 
#   [1] Array as input
#   [2] Similar to push @ARRAY
#   [3] Returns the new number of elements in the spreadsheet

    my $self = shift;
    my @cell_values = @_;
    
    push( @{$self->{template}}, [@cell_values] );
  
    return scalar( @{$self->{template}} )
}

sub GetRow {

#Contract: 
#   [1] Row number as input
#   [2] Returns array of cell values
    
    my $self = shift;
    my $row_number = shift;
    
    if ( $row_number < 1 ){
	        croak "Row number '$row_number' is out of range"
    }    
    if ( $row_number > scalar( @{$self->{template}} ) ){
        croak  "Row number '$row_number' is out of this spreadsheet"
    }
    
    my $x = $row_number - 1;
    return @{$self->{template}->[$x]}  
}

sub SetRow {

#Contract: 
#   [1] Row number and array as input
#   [2] Returns nothing
    
    my $self = shift;
    my $row_number = shift;
    my @cell_values = @_;
    
    if ( $row_number < 1 ){
	        croak "Row number '$row_number' is out of range"
    }
    if ( $row_number > scalar( @{$self->{template}} ) ){
        croak  "Row number '$row_number' is out of this spreadsheet"
    }
    
    my $x = $row_number - 1;
    $self->{template}->[$x] = \@cell_values
}

sub RemoveRow {

#Contract: 
#   [1] Row number as input
#   [2] Returns removed row as array   

    my $self = shift;
    my $row_number = shift;
    
    if ( $row_number < 1 ){
	        croak "Row number '$row_number' is out of range"
    }
    if ( $row_number > scalar( @{$self->{template}} ) ){
        croak  "Row number '$row_number' is out of this spreadsheet"
    }
    
    my $x = $row_number - 1;
    
    return @{ splice( @{$self->{template}}, $x, 1 ) }
}

sub RowCount {

#Contract: 
#   [1] Returns the number of elements in the spreadsheet
    
    my $self = shift;
    
    return scalar( @{$self->{template}} )    
}

sub CopySheetTo{

#Contract: 
#   [1] Name of the 'SpreadSheet' tied pointer to hash as input
#   [2] Method succeeds or everything dies ...

    my $self = shift;
    my $new_sheet = shift;
    
    @{$new_sheet->{template}} = @{$self->{template}};
    foreach my $row ( @{$new_sheet->{template}} ){
        $row = [ @$row ] 
    } 
}

sub convert_spreadsheet_address {

#Contract: 
#   [1] ('A12') spreadsheet address or row & column number eg ('12,1') as input
#   [2] Method returns hash with keys {x} and {y} or or everything dies...
    
    my $address = shift;
    
    $address = uc( $address );
    
    if ( $address =~  /^\s*([0-9]+)\s*\,\s*([0-9]+)\s*$/ ){
	    my $row_number = $1;
	    my $column_number = $2;
	    
	    if ( $row_number < 1 ){
	        croak "Row number in cell address '$address' is out of range"
	    }
	    if ( $column_number < 1 ){
	        croak "Column number in cell address '$address' is out of range"
	    }
	    return { x => ( $row_number -1 ), y => ( $column_number -1 ) }	    
    }
    
    if ( $address =~  /^\s*([A-Z]+)\s*([0-9]+)\s*$/ ){
	    my $column_AAA = $1;
	    my $row_number = $2;
        
        if ( $row_number < 1 ){
	        croak "Row number in cell address '$address' is out of range"
	    }
        
        my $column_number = 0;
        while( $column_AAA =~ s/^([A-Z])// ){
	        $column_number = 26 * $column_number + 1 + ord ($1) - ord ("A");
        }
        if ( $column_number < 1 ){
	        croak "Column number in cell address '$address' is out of range"
	    }
        return { x => ( $row_number -1 ), y => ( $column_number -1 ) }
    }
    croak "Cell address '$address' has wrong format"
}
1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

Apache::FastForward::Spreadsheet 

=head1 SYNOPSIS

 my $t1 = tie my %t1, 'Spreadsheet';
 
 my %csv_atr = (
        'quote_char'  => '"',
        'escape_char' => '"',
        'sep_char'    => ';',
        'binary'      => 1 );
 
 $t1->LoadTemplate( './t1.csv', \%csv_atr);
 
 $t1{'A3'} = 'BZDYL';
 print $t1{'3,1'};
 print $t1->DumpAsCSV( \%csv_atr );
 print $t2->RowCount(), "\n";
 
 my $t2 = tie my %t2, 'Spreadsheet';
 $t1->CopySheetTo( $t2 );

 my @row = ( 1, 2, 3 );
 $t2->SetRow( 1, @row );
 @row = $t2->GetRow( 1 );
 my $new_spreadsheet_size = St2->PushRow( @row );
 @row = $t2->PopRow();
 @row = $t2->RemoveRow( 2 );

=head1 DESCRIPTION


=head2 USAGE

The module should be used for manipulating CSV data structures as if it would be
a spreadsheet. Spreadsheet address in a form eg ('A12') or row and column number eg ('12,1')
can be used for data access.


=head2 METHODS

=over

=item LoadTemplate ( $csv_file_path, \%csv_attributes )

Path to a CSV file and CSV parameters (see L<Text::CSV_XS>) as input.
Method can either suceed or everything dies...

=item DumpAsCSV( \%csv_attributes )

CSV file parameters as input. Method can return CSV string or everything
dies...

=item CopySheetTo( $another_sheet )

Name of the 'SpreadSheet' tied pointer to hash as input. Method succeeds or everything dies ... 

=item ShiftRow( )

No input. Similar to 'shift @ARRAY'. Returns shifted row.


=item PopRow( )

No input. Similar to 'pop @ARRAY'. Returns poped row.

=item PushRow( @new_cell_values )

Array as input. Similar to 'push @ARRAY'. Returns the new number of elements
in the array.

=item GetRow( $row_number )

Row number as input. Returns array of cell values.

=item SetRow( $row_number, @@new_cell_values )

Row number and array as input. Returns nothing.

=item RemoveRow( $row_number )

Row number as input. Returns removed row as array.

=item RowCount( )

No input. Returns the number of elements in the spreadsheet.

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.

=head1 SEE ALSO

L<Apache::FastForward>

=over
