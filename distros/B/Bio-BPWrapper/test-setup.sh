# Common test setup code.
# Tests for BioPerl,

min_bp_version=1.006


if [[ $0 == ${BASH_SOURCE[0]} ]] ; then
    echo "This script should be *sourced* rather than run directly through bash"
    exit 1
fi

testStart=`date`;
echo "testing start: $testStart.";
echo "----------";

# Set min_bp_version if it hasn't been set before
bmin_bp_version=${min_bp_vrsion:1.006}

#----------------------------
# Check where bp-utils are
#----------------------------
testDir=`dirname ${BASH_SOURCE[0]}`
if ! cd $testDir; then echo "Stop: check if $testDir exist" >&2; exit 1; fi;

binDir=$testDir/bin
BIOALN=${binDir}/bioaln
BIOTREE=${binDir}/biotree
BIOSEQ=${binDir}/bioseq

#-----------------------------
# Test existence of BioPerl
#-----------------------------
echo -ne "Testing if BioPerl is installed: ...";
if perldoc -l Bio::Perl > /dev/null; then
    echo " ... Great, bioperl found!"
else
    echo "Stop: please install bioperl modules before using this utility" >&2
    exit 1;
fi

bp_version=$(perl -MBio::Root::Version -e 'print $Bio::Root::Version::VERSION');
if_true=$(echo "$bp_version > 1.006" | bc);
if [ $if_true -ne 1 ]; then
    echo "Warning: Your BioPerl version ($bp_version) may be old (< $min_bp_version) and some functions may fail."
else
    echo "Great, your BioPerl version ($bp_version) is compatible."
fi;
