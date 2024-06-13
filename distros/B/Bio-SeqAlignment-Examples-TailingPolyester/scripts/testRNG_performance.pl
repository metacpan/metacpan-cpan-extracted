#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
use v5.36;
use strict;
use warnings;

use Benchmark::CSV;
use Carp;
use Class::Tiny;
use Bio::SeqAlignment::Examples::TailingPolyester::PERLRNGPDL;
use Bio::SeqAlignment::Examples::TailingPolyester::PERLRNG;
use Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG;
use Bio::SeqAlignment::Examples::TailingPolyester::GSLRNG;
use Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL;
use Bio::SeqAlignment::Examples::TailingPolyester::SimulateMathGSL;
use Cwd;
use File::Spec;
use PDL;
use PDL::IO::CSV ':all';
use PDL::GSL::RNG;

use Time::HiRes 'time';

my $benchmark_reps    = 1000;
my $distr             = 'lognormal';
my $iter              = 1000000;
my $t                 = time;
my $params            = [ log(125), 1 ];
my $lower_trunc_limit = 0;
my $upper_trunc_limit = 250;

set_autopthread_size(1024*256); ## ensures we will only use 1 thread
## generate RNG objects to assess object construction overhead
my $rng_PERLRNGPDL =
  Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
    seed       => 3,
    rng_plugin => 'Bio::SeqAlignment::Examples::TailingPolyester::PERLRNGPDL'
  );    ## perl rng with PDL
my $rng_PERLRNG =
  Bio::SeqAlignment::Examples::TailingPolyester::SimulateMathGSL->new(
    seed       => 3,
    rng_plugin => 'Bio::SeqAlignment::Examples::TailingPolyester::PERLRNG'
  );    ## perl rng with Math::GSL
my $rng_RNG =
  Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
    seed       => 3,
    rng_plugin => 'Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG'
  );
my $rng_PDLGSLUNIF =
  Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
    seed       => 3,
    rng_plugin => 'Bio::SeqAlignment::Examples::TailingPolyester::GSLRNG',
    RNG_init_parameters => ['mt19937']
  );    ## GSL uniform RNG with PDL

my $cwd = getcwd();

my $benchmark = Benchmark::CSV->new(
    output      => File::Spec->catfile($cwd,'testPerl.csv'),
    sample_size => 1,
);

$benchmark->add_instance(
    PDLGSL_PERLRNGPDL_WITH_OC => sub {
        my $rng =
          Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
            seed       => 3,
            rng_plugin =>
              'Bio::SeqAlignment::Examples::TailingPolyester::PERLRNGPDL'
          );
        my $pdl = $rng->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    MathMLGSL_PERLRNG_WITH_OC => sub {
        my $rng =
          Bio::SeqAlignment::Examples::TailingPolyester::SimulateMathGSL->new(
            seed       => 3,
            rng_plugin =>
              'Bio::SeqAlignment::Examples::TailingPolyester::PERLRNG'
          );
        my $pdl = $rng->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    PDLGSL_PDLUNIF_WITH_OC => sub {
        my $rng =
          Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
            seed       => 3,
            rng_plugin =>
              'Bio::SeqAlignment::Examples::TailingPolyester::PDLRNG'
          );
        my $pdl = $rng->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    PDLGSL_PDLGSLUNIF_WITH_OC => sub {
        my $rng =
          Bio::SeqAlignment::Examples::TailingPolyester::SimulatePDLGSL->new(
            seed       => 3,
            rng_plugin =>
              'Bio::SeqAlignment::Examples::TailingPolyester::GSLRNG',
            RNG_init_parameters => ['mt19937']
          );
        my $pdl = $rng->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    PDLGSL_PERLRNGPDL_WO_OC => sub {
        my $pdl = $rng_PERLRNGPDL->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    MathMLGSL_PERLRNG_WO_OC => sub {
        my $pdl = $rng_PERLRNG->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    PDLGSL_PDLUNIF_WO_OC => sub {
        my $pdl = $rng_RNG->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);
$benchmark->add_instance(
    PDLGSL_PDLGSLUNIF_WO_OC => sub {
        my $pdl = $rng_PDLGSLUNIF->simulate_trunc(
            random_dim      => [$iter],
            distr           => $distr,
            params          => $params,
            left_trunc_lmt  => $lower_trunc_limit,
            right_trunc_lmt => $upper_trunc_limit,

        );
    }
);


$benchmark->run_iterations($benchmark_reps);
