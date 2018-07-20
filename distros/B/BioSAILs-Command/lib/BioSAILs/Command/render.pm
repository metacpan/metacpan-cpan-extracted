package BioSAILs::Command::render;

use v5.10;
use strict;
use warnings FATAL => 'all';
use MooseX::App::Command;
use namespace::autoclean;

extends 'BioX::Workflow::Command::run';

command_short_description 'Render your workflow.';
command_long_description
    'Render your workflow to a shell script, process the variables, and create all your directories.';

__PACKAGE__->meta->make_immutable;

1;
