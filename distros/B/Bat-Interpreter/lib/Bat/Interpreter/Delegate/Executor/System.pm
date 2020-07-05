package Bat::Interpreter::Delegate::Executor::System;

use utf8;

use Moo;
use namespace::autoclean;

with 'Bat::Interpreter::Role::Executor';

our $VERSION = '0.022';    # VERSION

sub execute_command {
    my $self    = shift();
    my $command = shift();
    return system($command);
}

sub execute_for_command {
    my $self    = shift();
    my $command = shift();
    my $output  = `$command`;
    chomp $output;
    return $output;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Delegate::Executor::System

=head1 VERSION

version 0.022

=head1 SYNOPSIS

    use Bat::Interpreter;
    use Bat::Interpreter::Delegate::Executor::System;

    my $system_executor = Bat::Interpreter::Delegate::Executor::System->new;

    my $interpreter = Bat::Interpreter->new(executor => $system_executor);
    $interpreter->run('my.cmd');

=head1 DESCRIPTION

Every command gets through system. So if you are in Linux using bash, bash will try to execute the command.

This executor is as dumb and simple as it can, be cautious.

=head1 NAME

Bat::Interpreter::Delegate::Executor::PartialDryRunner - Executor for executing commands via perl system

=head1 METHODS

=head2 execute_command

Execute general commands.

This executor use perl system

=head2 execute_for_command

Execute commands for use in FOR expressions.
This is usually used to capture output and
implement some logic inside the bat/cmd file.

This executor executes this commands via perl subshell: ``

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
