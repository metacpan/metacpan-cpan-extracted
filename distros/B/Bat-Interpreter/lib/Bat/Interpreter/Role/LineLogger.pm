package Bat::Interpreter::Role::LineLogger;

use utf8;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '0.023';    # VERSION

requires 'log_line';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Role::LineLogger

=head1 VERSION

version 0.023

=head1 DESCRIPTION

Role for logging all the lines just before bein evaluated by the interpreter. This mean, all the
variables are substituted and manipulated. You can choose what to do with this lines, just printing them or whatever.

See Bat::Interpreter::Delegate::LineLogger::Silent for a simple example

=head1 NAME

Bat::Interpreter::Role::LineLogger - Role for logging all the lines as are going evaluated by the interpreter

=head1 METHODS

=head2 log_line

Just the line

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
