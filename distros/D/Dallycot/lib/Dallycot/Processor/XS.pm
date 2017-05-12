package Dallycot::Processor::XS;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: XS implementation of Processor methods

use strict;
use warnings;

use utf8;

use Moose;

use Dallycot;

require XSLoader;

XSLoader::load( __PACKAGE__, $Dallycot::VERSION );

__PACKAGE__ -> meta -> make_immutable;

1;
