package BioSAILs::Command::add;
use v5.10;
use strict;
use warnings FATAL => 'all';
use MooseX::App::Command;
use namespace::autoclean;

extends 'BioX::Workflow::Command::add';

command_short_description 'Add rules to an existing workflow.';
command_long_description 'Add rules to an existing workflow.';

__PACKAGE__->meta->make_immutable;

1;
