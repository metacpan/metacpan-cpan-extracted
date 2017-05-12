#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say);

use Bio::Taxonomy::GlobalNames;

# Initialize the query object.
my $query = Bio::Taxonomy::GlobalNames->new(
    file            => 'names.dat',
    data_source_ids => '12',          # Use the EOL source.
    resolve_once    => 'true',
    with_context    => 'true',
);

my $output = $query->post();

# Print the results in an output file.
open my $output_fh, '>', './scientific_names.csv';

# Print the first line of the csv file.
say {$output_fh}
  '"Scientific_Name","Source","Local_ID","Score","Supplied_Name"';

# Parse the results.
foreach ( @{ $output->data } )
{

    # If a result was found...
    if ( $_->results->[0] )
    {

        # Get the fields that were found in the hit...
        foreach my $result ( @{ $_->results } )
        {
            my $scientific_name = $result->name_string;
            my $source          = $result->data_source_id;
            my $local_id        = $result->local_id;
            my $score           = $result->score;
            my $supplied_name   = $_->supplied_name_string;

            # ... and add them to the csv file.
            print {$output_fh} << "END";
"$scientific_name","$source","$local_id","$score","$supplied_name"
END
        }
    }
}

close $output_fh;
