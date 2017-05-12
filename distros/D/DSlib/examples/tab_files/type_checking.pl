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
use DS::Transformer::Sub;
use DS::TypeSpec;
use DS::TypeSpec::Any;

my $period_split_type = new DS::TypeSpec([ 'period' ]);

my $period_split_transformer = new DS::Transformer::Sub(
    sub {
        my( $self, $row ) = @_;
        @$row{ qw{ year month } } = $row->{period} =~ /(\d+)M(\d+)/ if( $row );
        return $row;
    },
    $period_split_type,
    $DS::TypeSpec::Any
);

my $printer  = new DS::Transformer::TabStreamWriter( new_from_fd IO::Handle(fileno(STDOUT), 'w') );
$printer->include_header;

my $importer = new DS::Importer::TabFile( "$Bin/pets.csv" );
$importer->attach_target( $period_split_transformer );
$period_split_transformer->attach_target( $printer );
$printer->attach_target( new DS::Target::Sink );

# This will read the input file and process everything.
$importer->execute();
