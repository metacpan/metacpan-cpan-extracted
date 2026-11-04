use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Text::CSV_XS;

sub run_code {
    open my $pipe, '-|', $^X, '-Ilib', 'bin/clarid-tools', 'code',
      '--entity', 'biosample', '--codebook', 'share/versions/0.04/clarid-codebook.yaml',
      @_ or die "Cannot run clarid-tools: $!";
    my $output = do { local $/; <$pipe> };
    close $pipe;
    is($?, 0, 'CLI succeeds');
    return $output;
}

# Optional columns occur in generated CSV even when a record has no value.
my ($input, $path) = tempfile(UNLINK => 1);
my $csv = Text::CSV_XS->new({binary => 1, eol => "\n"});
$csv->print($input, [qw(unique_id subject_id project species tissue sample_type
                       assay condition timepoint duration batch replicate)]);
my @optional = (['', ''], [' ', "\t"], ['2', ''], ['', '3'], ['0', '0']);
for my $index (0 .. $#optional) {
    $csv->print($input, ["sample$index", 1, 'CNAG-Test', 'Human', 'Blood',
        'Normal', 'WGS', 'C22.0', 'Baseline', 'P0D', @{$optional[$index]}]);
}
close $input;

for my $format (qw(human stub)) {
    subtest "bulk $format optional fields" => sub {
        my $output = run_code('--action', 'encode', '--format', $format,
                              '--infile', $path, '--sep', ',');
        open my $handle, '<', \$output or die "Cannot read CLI output: $!";
        my $reader = Text::CSV_XS->new({binary => 1});
        $reader->getline($handle);
        my $rows = $reader->getline_all($handle);
        my $base = $format eq 'human'
          ? 'CNAG_Test-HomSap-00001-BLO-NOR-WGS-C22.0-BSL-P0D'
          : 'CT01001BNZ0N401B0D';
        my @suffixes = $format eq 'human'
          ? ('', '', '-B02', '-R03', '-B00-R00')
          : ('', '', 'B02', 'R03', 'B00R00');
        is_deeply([map { $_->[-1] } @$rows],
                  [map { $base . $_ } @suffixes],
                  'blank cells are absent; individual values and zero are retained');
    };
}

subtest 'short Not Available species stub' => sub {
    my $output = run_code('--action', 'decode', '--format', 'stub',
                          '--clar_id', 'CTn00hnnnBiR01n0N');
    like($output, qr/^species: Not Available$/m, 'short species token is decoded');
    like($output, qr/^subject_id: 43$/m, 'subject boundary is preserved');
    like($output, qr/^condition: Z00\.0$/m, 'condition is preserved');
};

done_testing();
