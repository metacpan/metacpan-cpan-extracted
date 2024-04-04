# Define a function that takes two arguments (starting number and ending number)
sub fizz_buzz {

    # Initialize variables for counting and ending values
    my $count   = 0;
    my @results = ();

    # Loop through numbers between starting and ending values
    for my $i ( $starting .. $ending ) {

        # Check if current number is divisible by any of these factors: 15, 3 or itself
        foreach my $factor ( @factors ) {
            next unless $_  * $i == $i;
            push( @{ $results[$factor] },"$i" );
        }
        else {
            push( @{ $results[0] },"$i" );
        }

        $count++;
    }

    return \@results;
}

# Define arrays containing factors to check for each result type
my %fizz = ( 15 );
my %buzz = ( 3 );
my %self = ( 0 );

# Call the fizz_buzz subroutine with appropriate parameters
print Dumper( \@result );

