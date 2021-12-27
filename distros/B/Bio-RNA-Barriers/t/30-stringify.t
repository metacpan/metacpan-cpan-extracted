#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use File::Spec::Functions;

plan tests => 4 + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

my $barfile_with_bsize        = catfile qw(t data with_bsize.bar);
my $barfile_with_saddle       = catfile qw(t data with_saddle.bar);
my $barfile_with_bsize_saddle = catfile qw(t data with_bsize_saddle.bar);
my $barfile_without_bsize     = catfile qw(t data without_bsize.bar);

run_tests( $barfile_with_bsize,        'with_bsize'        );
run_tests( $barfile_with_saddle,       'with_saddle'       );
run_tests( $barfile_with_bsize_saddle, 'with_bsize_saddle' );
run_tests( $barfile_without_bsize,     'without_bsize'     );

# Run actual tests.
sub run_tests {   # has_bsize == true
    my ($barfile, $descript) = @_;
    # Open input data file and check it worked
    open my $barfh,    '<', $barfile
        or BAIL_OUT "failed to open test data file '$barfile'";

    my $bar = Bio::RNA::Barriers::Results->new($barfh);
    seek $barfh, 0, 0;                  # reset file pointer position
    my @barfile_lines = <$barfh>;
    chomp @barfile_lines;

    subtest "stringification: $descript" => sub {
        my $supposed_min_count = @barfile_lines - 1;
        plan tests => 2 * $supposed_min_count + 2;

        foreach my $i (1..$bar->min_count) {
            my $min = $bar->get_min($i);
            is $bar->get_min($i)->stringify,
               "$min",
               "stringify() overloading of $descript min $i"
               ;
            is $bar->get_min($i)->stringify,
               $barfile_lines[$i],
               "stringify() of $descript min $i"
               ;
        }

        # Whole bar file.
        is $bar->stringify,
           "$bar",
           "stringify() overloading of full $descript results"
           ;
        is $bar->stringify,
           join("\n", @barfile_lines),
           "stringify() of full $descript results"
           ;
   };
}
