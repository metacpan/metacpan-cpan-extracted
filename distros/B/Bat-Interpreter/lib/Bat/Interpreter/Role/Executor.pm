package Bat::Interpreter::Role::Executor;

use utf8;

use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.002';    # VERSION

=encoding utf-8

=head1 NAME

Bat::Interpreter::Role::Executor - Role for executing the commands in the bat files

=head1 DESCRIPTION

Role for executing the commands in the bat files. With this role you can just
print the commands that are going to be executed (dry run), or maybe in another
machine (via SSH, RPC, or whatever).

See Bat::Interpreter::Delegate::Executor::DryRunner or Bat::Interpreter::Delegate::Executor::PartialDryRunner
for an example of implementation

=head1 METHODS

=head2 execute_for_command

Execute commands for use in FOR expressions.
This is usually used to capture output and
implement some logic inside the bat/cmd file.

=head2 execute_command

Execute general commands

=cut

requires 'execute_command';

requires 'execute_for_command';

1;
