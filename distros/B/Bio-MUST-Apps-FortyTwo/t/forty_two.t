#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Config::Any;
use Path::Class qw(file);

use Bio::MUST::Apps::FortyTwo;

my $class = 'Bio::MUST::Apps::FortyTwo';

SKIP: {
    skip q{Cannot test without NCBI-BLAST!}, 12 unless qx{which blastp};

    check_forty('nuc-simple');
    check_forty('prot-simple');
    check_forty('prot-tax');
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

    # use ft as factory for run_proc object
    my $rp = $ft->run_proc;
    # my $rp = $ft->run_proc( { threads => 2 } );

    compare_ok(
        file('test/MSAs/', "EOG700KXR-my-42-$variant.ali"),
        file('test/MSAs/', "EOG700KXR-42-$variant.ali"),
            "wrote expected Ali for: EOG700KXR (-$variant)"
    );

    compare_ok(
        file('test/MSAs/', "EOG700KXZ-my-42-$variant.ali"),
        file('test/MSAs/', "EOG700KXZ-42-$variant.ali"),
            "wrote expected Ali for: EOG700KXZ (-$variant)"
    );

    compare_filter_ok(
        file('test/MSAs/', "EOG700KXR-my-42-$variant.tax-report"),
        file('test/MSAs/', "EOG700KXR-42-$variant.tax-report"), \&filter,
            "wrote expected TaxReport for: EOG700KXR (-$variant)"
    );

    compare_filter_ok(
        file('test/MSAs/', "EOG700KXZ-my-42-$variant.tax-report"),
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
