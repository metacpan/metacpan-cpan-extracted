package AAA::Demo;

use strict;
use warnings;
use Apache::Constants qw( :common );
use Apache::FastForward;
use Apache::FastForward::Spreadsheet;
use Socket;

my %books = (   '111001' =>{ titel => 'Blood Meridian : Or the Evening Redness in the West by Cormac Mccarthy', price => 67 },
		'111134' =>{ titel => 'As I Lay Dying  by William Faulkner', price => 7 },
		'111267' =>{ titel => 'The Great Gatsby by F. Scott Fitzgerald', price => 2 },
		'111400' =>{ titel => 'The Portrait of a Lady  by Henry James', price => 34 },
		'111533' =>{ titel => 'The Adventures of Huckleberry Finn  by Mark Twain', price => 56 });

sub handler {
    
    my $r = Apache::FastForward->new( shift );

=pod
    # For testing the content of the posted body        
    $r->read( my $rbody, $r->header_in( 'Content-length') );
    print "$rbody\n";
    return OK;
=cut

    
    my $user = $r->user();
    defined( $user ) or $user = 'anonymous';
        
    $r->send_http_header( 'text/plain' );

    # Template initialisation
    my $sheet = tie my %sheet, 'Apache::FastForward::Spreadsheet';
    my %csv_atr = (
        'quote_char'  => '"',
        'escape_char' => '"',
        'sep_char'    => ';',
        'binary'      => 1 );
 
    $sheet->LoadTemplate( '/var/www/demo/books.csv', \%csv_atr);
  
    $r->ParseBody();

    unless ( $r->IsDefinedTable( 'item', 'quantity' ) ){

	    print $sheet->DumpAsCSV( \%csv_atr );
	    
	    return OK
    }

    my @item_quantity_table = $r->GetTable( 'item', 'quantity' );
    
    my $system_message = '***';

    foreach my $row ( @item_quantity_table ){

	    unless ( defined( $books{$row->{item}} ) or $row->{item} eq ''){
	        $system_message .= ' The item "'.$row->{item}.'" does not exist '.'***'
	    }
	    if ( $row->{quantity} eq '' ){ $row->{quantity} = 0 };
    	    unless ( $row->{quantity} =~ /^\d+$/ or $row->{quantity} >= 0 ){
	        $system_message .= 
	        ' The quantity "'.$row->{quantity}.'" for item "'.$row->{item}
	        .'" must be a positive integer '.'***'
	    }
    }


    unless ( $system_message =~ /^\*\*\*$/ ){

        $sheet{'C15'} = $system_message;
        print $sheet->DumpAsCSV( \%csv_atr );
	
	return OK
    }

    my $delivery_mode = 'normal';
    if ( $r->IsDefinedTable( 'delivery' ) ){
	    my @delivery_table = $r->GetTable( 'delivery' );
	    $delivery_mode = shift( @delivery_table )->{delivery};
	    $delivery_mode = 'normal' if  $delivery_mode eq ''
    }

    $sheet{'C17'} = $user;
    $sheet{'C19'} = $delivery_mode;  
    
    my $row_number = 22;
    foreach my $row ( @item_quantity_table ){
	    if ( $row->{quantity} > 0 ){
	        my $item = $row->{item};
	        my $titel = $books{$item}->{titel};
	        my $quantity = $row->{quantity};
	        my $price = $books{$item}->{price};
	        my $value = $price * $quantity;

	        $sheet{"B$row_number"} = $item;
	        $sheet{"C$row_number"} = $titel;
	        $sheet{"D$row_number"} = $quantity;
	        $sheet{"E$row_number"} = $price;
	        $sheet{"F$row_number"} = $value;
	        
	        $row_number++	        
	    }
    }
    print $sheet->DumpAsCSV( \%csv_atr );
    return OK
}
1

