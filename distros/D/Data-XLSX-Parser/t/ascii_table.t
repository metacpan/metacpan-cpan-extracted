#!/usr/bin/perl

use strict;
use warnings;

use Data::XLSX::Parser;
use Test::More;

my $error;
eval {
    require Text::ASCIITable;
    1;
} or $error++;

SKIP: {
    skip 'Text::ASCIITable not installed', 2 if $error;
    
    # get names of all sheets in the workbook
    my @rows;
    
    my $xlsx_parser = Data::XLSX::Parser->new;
    $xlsx_parser->add_row_event_handler( sub{
        push @rows, $_[0];
    });
    
    (my $file = __FILE__) =~ s{\.t$}{.xlsx};

    $xlsx_parser->open( $file );
    my @names = $xlsx_parser->workbook->names;

    my $output = '';
    
    for my $name ( @names ) {
        $output .= "Table $name:\n";
    
        my $table = Text::ASCIITable->new;
        my $rid   = $xlsx_parser->workbook->sheet_rid( $name );
        $xlsx_parser->sheet_by_rid( $rid );
    
        my $headers = shift @rows;
        $table->setCols( @{ $headers || [] } );
    
        for my $row ( @rows ) {
            $table->addRow( @{ $row || [] } );
        }
        
        $output .= $table . "\n";
    
        @rows = ();
    }

    like $output, qr/Hugo/;
    like $output, qr/Network/;
}

done_testing();
