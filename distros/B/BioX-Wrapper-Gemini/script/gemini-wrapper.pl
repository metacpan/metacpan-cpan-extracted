#!/usr/bin/env perl

package Main;

use Moose;

extends 'BioX::Wrapper::Gemini';

Main->new_with_options->run;

1;
