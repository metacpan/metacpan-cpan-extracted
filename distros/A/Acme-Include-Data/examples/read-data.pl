my $data = __FILE__;

# Make whatever substitutions are necessary:

$data =~ s/Data\.pm$/this-is-a-data-file.txt/;

# Read the data in:

open my $in, "<", $data or die $!;
my $text = '';
while (<$in>) {
    $text .= $_;
}

