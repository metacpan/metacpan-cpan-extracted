#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Config::Any;
use Const::Fast;
use Path::Class qw(file);

use Bio::MUST::Apps::FortyTwo;


const my $EXO_VAR => 'BMA_TEST_EXON';
# const my $CAP_VAR => 'BMA_TEST_CAP3';

my $class = 'Bio::MUST::Apps::FortyTwo';

SKIP: {
#   skip q{Cannot test without NCBI-BLAST!}, 20 unless qx{which blastp};
    skip q{Cannot test without NCBI-BLAST!}, 16 unless qx{which blastp};

    check_forty('nuc-simple');
    check_forty('prot-simple');
    check_forty('prot-tax');

    SKIP: {
        skip <<"EOT", 4 unless $ENV{$EXO_VAR};
exonerate-based tests!
These tests require exonerate version 2.2.0 (not the newer version 2.4.0).
To enable them use:
\$ $EXO_VAR=1 make test
EOT
        check_forty('nuc-exo');
    }

# TODO: test CAP3? (but current test files cannot trigger its use)
#   SKIP: {
#         skip <<"EOT", 4 unless $ENV{$CAP_VAR};
# CAP3-based tests!
# These tests require CAP3.
# To enable them use:
# \$ $CAP_VAR=1 make test
# EOT
#         check_forty('nuc-cap');
#   }
}


sub check_forty {
    my $variant = shift;

    explain $variant;

    # read configuration file
    my $config_file = file('test/', "config-42-$variant.yaml")->stringify;
    my $config = Config::Any->load_files( {
        files           => [ $config_file ],
        flatten_to_hash => 1,
        use_ext         => 1,
    } );

    # build ft object
    my $ft = $class->new(
        config  => $config->{$config_file},
        infiles => [
            file('test/MSAs/', "EOG700KXR.ali")->stringify,
            file('test/MSAs/', "EOG700KXZ.ali")->stringify,
        ],
    );

    # clean-up pre-existing outfiles
    my $outfile1 = file('test/MSAs/', "EOG700KXR-my-42-$variant.ali");
    my $outfile2 = file('test/MSAs/', "EOG700KXZ-my-42-$variant.ali");
    my $outfile3 = file('test/MSAs/', "EOG700KXR-my-42-$variant.tax-report");
    my $outfile4 = file('test/MSAs/', "EOG700KXZ-my-42-$variant.tax-report");
    ( file($outfile1) )->remove if -e $outfile1;
    ( file($outfile2) )->remove if -e $outfile2;
    ( file($outfile3) )->remove if -e $outfile3;
    ( file($outfile4) )->remove if -e $outfile4;

    # use ft as factory for run_proc object
    my $rp = $ft->run_proc;
    # my $rp = $ft->run_proc( { threads => 2 } );
    # my $rp = $ft->run_proc( { out_dir => '/Users/denis/custom_outdir' } );
    # my $rp = $ft->run_proc( { out_dir => 'custom_outdir' } );

    # check outfiles
    compare_ok(
        $outfile1,
        file('test/MSAs/', "EOG700KXR-42-$variant.ali"),
            "wrote expected Ali for: EOG700KXR (-$variant)"
    );

    compare_ok(
        $outfile2,
        file('test/MSAs/', "EOG700KXZ-42-$variant.ali"),
            "wrote expected Ali for: EOG700KXZ (-$variant)"
    );

    compare_filter_ok(
        $outfile3,
        file('test/MSAs/', "EOG700KXR-42-$variant.tax-report"), \&filter,
            "wrote expected TaxReport for: EOG700KXR (-$variant)"
    );

    compare_filter_ok(
        $outfile4,
        file('test/MSAs/', "EOG700KXZ-42-$variant.tax-report"), \&filter,
            "wrote expected TaxReport for: EOG700KXZ (-$variant)"
    );
}

sub filter {
    my $line = shift;

    # TODO
    # check if we need to change anything here

    return $line;
}

done_testing;
