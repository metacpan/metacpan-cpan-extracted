package Data::XLSX::Parser;
use strict;
use warnings;

our $VERSION = '0.20';

use Data::XLSX::Parser::DocumentArchive;
use Data::XLSX::Parser::Workbook;
use Data::XLSX::Parser::SharedStrings;
use Data::XLSX::Parser::Styles;
use Data::XLSX::Parser::Sheet;
use Data::XLSX::Parser::Relationships;
use Carp;

my $workbook_schema = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet';

sub new {
    my ($class) = @_;

    bless {
        _row_event_handler => [],
        _archive           => undef,
        _workbook          => undef,
        _shared_strings    => undef,
        _relationships    => undef,
    }, $class;
}

sub add_row_event_handler {
    my ($self, $handler) = @_;
    croak ("no sub reference given in argument!") unless $handler;
    push @{ $self->{_row_event_handler} }, $handler;
}

sub open {
    my ($self, $file) = @_;
    croak ("no file path given in argument!") unless $file;
    $self->{_archive} = Data::XLSX::Parser::DocumentArchive->new($file);
}

sub workbook {
    my ($self) = @_;
    $self->{_workbook} ||= Data::XLSX::Parser::Workbook->new($self->{_archive});
}

sub shared_strings {
    my ($self) = @_;
    $self->{_shared_strings} ||= Data::XLSX::Parser::SharedStrings->new($self->{_archive});
}

sub styles {
    my ($self) = @_;
    $self->{_styles} ||= Data::XLSX::Parser::Styles->new($self->{_archive});
}

sub relationships {
    my ($self) = @_;
    $self->{_relationships} ||= Data::XLSX::Parser::Relationships->new($self->{_archive});
}

sub sheet_by_id {
    my ($self, $sheet_id) = @_;
    croak ("no sheet_id given in argument!") unless $sheet_id;
    $self->{_sheet}->{$sheet_id} ||= Data::XLSX::Parser::Sheet->new($self, $self->{_archive}, $sheet_id);
}

sub sheet_by_rid {
    my ($self, $rid) = @_;
    croak ("no sheet relation id given in argument!") unless $rid;
    my $relation = $self->relationships->relation($rid);
    unless ($relation) {
        return;
    }
    if ($relation->{Type} eq $workbook_schema) {
        my $target = $relation->{Target};
        $self->{_sheet}->{$rid} ||=
            Data::XLSX::Parser::Sheet->new($self, $self->{_archive}, $target);
    }
}

sub _row_event {
    my ($self, $row) = @_;

    my $row_vals = [map { $_->{v} } @$row];
    for my $handler (@{ $self->{_row_event_handler} }) {
        $handler->($row_vals, $row);
    }
}
1;

__END__

=head1 NAME

Data::XLSX::Parser - faster XLSX parser

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Data::XLSX::Parser provides a fast way to parse Microsoft Excel's .xlsx files.
The implementation of this module is highly inspired from Python's FastXLSX library.

The module uses a SAX based parser, so you can parse very large XLSX file with lower memory usage.

=head1 METHODS

=head2 new

Create new parser object.

=head2 add_row_event_handler

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

=head2 open

Open a workbook to be parsed.

=head2 sheet_by_id

Start parsing of sheet identified by sheet Id.

=head2 sheet_by_rid

Start parsing of sheet identified by sheet relation Id.

=head2 workbook

returns the Data::XLSX::Parser::Workbook object (representation of xl/workbook.xml, used to get sheets).

=head2 shared_strings

returns the Data::XLSX::Parser::SharedStrings object (representation of xl/sharedStrings.xml).

=head2 styles

returns the Data::XLSX::Parser::Styles object (representation of xl/styles.xml).

=head2 relationships

returns the Data::XLSX::Parser::Relationships object (representation of xl/_rels/workbook.xml.rels).

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
