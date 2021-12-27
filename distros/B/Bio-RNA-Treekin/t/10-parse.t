#!perl -T
use 5.012;
use warnings;

use Test::More;
use Test::Exception;            # for lives_ok(), dies_ok()
use Test::NoWarnings;           # produces one additional test!
use File::Spec::Functions qw(catfile);
use Bio::RNA::Treekin;

plan tests => 3;


##############################################################################
##                                Input data                                ##
##############################################################################

my $treekin_single_small = catfile qw(t data treekin_single_small.kin);
my $treekin_multi_small  = catfile qw(t data treekin_multi_small.kin);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub test_construction_lives {
    my ($treekin_file, $descript) = @_;
    # Open input data file and check it worked
    open my $treekin_fh, '<', $treekin_file
        or BAIL_OUT "failed to open test data file '$treekin_file'";

    lives_ok { Bio::RNA::Treekin::Record->new($treekin_fh) }
            "results contruction: $descript lives";
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_construction_lives $treekin_single_small,      'single_small';
test_construction_lives $treekin_multi_small,       'multi_small';


exit 0;                             # EOF
