# Everything should be in an explicit package
package main;

# Safeguards against common errors
use strict;
use warnings;

# Easy way to point to modules relative to script location
use FindBin qw { $Bin };
use lib "$Bin/../../lib";

# Load various modules from DS
use DS::Importer::TabFile;
use DS::Transformer::TabStreamWriter;
use DS::Target::Sink;
use DS::Transformer::Stack;
use DS::Transformer::Grep;

# Prepare a transformer stack
my $stack = new DS::Transformer::Stack;

$stack->push_transformer( 
    new DS::Transformer::Grep ( 
        sub {
            my( $self, $row ) = @_; 
            return $row->{period} =~ /M06/;
        } 
    )
);

my $printer  = new DS::Transformer::TabStreamWriter( new_from_fd IO::Handle(fileno(STDOUT), 'w') );
$printer->include_header;
$stack->push_transformer( $printer );

my $importer = new DS::Importer::TabFile( "$Bin/price_index.csv" );
$stack->attach_source( $importer );
$stack->attach_target( new DS::Target::Sink );

# This will read the input file and process everything.
$importer->execute();
