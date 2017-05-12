#!perl 
use warnings;
use strict;

#use Test::More tests => 1;
use Test::More qw(no_plan);
use File::Temp qw/ tempfile /;

unless( $ENV{AUTHOR_TESTING} ) {
    ok( 1, "skipping tests, \$ENV{AUTHOR_TESTING} not set" );
    exit( 0 );
}
# sample text to operate on.
my $matrix_3x3 = "1 2 3\n4 5 6\n7 8 9\n";   # 3x3 matrix
my $matrix_3tri = "a b c\nd e\nf\n";        # 3x3 triangular matrix
my $name_data = 
"Bob Elmer, 2716 Fremont Blvd, New York, NY, 12344, ID:91818, CanastaRating:3.1415
Elmer Fudd, 1 Bunny Hill Drive, Tarrytown, NY, 87654, ID:1, CanastaRating:123456789\n";

my @tests = (
    # input         # command line     # expected output,   # optional name 
   [ $matrix_3x3,   "1 2",             "1 2\n4 5\n7 8\n", ],
   [ $matrix_3x3,   "-x 1 2",          "3\n6\n9\n", ],
   [ $matrix_3x3,   "-99",             "\n\n\n", ],
   [ $matrix_3x3,   "-x -99",          $matrix_3x3 ],
   [ $matrix_3x3,   "1 2 -99",         "1 2\n4 5\n7 8\n", ],
   [ $matrix_3x3,   "1 2 0",           "1 2\n4 5\n7 8\n", ],
   [ $matrix_3x3,   "-1 -2",           "3 2\n6 5\n9 8\n", ],
   [ $matrix_3x3,   "2..3",            "2 3\n5 6\n8 9\n", ],
   [ $matrix_3x3,   "-x 2..3",         "1\n4\n7\n", ],

   [ $matrix_3tri,  "1 2",             "a b\nd e\nf\n",   ],
   [ $matrix_3tri,  "-2",              "b\nd\n\n",     ],
   [ $matrix_3tri,  "1..99",           $matrix_3tri,   ],
   [ $matrix_3tri,  "-x -99..99",      "\n\n\n",   ],
   [ $matrix_3tri,  "-99..-1",         $matrix_3tri,   ],
   [ $matrix_3tri,  "-99..99",         $matrix_3tri,   ],
   [ $matrix_3tri,  "-1..-99",         "c b a\ne d\nf\n"  ],
   [ $matrix_3tri,  "1 3 99 -111",     "a c\nd\nf\n"  ],
   [ $matrix_3tri,  "-x 1 3 99 -111",  "b\ne\n\n"  ],

   [ $name_data,    "-d ', ' -j ', ' 1 -2",    "Bob Elmer, ID:91818\nElmer Fudd, ID:1\n", ]
);

for my $test (@tests) {
    my ($input, $args, $expected, $name) = @$test;
    $name ||= "test(args '$args' on '" . describe_file( $input ) . "')...";

    # write the contents of $input to a temporary file
    my ($fh, $filename) = tempfile();
    print $fh $input;

    # build and run the command, collecting output
    my $cmd = "perl bin/jawk $args -- $filename";
    my $result = join("", btick( $cmd ) );

    cmp_ok( $result, "eq", $expected, $name );
    unlink( $filename );
}

#################################rrrr#######
# my $line = describe_file( $input )
# returns the max of the two
sub describe_file {
    my $t = shift;
    my (@parts) = split( /\n/, $t, 2 ); # only two parts
    my $output =  $parts[0];
    #my $output = join( '\n', @lines ) . '\n';
    my $max = 20;
    if (length($output) > $max) {
        $output = substr($output, 0, $max - 3) . "...";
    }
    return $output;
}

# my $output =- btick()
# runs the commands from @_ (using the actual backtick operator),
# joins all the output together into one scalar, and returns it.
sub btick {
    my $cmd = join(" ", @_ );
    #print "Running: $cmd\n";
    my @ret = `$cmd`;
    return join("", @ret);
}
1;
