# NAME

Data::XLSX::Parser - faster XLSX parser

# SYNOPSIS

    use Data::Dumper;
    use Data::XLSX::Parser;
    
    my $parser = Data::XLSX::Parser->new;
    $parser->add_row_event_handler(sub {
        my ($row, $rowDetail) = @_;
        # array of cell values in parsed row
        print Dumper $row;
        # array of hashes with cell details (reference, value, column, row, style, etc.) in parsed row
        print Dumper $rowDetail;
    });
    $parser->open('foo.xlsx');
    
    # parse sheet with sheet name
    $parser->sheet_by_rid( $parser->workbook->sheet_rid( 'Sheet1' ) );
    
    # .. or parse sheet with sheet Id
    $parser->sheet_by_id(1);
    
    # -----------
    # print values of all sheets on the commandline
    use Text::ASCIITable;
    
    # get names of all sheets in the workbook
    my @rows;
    
    my $xlsx_parser = Data::XLSX::Parser->new;
    $xlsx_parser->add_row_event_handler( sub{
        push @rows, $_[0];
    });
    
    $xlsx_parser->open( 'test.xlsx' );
    my @names = $xlsx_parser->workbook->names;
    
    for my $name ( @names ) {
        say "Table $name:";
    
        my $table = Text::ASCIITable->new;
        my $rid   = $xlsx_parser->workbook->sheet_id( $name );
        $xlsx_parser->sheet_by_rid( $rid );
    
        my $headers = shift @rows;
        $table->setCols( @{ $headers || [] } );
    
        for my $row ( @rows ) {
            $table->addRow( @{ $row || [] } );
        }
        
        print $table;
    
        @rows = ();
    }

# DESCRIPTION

Data::XLSX::Parser provides a fast way to parse Microsoft Excel's .xlsx files.
The implementation of this module is highly inspired from Python's FastXLSX library.

The module uses a SAX based parser, so you can parse very large XLSX file with lower memory usage.

# METHODS

## new

Create new parser object.

## add\_row\_event\_handler

Add sub reference to row handler. Two arguments are returned, the first is an array with the cell values of the parsed row, the second is an array of hashes with the details of the parsed row cells:

    |key |Content  
    -------------------------
    | i  |STYLE_INDEX        
    | s  |STYLE OF CELL      
    | f  |FORMAT OF CELL     
    | r  |REFERENCE          
    | c  |COLUMN OF CELL     
    | v  |VALUE OF CELL      
    | t  |TYPE OF CELL       
    | s  |TYPE_SHARED_STRING 
    | g  |GENERATED_CELL     
    | row|ROW OF CELL        

Cell values are returned 'as is', except date values (where the format tag indicates this) are converted to epoch values.

## open

Open a workbook to be parsed.

## sheet\_by\_id

Start parsing of sheet identified by sheet Id.

## sheet\_by\_rid

Start parsing of sheet identified by sheet relation Id.

## workbook

returns the Data::XLSX::Parser::Workbook object (representation of xl/workbook.xml, used to get sheets).

## shared\_strings

returns the Data::XLSX::Parser::SharedStrings object (representation of xl/sharedStrings.xml).

## styles

returns the Data::XLSX::Parser::Styles object (representation of xl/styles.xml).

## relationships

returns the Data::XLSX::Parser::Relationships object (representation of xl/\_rels/workbook.xml.rels).

# AUTHOR

Daisuke Murase <typester@cpan.org>
