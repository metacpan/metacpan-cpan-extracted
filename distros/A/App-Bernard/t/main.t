use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Slurp;
use Cwd;
use Test::More;

die "Please run this test from the top of the distribution.\n"
    unless -e "t";

sub read_file_without_date {
    my ($filename) = @_;

    my $result = read_file($filename);

    $result =~ s/PO-Revision-Date: [0-9: -]*/PO-Revision-Date: redacted/;
    return $result;
}

sub compare {
    my ($left, $right, $name) = @_;

    my @left = split(/\n/, read_file_without_date($left));
    my @right = split(/\n/, read_file_without_date($right));

    is_deeply(\@left, \@right,
	      $name);
}

# Firstly, count the number of files in subdirs
# whose name begins with "output".  This is the
# number of tests.

my $testcount = 0;

for my $subdir (glob("t/*")) {
    next unless -d $subdir;

    for my $file (glob("$subdir/output*")) {
	$testcount++;
    }
}

plan tests => $testcount;

my $cwd = getcwd();
my $script = "$cwd/script/bernard";
my $lib = "$cwd/lib";

for my $subdir (sort glob("t/*")) {
    next unless -d $subdir;

    my $testname = $subdir;
    $testname =~ s!^t/!!;
    $testname =~ s/_/ /g;

    my $tempdir = tempdir(CLEANUP => 1);

    for my $input (glob("$subdir/input-*")) {
	$input =~ /input-(.*)$/;
	write_file("$tempdir/$1",
		   read_file($input));
    }

    my $args = read_file("$subdir/command");

    chdir($tempdir);

    open OUT, ">$tempdir/stdout"
	or die "Couldn't open stdout dump: $!";
    open BERNARD, "perl -I$lib $script $args|"
	or die "Couldn't open script: $!";
    while (<BERNARD>) {
	print OUT $_;
    }
    close BERNARD
	or die "Couldn't close script: $!";
    close OUT
	or die "Couldn't close stdout dump: $!";

    chdir($cwd);

    for my $left (glob("$subdir/output*")) {
	$left =~ /output-(.*)$/;
	my $right = "$tempdir/$1";

	compare($left, $right, "$testname - $1");
    }

}
