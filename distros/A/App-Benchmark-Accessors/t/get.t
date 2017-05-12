#!/usr/bin/env perl
use warnings;
use strict;
use App::Benchmark;
use App::Benchmark::Accessors;
my $iterations = shift;
$iterations ||= 2_000_000;
my $Moose                    = WithMoose->new;
my $MooseImmutable           = WithMooseImmutable->new;
my $Mouse                    = WithMouse->new;
my $MouseImmutable           = WithMouseImmutable->new;
my $ClassAccessor            = WithClassAccessor->new;
my $ClassAccessorFast        = WithClassAccessorFast->new;
my $ClassAccessorFastXS      = WithClassAccessorFastXS->new;
my $ClassXSAccessorCompat    = WithClassXSAccessorCompat->new;
my $ClassAccessorComplex     = WithClassAccessorComplex->new;
my $ClassAccessorConstructor = WithClassAccessorConstructor->new;
my $ClassAccessorLite        = WithClassAccessorLite->new;
my $ClassAccessorClassy      = WithClassAccessorClassy->new;
my $Mojo                     = WithMojo->new;
my $ClassMethodMaker         = WithClassMethodMaker->new;
my $Accessors                = WithAccessors->new;
my $ObjectTiny               = WithObjectTiny->new;
my $Spiffy                   = WithSpiffy->new;
my $ClassSpiffy              = WithClassSpiffy->new;
my $ClassXSAccessor          = WithClassXSAccessor->new;
my $ClassXSAccessorArray     = WithClassXSAccessorArray->new;
my $ObjectTinyXS             = WithObjectTinyXS->new;
my $Rose                     = WithRose->new;

#my $BadgerClass              = WithBadgerClass->new;
my $RubyishAttribute = WithRubyishAttribute->new;
benchmark_diag(
    $iterations,
    {   moose                      => sub { $Moose->myattr },
        moose_immutable            => sub { $MooseImmutable->myattr },
        mouse                      => sub { $Mouse->myattr },
        mouse_immutable            => sub { $MouseImmutable->myattr },
        class_accessor             => sub { $ClassAccessor->myattr },
        class_accessor_fast        => sub { $ClassAccessorFast->myattr },
        class_accessor_fast_xs     => sub { $ClassAccessorFastXS->myattr },
        class_xsaccessor_compat    => sub { $ClassXSAccessorCompat->myattr },
        class_accessor_complex     => sub { $ClassAccessorComplex->myattr },
        class_accessor_constructor => sub { $ClassAccessorConstructor->myattr },
        class_accessor_lite        => sub { $ClassAccessorLite->myattr },
        class_accessor_classy      => sub { $ClassAccessorClassy->myattr },
        mojo                       => sub { $Mojo->myattr },
        class_methodmaker          => sub { $ClassMethodMaker->myattr },
        object_tiny                => sub { $ObjectTiny->myattr },
        accessors                  => sub { $Accessors->myattr },
        spiffy                     => sub { $Spiffy->myattr },
        class_spiffy               => sub { $ClassSpiffy->myattr },
        class_xsaccessor           => sub { $ClassXSAccessor->myattr },
        class_xsaccessor_array     => sub { $ClassXSAccessorArray->myattr },
        object_tiny_xs             => sub { $ObjectTinyXS->myattr },
        rose                       => sub { $Rose->myattr },

        #badger_class => sub { $BadgerClass->myattr },
        rubyish_attribute => sub { $RubyishAttribute->myattr },
    }
);
