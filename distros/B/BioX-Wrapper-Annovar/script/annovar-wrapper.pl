#!/usr/bin/env perl 

package Main;

use Moose;
#use Carp::Always;

extends 'BioX::Wrapper::Annovar';

Main->new_with_options->run;

1;
