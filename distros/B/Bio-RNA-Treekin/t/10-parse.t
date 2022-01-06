#!perl -T
use 5.012;
use warnings;

use Test::More;
use Test::Exception;            # for lives_ok(), dies_ok()
use Test::NoWarnings;           # produces one additional test!
use File::Spec::Functions qw(catfile);
use Bio::RNA::Treekin;

plan tests => 1 + 4;


##############################################################################
##                                Input data                                ##
##############################################################################

my $treekin_single_small     = catfile qw(t data treekin_single_small.kin);
my $treekin_single_small_new = catfile qw(t data treekin_single_small_new.kin);
my $treekin_multi_small      = catfile qw(t data treekin_multi_small.kin);


##############################################################################
##                              Test functions                              ##
##############################################################################

# Open input Treekin file and check if it worked. Bail out if not.
sub get_handle {
    my ($treekin_file) = @_;

    open my $treekin_fh, '<', $treekin_file
        or BAIL_OUT "failed to open test data file '$treekin_file'";

    return $treekin_fh;
}

sub test_construction_single_lives {
    my ($treekin_file, $descript) = @_;
    my $treekin_fh = get_handle $treekin_file;
    lives_ok { Bio::RNA::Treekin::Record->new($treekin_fh) }
             "single results contruction: $descript lives";
}

sub test_construction_single_dies {
    my ($treekin_file, $descript) = @_;
    my $treekin_fh = get_handle $treekin_file;
    dies_ok { Bio::RNA::Treekin::Record->new($treekin_fh) }
             "single results contruction: $descript dies";
}

sub test_construction_multi_lives {
    my ($treekin_file, $descript) = @_;
    my $treekin_fh = get_handle $treekin_file;
    lives_ok { Bio::RNA::Treekin::MultiRecord->new($treekin_fh) }
             "multi results contruction: $descript lives";
}


##############################################################################
##                                Call tests                                ##
##############################################################################

test_construction_single_lives $treekin_single_small,     'single_small';
test_construction_single_lives $treekin_single_small_new, 'single_small_new';
test_construction_single_dies  $treekin_multi_small,      'multi_small';
test_construction_multi_lives  $treekin_multi_small,      'multi_small';


exit 0;                             # EOF
