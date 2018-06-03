package Bat::Interpreter::Role::Executor;

use utf8;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '0.010';    # VERSION

requires 'execute_command';

requires 'execute_for_command';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Role::Executor

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Role for executing the commands in the bat files. With this role you can just
print the commands that are going to be executed (dry run), or maybe in another
machine (via SSH, RPC, or whatever).

See Bat::Interpreter::Delegate::Executor::DryRunner or Bat::Interpreter::Delegate::Executor::PartialDryRunner
for an example of implementation

=head1 NAME

Bat::Interpreter::Role::Executor - Role for executing the commands in the bat files

=head1 METHODS

=head2 execute_for_command

Execute commands for use in FOR expressions.
This is usually used to capture output and
implement some logic inside the bat/cmd file.

=head2 execute_command

Execute general commands

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
