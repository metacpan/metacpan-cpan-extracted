package AAA::eBay;

use strict;
use warnings;
use Apache::Constants qw( :common );
use Apache::FastForward;
use Apache::FastForward::Spreadsheet;
use Net::eBay;
use Socket;

# This fakes some catalogue numbers and internal registration&mapping of eBay-IDs
my %books = (   'L1B215' =>{ ebay_id => '110019678243', titel => 'Blood Meridian : Or the Evening Redness in the West by Cormac Mccarthy', price => 5, quantity => 5 },
		'L1B226' =>{ ebay_id => '110019678242', titel => 'As I Lay Dying  by William Faulkner', price => 10, quantity => 3 },
		'L1B237' =>{ ebay_id => '110019678245', titel => 'The Great Gatsby by F. Scott Fitzgerald', price => 7, quantity => 10 },
		'L1B311' =>{ ebay_id => '110019678241', titel => 'The Portrait of a Lady  by Henry James', price => 9, quantity => 3 },
		'L1B119' =>{ ebay_id => '110019678192', titel => 'The Adventures of Huckleberry Finn  by Mark Twain', price => 5, quantity => 15 });

sub handler {
    
    my $r = Apache::FastForward->new( shift );

    $r->send_http_header( 'text/plain' );

    # Template initialisation
    my $sheet = tie my %sheet, 'Apache::FastForward::Spreadsheet';
    my %csv_atr = (
        'quote_char'  => '"',
        'escape_char' => '"',
        'sep_char'    => ';',
        'binary'      => 1 );
    
     
    $sheet->LoadTemplate( '/var/www/ebay/FF4eBay-tmpl--v4.csv', \%csv_atr);

    # If IP numbers in a sheet are used (eg for testing with VMware and/or dhcp) 
    # it can spare updating the template each time a dhcp lease ends
    my $c = $r->connection();
    my $local_addr = $c->local_addr();
    my ($local_port, $local_ip) = Socket::sockaddr_in( $local_addr );
    $local_ip = Socket::inet_ntoa( $local_ip );
    $sheet{'B1'} = 'http://'.$local_ip.'/ebay';
    
    # The Start of Everything ~{;-)
    $r->ParseBody();
    
    # Is the right table inside?
    unless ( $r->IsDefinedTable( 'item', 'check' ) ){

	    print $sheet->DumpAsCSV( \%csv_atr );
	    return OK
    }

    # Are the values in the tabel within of a correct range?
    my @item_check_table = $r->GetTable( 'item', 'check' );
    my $system_message = '***';
    foreach my $row ( @item_check_table ){

	    unless ( defined( $books{$row->{item}} ) or $row->{item} eq ''){
	        $system_message .= ' The item "'.$row->{item}.'" does not exist '.'***'
	    }
    }

    unless ( $system_message =~ /^\*\*\*$/ ){

	$sheet{'C12'} = $system_message;
        print $sheet->DumpAsCSV( \%csv_atr );
	
	return OK
    }
    
    # Downloading the eBay prices...
    
    # eBay-API access expiration: 2008-10-25 07:29:01
    my $eBay = new Net::eBay( {
                              SiteLevel => 'dev',
                              DeveloperKey => 'K5C16E838BG13GLOPFFKU966JFK12D',
                              ApplicationKey => 'JERZYWACHOH4S5X99K418JJ1298BH8',
                              CertificateKey => 'T48W813V3EK$SM4AE2VE1-RD3AY168',
                              Token => 'AgAAAA**AQAAAA**aAAAAA**veA6Rg**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wFk4CnDJCAoQ6dj6x9nY+seQ**uK0AAA**AAMAAA**ftgjtxOWDHk4YDlxQFfmJM6YZOmUvW4+IFi1fFQGBOuFQqibA6vL48n82pgxD0R3gY4e/Y7Ry5H6P6IDMOX8Obr8JW2XQ/KM47WUPiJ199M+saJvo52TEnC5Le9lglQEW7ETQHdygLINz6vrYm49mT+tLaw7qA4TSOGxarbGYUJb+rFuLodHG+s90skJa0/wSBI0Xbr/Gqx0OK3OKRnP4U50QABeAEiSP0QCXsuJuBtfdvD74AAZ+KDtrrFEjYOuJIwQn6c+YKXfa3Q09Mk2tzs20+yq10dN8fRHebqbS/QLDRHkkMIYbUw7aFE5i/0aiobUYdwfeYWMGGPVx5vP2dkn5zw5xw4ouz23CfN1oZIJHLTcJs1xt/HYNx+WoLUuUBHuqE+Q/Sm/DxwzffZ47t6wXVBZe2QyuKWvU4j0vP+k47Iau9ZCYayIJ56DwbKVvB2vOAAY8vr8RNrQLR7GZJ1Zcfq1q9HBphQ+KArHXJxoRq5hw0WSjP+47emVEPY7wOSzUsW3gAFU37DMB4lptnlC0XCauJeMSJPFS7NKKf1OBPyJ8n2e4kgfMuQu09K2CGypJjrk/1PBHWmQ/BY62n/IPLGhzTHT3VGJiZXSKTkGQf2R1wzfVEq+m3Dq5kjqm8L0SNo/QX8NzsGdYHBBRzxD0lcZHwvlQuZmXzNp0KlGwzxRJgbPwiwLX++u7cCtNgR6b0GUfEMeXG5hNSUIEiHIEjUdcRJ6hKmVR7Q5upKzBqIJsZLfWzLUU6K/ZzjV',
                             } );

    $eBay->setDefaults( { API => 2 } );

    my $result = $eBay->submitRequest( "GetSellerTransactions",
                                     {
                                      ModTimeFrom => '2007-05-18T00:00:00.463Z',
				      ModTimeTo => '2007-05-19T00:00:00.463Z'
                                     }
                                   );

    my %ebay_transaction_price;
    foreach my $transaction ( @{$result->{TransactionArray}->{Transaction}} ){
	
	$transaction->{TransactionPrice}->{content} =~ s/\./,/;
	$ebay_transaction_price{$transaction->{Item}->{ItemID}} = $transaction->{TransactionPrice}->{content}
    }
    
    # Filling the report...
    my $first_row_number = 23; 

    my $row_number = $first_row_number;
    foreach my $row ( @item_check_table ){
	    if ( $row->{check} ne '' ){
	        my $item = $row->{item};
	        my $titel = $books{$item}->{titel};
	        my $price = $books{$item}->{price};
	        my $ebay_id = $books{$item}->{ebay_id};
		my $quantity = $books{$item}->{quantity};
		my $ebay_price = $ebay_transaction_price{$ebay_id};
		
	        $sheet{"B$row_number"} = $ebay_id;
	        $sheet{"C$row_number"} = $titel;
	        $sheet{"D$row_number"} = $quantity;
	        $sheet{"E$row_number"} = $price;
		$sheet{"F$row_number"} = $ebay_price;
	        
	        $row_number++	        
	    }
    }
    
    # OO Calc Formula can be sent down if the parameter ALLOW_FORMULAS is set to True in OO Calc ...
    my $last_row_number = $row_number-1;
    
    $sheet{'C17'} = "=SUM(G$first_row_number:G$last_row_number)";
    $sheet{'C18'} = "=SUM(H$first_row_number:H$last_row_number)";
    $sheet{'C19'} = '=C18-C17'; 
    
    print $sheet->DumpAsCSV( \%csv_atr );
    return OK
}
1

