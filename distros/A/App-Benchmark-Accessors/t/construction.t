#!/usr/bin/env perl
use warnings;
use strict;
use App::Benchmark;
use App::Benchmark::Accessors;
my $iterations = shift;
$iterations ||= 200_000;
benchmark_diag(
    $iterations,
    {   moose                      => sub { WithMoose->new },
        moose_immutable            => sub { WithMooseImmutable->new },
        mouse                      => sub { WithMouse->new },
        mouse_immutable            => sub { WithMouseImmutable->new },
        class_accessor             => sub { WithClassAccessor->new },
        class_accessor_fast        => sub { WithClassAccessorFast->new },
        class_accessor_fast_xs     => sub { WithClassAccessorFastXS->new },
        class_accessor_complex     => sub { WithClassAccessorComplex->new },
        class_accessor_constructor => sub { WithClassAccessorConstructor->new },
        class_accessor_lite        => sub { WithClassAccessorLite->new },
        class_accessor_classy      => sub { WithClassAccessorClassy->new },
        mojo                       => sub { WithMojo->new },
        class_methodmaker          => sub { WithClassMethodMaker->new },
        object_tiny                => sub { WithObjectTiny->new },
        spiffy                     => sub { WithSpiffy->new },
        class_spiffy               => sub { WithClassSpiffy->new },
        class_xsaccessor           => sub { WithClassXSAccessor->new },
        class_xsaccessor_array     => sub { WithClassXSAccessorArray->new },
        object_tiny_xs             => sub { WithObjectTinyXS->new },
        rose                       => sub { WithRose->new },

      #badger_class               => sub { WithBadgerClass->new              } ,
    }
);
