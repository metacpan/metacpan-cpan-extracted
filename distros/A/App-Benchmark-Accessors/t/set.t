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
    {   moose                  => sub { $Moose->myattr(27) },
        moose_immutable        => sub { $MooseImmutable->myattr(27) },
        mouse                  => sub { $Mouse->myattr(27) },
        mouse_immutable        => sub { $MouseImmutable->myattr(27) },
        class_accessor         => sub { $ClassAccessor->myattr(27) },
        class_accessor_fast    => sub { $ClassAccessorFast->myattr(27) },
        class_accessor_fast_xs => sub { $ClassAccessorFastXS->myattr(27) },
        class_xsaccessor_compat =>
          sub { $ClassXSAccessorCompat->myattr(27) },
        class_accessor_complex => sub { $ClassAccessorComplex->myattr(27) },
        class_accessor_constructor =>
          sub { $ClassAccessorConstructor->myattr(27) },
        class_accessor_lite    => sub { $ClassAccessorLite->myattr(27) },
        class_accessor_classy  => sub { $ClassAccessorClassy->set_myattr(27) },
        mojo                   => sub { $Mojo->myattr(27) },
        class_methodmaker      => sub { $ClassMethodMaker->myattr(27) },
        accessors              => sub { $Accessors->myattr(27) },
        spiffy                 => sub { $Spiffy->myattr(27) },
        class_spiffy           => sub { $ClassSpiffy->myattr(27) },
        class_xsaccessor       => sub { $ClassXSAccessor->myattr(27) },
        class_xsaccessor_array => sub { $ClassXSAccessorArray->myattr(27) },
        object_tiny_xs         => sub { $ObjectTinyXS->myattr(27) },
        rose                   => sub { $Rose->myattr(27) },

        #badger_class => sub { $BadgerClass->myattr(27) },
        rubyish_attribute => sub { $RubyishAttribute->myattr(27) },
    }
);
