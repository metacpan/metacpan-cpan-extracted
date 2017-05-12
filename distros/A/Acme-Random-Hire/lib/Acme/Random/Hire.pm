package Acme::Random::Hire;
$Acme::Random::Hire::VERSION = '0.001';
# ABSTRACT: turns baubles into trinkets

use strict;
use warnings;

use Acme::Random;
use List::Util qw{shuffle};

sub fire { (List::Util::shuffle(@_))[(scalar @_ % Acme::Random::randomize) - 1] }

1;
