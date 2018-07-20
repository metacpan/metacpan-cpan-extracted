package BioSAILs::Command::new;
use v5.10;
use strict;
use warnings FATAL => 'all';
use MooseX::App::Command;
use namespace::autoclean;

extends 'BioX::Workflow::Command::new';
command_short_description 'Create a new workflow.';
command_long_description 'Create a new workflow.';

__PACKAGE__->meta->make_immutable;

1;
