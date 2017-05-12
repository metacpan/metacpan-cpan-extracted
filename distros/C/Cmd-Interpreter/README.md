# NAME

Cmd::Interpreter - Support for line-oriented command interpreters

# SYNOPSIS

    use Cmd::Interpreter;
    our @ISA = qw(Cmd::Interpreter);

# DESCRIPTION

Cmd::Interpreter provides a simple framework for writing line-oriented
command interpreters.

# USAGE

- Write your class

        package Example::Hello;

        use strict;
        use warnings;

        use Cmd::Interpreter;

        our @ISA = qw(Cmd::Interpreter);

        sub help {
            my $self = shift;
            print "common help\n";
            return '';
        }

        sub do_hello {
            my $self = shift;
            print "Hello " . (shift || "World") . "!\n";
            return '';
        }

        sub help_hello {
            my $self = shift;
            print "help for hello\n";
            return '';
        }

        sub do_quit {
            my $self = shift;
            print "By\n";
            return "quit";
        }

        sub empty_line {
        }

        1;

- Use your class

        #!/usr/bin/env perl
        use strict;
        use warnings;

        use Example::Hello;

        my $ex = Example::Hello->new(prompt => 'example> ');
        $ex->run("Welcome to hello world app.");

# API - may be useful for introduce or overriding

## Class constructor

You can pass program name as `prog_name`, prompt as `prompt`.

## Your functions

Loop stoping if function returns true value aka `stop flag`.

- do\_foo

        Will execute on command 'foo'.

- help\_foo

        Will execute on command '?foo' or 'help foo'.

- help

        Will execute when input is '?' or 'help'.

## Framework functions

- pre\_loop

        Will execute before loop.

- post\_loop

        Will execute after loop.

- pre\_cmd

        Receive input line, return one (can be changed).

- post\_cmd

        Receive stop flag, line (from pre_cmd). Return stop flag.

- default\_action

        Will execute when input command not exists.

- empty\_line

        Will execute when input defined but empty. By default execute
        last command if one exists.

- no\_input

        Will execute when input undefined.

- do\_shell

        Will execute when input is '!cmd [args]' or 'shell cmd [args]'.

# FAQ

## Command history

Command history works fine with such module like Term::ReadLine::Perl.

## git ready

You can install Cmd::Interpreter from `cpanm git@github.com:oakulikov/Cmd-Interpreter.git`.

# AUTHOR

Oleg Kulikov <oakulikov@yandex.ru>

# THANKS TO

Authors of Python Lib/cmd.py

# LICENSE

Copyright (C) Oleg Kulikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
