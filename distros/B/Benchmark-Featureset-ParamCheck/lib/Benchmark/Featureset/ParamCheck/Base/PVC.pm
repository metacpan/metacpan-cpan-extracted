use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base::PVC;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Params::ValidationCompiler 0.24 qw();

1;