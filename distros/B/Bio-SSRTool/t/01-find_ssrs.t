use strict;
use FindBin '$Bin';
use File::Spec::Functions;
use Test::More tests => 7;
use Test::Exports;

my @should_be = (
    {
        'seq_length'  => 141,
        'num_repeats' => '8',
        'sequence'    => 'seq1-1',
        'end'         => 36,
        'start'       => 21,
        'motif'       => 'ct'
    },
    {
        'seq_length'  => 141,
        'num_repeats' => '6',
        'sequence'    => 'seq1-2',
        'end'         => 71,
        'start'       => 54,
        'motif'       => 'cat'
    },
    {
        'seq_length'  => 134,
        'num_repeats' => '6',
        'sequence'    => 'seq2-1',
        'end'         => 70,
        'start'       => 59,
        'motif'       => 'tc'
    },
    {
        'seq_length'  => 134,
        'num_repeats' => '6',
        'sequence'    => 'seq2-2',
        'end'         => 126,
        'start'       => 103,
        'motif'       => 'actc'
    }
);
    
require_ok 'Bio::SSRTool' or BAIL_OUT "can't load module";

import_ok 'Bio::SSRTool', [ 'find_ssr' ], 'default import OK';

is_import qw/find_ssr/, 'Bio::SSRTool', 'imports subs';

use_ok('Bio::SSRTool');

my $file = catfile( $Bin, 'data', 'input.txt' );

my $text;
{
    open my $fh, '<', $file or die "Can't read '$file': $!\n";
    $text = join '', <$fh>;
    close $fh;
}

open my $fh, '<', $file or die "Can't read '$file': $!\n";;

for my $input ( $file, $text, $fh ) {
    my @ssrs = find_ssr( $input, { motif_length => 4, min_repeats => 5 } );

    is_deeply( \@ssrs, \@should_be, 'SSRs parsed correctly' );
}

