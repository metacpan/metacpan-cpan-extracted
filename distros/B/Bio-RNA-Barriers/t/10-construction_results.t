#!perl -T
use 5.012;
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Test::Exception;
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $test_count = 7;
plan tests => $test_count + 1;            # +1 for Test::NoWarnings

use Bio::RNA::Barriers;

# These should live
my $barfile_bsize           = catfile qw(t data with_bsize.bar);
my $barfile_saddle          = catfile qw(t data with_saddle.bar);
my $barfile_bsize_saddle    = catfile qw(t data with_bsize_saddle.bar);
my $barfile_without_bsize   = catfile qw(t data without_bsize.bar);

# These should die
my $barfile_invalid_saddle1 = catfile qw(t data with_invalid_saddle1.bar);
my $barfile_invalid_saddle2 = catfile qw(t data with_invalid_saddle2.bar);
my $barfile_invalid_father  = catfile qw(t data with_invalid_father.bar);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_construction_dies {
    my ($barfile, $descript) = @_;
    # Open input data file and check it worked
    open my $barfh, '<', $barfile
        or BAIL_OUT "failed to open test data file '$barfile'";

    dies_ok { Bio::RNA::Barriers::Results->new($barfh) }
            "results contruction: $descript dies";
}

sub test_construction_lives {
    my ($barfile, $descript) = @_;
    # Open input data file and check it worked
    open my $barfh, '<', $barfile
        or BAIL_OUT "failed to open test data file '$barfile'";

    lives_ok { Bio::RNA::Barriers::Results->new($barfh) }
             "results contruction: $descript lives";
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_construction_lives $barfile_bsize,           'with_bsize';
test_construction_lives $barfile_saddle,          'with_saddle';
test_construction_lives $barfile_bsize_saddle,    'with_bsize_saddle';
test_construction_lives $barfile_without_bsize,   'without_bsize';

test_construction_dies  $barfile_invalid_saddle1, 'with_invalid_saddle1';
test_construction_dies  $barfile_invalid_saddle2, 'with_invalid_saddle2';
test_construction_dies  $barfile_invalid_father,  'with_invalid_father';

exit 0;

