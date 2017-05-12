use strict;
use warnings;

use Path::Tiny;
use Test::More;
use Test::FailWarnings;
use Text::CSV;

use Data::Decimate qw(decimate);

my $data = datas_from_csv('t/sampledata.csv');

subtest "decimate" => sub {

    my $output = Data::Decimate::decimate(15, $data);

    is scalar(@$output), '10', "decimated data";

    is $output->[0]->{epoch}, '1479203114', "epoch is correct";

};

$data = datas_from_csv('t/sampledata2.csv');

subtest "decimate_with_missing_data" => sub {

    my $output = Data::Decimate::decimate(15, $data);

    is scalar(@$output), '10', "decimated data";

    is $output->[0]->{epoch}, '1479203114', "epoch is correct";

};

sub datas_from_csv {
    my $filename = shift;

    open(my $fh, '<:utf8', $filename) or die "Can't open $filename: $!";

# skip to the header
    my $header = '';
    while (<$fh>) {
        if (/^symbol,/x) {
            $header = $_;
            last;
        }
    }

    my $csv = Text::CSV->new or die "Text::CSV error: " . Text::CSV->error_diag;

# define column names
    $csv->parse($header);
    $csv->column_names([$csv->fields]);

    my @datas;

# parse the rest
    while (my $row = $csv->getline_hr($fh)) {
        push @datas, $row;
    }

    $csv->eof or $csv->error_diag;
    close $fh;

    return \@datas;
}

done_testing;
