use strict;
use warnings;
use Test::More;
use Text::AutoCSV;

BEGIN { use_ok('Text::AutoCSV'); }
BEGIN { use_ok('CSV::Processor'); }

use Data::Dumper;

subtest "add_email numbered params" => sub {

    my $sample_file = 't/samples/addresses.csv';
    my $col_in      = 1;
    my $col_out     = 2;
    my $test_out    = 'your@email.com';

    my ( @csv1, @csv2 );
    Text::AutoCSV->new(
        in_file   => $sample_file,
        walker_ar => sub { push @csv1, shift; }
    )->read();

    no warnings 'redefine';
    local *Email::Extractor::search_until_attempts = sub { return [$test_out] };

    my $bot = CSV::Processor->new( file => $sample_file );
    $bot->add_email( $col_in, $col_out );

    Text::AutoCSV->new(
        in_file   => 't/samples/p_addresses.csv',
        walker_ar => sub { push @csv2, shift; }
    )->read();

    is scalar @csv1, scalar @csv2, 'add_email leave number of rows same';

    for my $i ( 0 .. $#csv2 ) {
        is $csv2[$i][$col_out], $test_out, "row $i out fine";
        splice @{ $csv2[$i] }, $col_out, 1;
    }

    is_deeply \@csv1, \@csv2, 'Original data untouched';

    unlink 't/samples/p_addresses.csv';
};

done_testing;
