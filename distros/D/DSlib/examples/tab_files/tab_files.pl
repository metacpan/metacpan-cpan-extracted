# Everything should be in an explicit package
package main;

# Safeguards against common errors
use strict;
use warnings;

# Easy way to point to modules relative to script location
use FindBin qw { $Bin };
use lib "$Bin/../../lib";

use IO::Handle;

# Load various modules from DS
use DS::Importer::TabFile;
use DS::Transformer::TabStreamWriter;
use DS::Target::Sink;

my $importer = new DS::Importer::TabFile( "$Bin/price_index.csv" );
my $printer  = new DS::Transformer::TabStreamWriter( new_from_fd IO::Handle(fileno(STDOUT), 'w') );
$printer->include_header;

$importer->attach_target( $printer );
$printer->attach_target( new DS::Target::Sink );

$importer->execute();
