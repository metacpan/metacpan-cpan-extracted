#-*-Perl-*-
## $Id: Primer3.t 15574 2009-02-25 13:49:22Z cjfields $

# tests for Bio::Tools::Run::Primer3Redux
# originally written for Bio::Tools::Run::Primer3 by Rob Edwards

use strict;
use warnings;
use Data::Dumper;
use Bio::Tools::Run::Primer3Redux;
use Bio::SeqIO;

BEGIN {
    use Bio::Root::Test;

    # num tests: see SKIP block for requires_executable
    # + 5 before the block
    test_begin( -tests => 164);

    # this is run in 00-compile.t
    #use_ok('Bio::Tools::Run::Primer3Redux');
}

my $verbose = $ENV{BIOPERLDEBUG} || 0;

# Get sequence for SEQUENCE_TEMPLATE from a fasta file
my ( $seqio, $seq, $primer3, $args, $results, $num_results );
$seqio = Bio::SeqIO->new( -file => test_input_file('Primer3.fa') );
$seq = $seqio->next_seq;

# This is for the thermodynamic parameters. the files in that
# directory are copied from the primer3 source tarball version 2.2.3
my $primer3_config_dir = 't/data/primer3_config/';

# Define sets of parameters and expected results
# note: these are v2 parameters
# !!! When adding a new test, update the number of tests
# to skip in the first SKIP block and in the BEGIN
# block
my @tests = (
  {
      desc       => "pick PCR primers with minimum product size range",
      p3_version => 2,
      params     => {
          'PRIMER_TASK'               => 'pick_pcr_primers',
          'PRIMER_SALT_CORRECTIONS'   => 1,
          'PRIMER_TM_FORMULA'         => 1,
          'PRIMER_PRODUCT_SIZE_RANGE' => '100-250',
          'PRIMER_EXPLAIN_FLAG'       => 1,
      },
      expect => {
          num_pairs => 5,
          loc_pair  => [ 69, 210 ],
      }
  },

  {
      desc =>
        "pick PCR primers with minimum product size range (for primer3 v1)",
      p3_version => 1,
      params     => {
          'PRIMER_TASK'               => 'pick_pcr_primers',
          'PRIMER_SALT_CORRECTIONS'   => 1,
          'PRIMER_PRODUCT_SIZE_RANGE' => '100-250',
          'PRIMER_EXPLAIN_FLAG'       => 1,
      },
      expect => {
          num_pairs => 4,
          loc_pair  => [ 66, 168 ],
      }
  },

  {
      desc       => "make design fail due to very strict constraints",
      p3_version => 2,
      params     => {
          'PRIMER_TASK'           => 'pick_pcr_primers',
          'PRIMER_MAX_POLY_X'     => 3,   # no runs of more than 2 of same nuc
          'PRIMER_MIN_TM'         => 55,
          'PRIMER_MAX_TM'         => 65,
          'PRIMER_PRODUCT_MIN_TM' => 75,
          'PRIMER_PRODUCT_OPT_TM' => 90,
          'PRIMER_PRODUCT_MAX_TM' => 95,
      },
      expect => { num_pairs => 0, }
  },

  {
      desc => "use PRIMER_PAIR_OK_REGION_LIST (new feature in primer3 v2.x)",
      p3_version => 2,
      params     => {
          'PRIMER_TASK'                         => 'pick_pcr_primers',
          'PRIMER_SALT_CORRECTIONS'             => 1,
          'PRIMER_TM_FORMULA'                   => 1,
          'PRIMER_EXPLAIN_FLAG'                 => 1,
          'PRIMER_PRODUCT_MIN_TM'               => 60,
          'PRIMER_PRODUCT_SIZE_RANGE'           => '50-200',
          'SEQUENCE_PRIMER_PAIR_OK_REGION_LIST' => '0,70,140,70',
      },
      expect => {
          num_pairs => 5,
          loc_pair  => [ 17, 210 ],
      }
  },

  {
    desc   => "pick PCR primers but cause warnings and error",
    p3_version => 2,
    params => {
      'PRIMER_TASK'               => 'pick_pcr_primers',
      'PRIMER_SALT_CORRECTIONS'   => 1,
      'PRIMER_TM_FORMULA'         => 1,
      'PRIMER_EXPLAIN_FLAG'       => 1,
      'SEQUENCE_PRIMER'          => 'AAAAAAAAAAAAAAAAAAA', # this is not on the SEQUENCE_TEMPLATE, so will cause error
    },
    expect => {
      errors => 1,
    }
  },

  {
    desc => "check existing primers without a sequence template. The primer ends are fully complementary but this is not picked up in this test because we are not using thermodynamic tests.",
    p3_version => 2,
    run_without_seq_template => 1,
    params => {
      PRIMER_TASK=>'check_primers',
      PRIMER_MIN_TM=>50,
      PRIMER_EXPLAIN_FLAG=>1,
      PRIMER_TM_FORMULA=>1,
      SEQUENCE_PRIMER=>'AGGCTAGGCGAGCTGAAAAATCCTAC',
      SEQUENCE_PRIMER_REVCOMP=>'GTAGGATTTTTCAGTCGAAGGGGCAT',
    },
    expect => {
      num_pairs => 1,
      warnings => 0,
      errors => 0,
    }
  },
  {
    # TODO
    # This input uses thermodynamic parameters to check primers
    # and it should actually reject the primer pair but there
    # seems to be a bug in primer3 and the pair is not rejected
    # despite PRIMER_PAIR_COMPL_ANY_TH > PRIMER_PAIR_MAX_COMPL_ANY_TH
    desc => "check existing primers. Use thermodynamic parameters.",
    p3_version => 2,
    run_without_seq_template => 1,
    params => {
      PRIMER_TASK=>'check_primers',
      PRIMER_MIN_TM=>50,
      PRIMER_EXPLAIN_FLAG=>1,
      PRIMER_TM_FORMULA=>1,
      PRIMER_THERMODYNAMIC_ALIGNMENT=>1,
      PRIMER_THERMODYNAMIC_PARAMETERS_PATH => $primer3_config_dir,
      PRIMER_SALT_CORRECTIONS=>1,
      PRIMER_MAX_HAIRPIN_TH=>47,
      PRIMER_MAX_SELF_ANY_TH=>47,
      PRIMER_MAX_SELF_END_TH=>47,
      PRIMER_PAIR_MAX_COMPL_ANY_TH=>30,
      SEQUENCE_PRIMER=>'AGGCTAGGCGAGCTGAAAAATCCTAC',
      SEQUENCE_PRIMER_REVCOMP=>'GTAGGATTTTTCAGTCGAAGGGGCAT',
    },
    expect => {
      num_pairs => 1,
      warnings => 0,
      errors => 0,
    }
  },
);

ok( $primer3 = Bio::Tools::Run::Primer3Redux->new(), "can instantiate object" );

SKIP: {
    test_skip(
        -tests               => 163,
        -requires_executable => $primer3,
    );

    like( $primer3->program_name, qr/primer3/, 'program_name' );
    my $major_version;
    if ( $primer3->version && $primer3->version =~ /^(\d+)/ ) {
        $major_version = $1;
        if ( $major_version < 2 ) {
            diag('++++++++++++++++++++++++++++++++++++++++++');
            diag("+ Using primer3 version $major_version.x");
            diag('+ Some features may not work well.      ');
            diag('+ It is recommended to update to primer3');
            diag('+ verion 2.0 or later.                  ');
            diag('++++++++++++++++++++++++++++++++++++++++++');
        }
    }

    # now run the individual tests for each block in the
    # @tests array.
    foreach my $test (@tests) {
        diag( 'Test parameter set for: ' . $test->{desc} ) if $verbose;
        ok( $primer3 = Bio::Tools::Run::Primer3Redux->new() );
        my $required_version = $test->{p3_version} || 0;
        SKIP: {
            skip( "tests for primer3 major version $required_version", 1 )
              if $required_version != $major_version;

            # This tests the new API with dedicated run methods
            # for each primer task, so remove PRIMER_TASK from params
            my $primer_task = delete $test->{params}{PRIMER_TASK};
            $primer3->set_parameters( %{ $test->{params} } );
            my $parser;
            if ($test->{run_without_seq_template} ){
              ok( $parser = $primer3->$primer_task(), "Can run primer3 using method '$primer_task' and no Bio::Seq object" );
            } else {
              ok( $parser = $primer3->$primer_task($seq), "Can run primer3 using method '$primer_task'" );
            }

            while ( my $result = $parser->next_result ) {
    #diag Dumper $result;
                isa_ok( $result, 'Bio::Tools::Primer3Redux::Result' );
                my $expect_warnings = $test->{expect}{warnings};
                SKIP:{
                  skip ("test warnings if expectation defined",1) if !defined $expect_warnings;
                  is ($result->warnings, $expect_warnings, "got the expected number of primer design warnings");
                }
                my $expect_errors = $test->{expect}{errors};
                SKIP:{
                  skip ("test errors if expectation defined",1) if !defined $expect_errors;
                    is ($result->errors, $expect_errors, "got the expected number of primer design errors");
                }
                my $num_pairs = $test->{expect}{num_pairs};
                is( $result->num_primer_pairs, $num_pairs,
                    "Got expected number of pairs: " . (defined($num_pairs) ?  $num_pairs : 'undef') );
                my $ps = $result->get_processed_seq;
                isa_ok( $ps, 'Bio::Seq' );

                SKIP: {
                    skip( "tests that require >0 primer pairs", 1 )
                      if ! $result->num_primer_pairs;
                    my $pair = $result->next_primer_pair;
                    isa_ok( $pair, 'Bio::Tools::Primer3Redux::PrimerPair' );
                    isa_ok( $pair, 'Bio::SeqFeature::Generic' );

                    my ( $fp, $rp ) =
                      ( $pair->forward_primer, $pair->reverse_primer );
                    is( $fp->oligo_type, 'forward_primer', 'oligo_type of fwd primer is forward_priemr' );
                    foreach my $primer ($fp,$rp){
                      # can't really do exact checks here, but we can certainly
                      # check various things about these...
                      isa_ok( $primer, 'Bio::Tools::Primer3Redux::Primer' );
                      isa_ok( $primer, 'Bio::SeqFeature::Generic' );
                      isa_ok( $rp, 'Bio::Tools::Primer3Redux::Primer' );
                      isa_ok( $rp, 'Bio::SeqFeature::Generic' );
                      like( $primer->seq->seq, qr/^[ACGTN]+$/,
                          "forward primer contains sequence" );
                      like( $rp->seq->seq, qr/^[ACGTN]+$/,
                          "reverse primer contains sequence" );
                      cmp_ok( $primer->seq->length, '>', 18,
                          "fwd primer length >18" );
                      cmp_ok( $rp->seq->length, '>', 18,
                          "rev primer length >18" );

                      cmp_ok( $primer->gc_content,   '>', 40, 'GC content >40' );
                      cmp_ok( $primer->melting_temp, '>', 50, 'Tm > 50' );
                      is( $primer->rank,       0, 'rank of the first primer is 0' );
                      like( $primer->run_description, qr/considered/, "The primer's description contain the word 'considered'" );
                    }


                    # If a location for the pair is provided in the expectation
                    # check it here. This is useful to check that some of
                    # the parameters (such as region contraints) have been
                    # passed on to primer3 correctly
                    SKIP: {
                        skip( "no location given", 1 )
                          if !defined $test->{expect}{loc_pair};
                        my ( $start, $end ) = @{ $test->{expect}{loc_pair} };
                        is( $pair->start, $start,
                            "primer pair start position is correct" );
                        is( $pair->end, $end,
                            "primer pair end position is correct" );
                    }
                }    # skip if 0 pairs
            }
        }    # skip if wrong version
    }    # each test

    # test the primer3 settings file with the first set of
    # parameters. The settigns file sets min Tm to 70, so
    # if it was applied then this design should fail now
    SKIP: {
        skip( "tests for primer3_setting_file which require primer3 v2.x", 1 )
          if $major_version < 2;
        my $settings_file = test_input_file('primer3_settings.txt');
        $primer3 = Bio::Tools::Run::Primer3Redux->new(
            -p3_settings_file => $settings_file );
        $primer3->set_parameters( %{ $tests[0]->{params} } );
        ok(
            my $parser = $primer3->run($seq),
            "Can run primer3 with p3_settings_file"
        );
        my $result = $parser->next_result;
        is( $result->num_primer_pairs, 0,
"strict global PRIMER params in p3_settings_file successfully applied and cause design to fail"
        );

    }

}    # skip if no executable

unlink('mlc') if -e 'mlc';
