#!perl -T
use 5.012;
use warnings;
use autodie ':all';

use Test::More;
use Test::NoWarnings;            # produces one additional test!
use Digest::CRC qw(crc32);
use File::Spec::Functions qw(catfile);
use Bio::RNA::Treekin;
use Scalar::Util qw(reftype);
use File::Slurp qw(read_file);

plan tests => 3;


##############################################################################
##                                Input data                                ##
##############################################################################

my $treekin_single_small = catfile qw(t data treekin_single_small.kin);
my $treekin_multi_small  = catfile qw(t data treekin_multi_small.kin);


##############################################################################
##                              Test functions                              ##
##############################################################################

sub separator {
    my ($message) = @_;
    $message = "  $message  ";
    my $total_width = 78;           # separator width in chars
    my $dash_count = int(  ($total_width-length($message)) / 2  );

    my $separator = '-' x $dash_count . $message . '-' x $dash_count . "\n";
    return $separator;
}

sub print_difference {
    my ($string1, $string2) = @_;

    my @lines1 = split /^/m, $string1;
    my @lines2 = split /^/m, $string2;
    my $len = @lines1 < @lines2 ? $#lines2 : $#lines1;

    # Print out first differing lines
    for my $i (0..$len) {
        next if $lines1[$i] eq $lines2[$i];

        # Mark leading / trailing white space.
        s/^(\s)* /$1_/g, s/ (\s)*$/_$1/g, s/^(\s)*\t/$1>___/g, s/\t(\s)*$/>___$1/g,
            foreach $lines1[$i], $lines2[$i];

        diag( 'First diffence in line ' . ($i+1) . ":\n",
              separator('First file:'),
              $lines1[$i],
              separator('Second file:'),
              $lines2[$i],
              separator('End'),
        );
        last;
    }
}


# For SINGLE Treekin records.
# Test whether stringification of Treekin record equals original file content.
sub test_stringify_single_eq {
    my ($treekin_file, $descript) = @_;

    my $treekin_file_content = read_file $treekin_file;
    open my $treekin_handle, '<', \$treekin_file_content;

    my $record = Bio::RNA::Treekin::Record->new($treekin_handle);

    # Remove trailing spaces for comparison. The are removed by BarMap in the
    # MultiVersion and thus not contained in the stringified version -_-
    $treekin_file_content =~ s{ \s+ $ }{}gxm;
    is(crc32("$record"), crc32($treekin_file_content), "stringify $descript")
        or print_difference "$record", $treekin_file_content;
}


# For MULTI Treekin records.
sub test_stringify_multi_eq {
    my ($treekin_file, $descript) = @_;

    my $treekin_file_content = read_file $treekin_file;
    open my $treekin_handle, '<', \$treekin_file_content;

    # Read all Treekin records from multi-record file.
    my $record_iter = Bio::RNA::Treekin::MultiRecord->new($treekin_handle);
    my @records;
    while (my $record = $record_iter->next()) {
            push @records, $record;
    }

    # Join stringified records. End with a separator.
    my $record_separator  = "\n&\n";
    my $treekin_stringified = join $record_separator,
                                   map {"$_"} @records, q{};

    # Compare content.
    is(crc32($treekin_stringified), crc32($treekin_file_content), "stringify $descript")
        or print_difference $treekin_stringified, $treekin_file_content;
}

##############################################################################
##                                Call tests                                ##
##############################################################################

test_stringify_single_eq $treekin_single_small, 'single small';
test_stringify_multi_eq  $treekin_multi_small,  'multi small';

exit 0;                             # EOF
