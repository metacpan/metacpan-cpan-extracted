package Cmd::Interpreter;
use 5.008001;
use strict;
use warnings;

use Term::ReadLine;

our $VERSION = "0.3.3";

use constant IDENT_CHARS => join '', 'a'..'z', 'A'..'Z', '0' .. '9', '_';
use constant PROG_NAME => 'Simple command interpreter';
use constant PROMPT => 'cmd> ';


sub new {
    my $class = shift;
    my %args = @_;

    my $self = {
        prog_name => PROG_NAME,
        prompt => PROMPT,
        last_cmd => '',
        %args
    };

    return bless $self, $class;
}


sub run {
    my $self = shift;

    $self->pre_loop();
    $self->loop(@_);
    $self->post_loop();
}


sub loop {
    my $self = shift;
    my $intro = shift;

    print "$intro\n" if $intro;

    my $term = Term::ReadLine->new($self->{prog_name});
    my $stop = '';

    while (1) {
        my $line = $term->readline($self->{prompt});

        $line = $self->pre_cmd($line);
        $stop = $self->do_cmd($line);
        $stop = $self->post_cmd($stop, $line);

        last if $stop;
    }
}


sub pre_loop {
}


sub post_loop {
}


sub pre_cmd {
    my $self = shift;

    return shift;
}


sub post_cmd {
    my $self = shift;

    return shift;
}


sub default_action {
}


sub empty_line {
    my $self = shift;

    return $self->do_cmd($self->{last_cmd}) if $self->{last_cmd};
    return '';
}


sub no_input {
    my $self = shift;

    print "\n";

    return "no_input";
}


sub do_help {
    my $self = shift;
    my $topic = shift;

    if ($topic) {
        my $sub = "help_$topic";

        if ($self->check_sub($sub)) {
            return $self->$sub();
        }

        print "There is no help for '$topic'\n";
    } else {
        my $sub = "help";

        if ($self->check_sub($sub)) {
            return $self->$sub();
        }

        print "Please try: '?command' or 'help command'\n";
    }

    return '';
}


sub do_shell {
    my $self = shift;
    my $cmd = shift;

    if ($cmd) {
        print `$cmd`;
    } else {
        print "Please use: '!command [args]' or 'shell command [args]'\n";
    }

    return '';
}


sub do_cmd {
    my $self = shift;

    return $self->no_input() unless defined $_[0];

    my ($cmd, $args, $line) = $self->parse_line(shift);

    return $self->empty_line() unless $line;
    return $self->default_action() unless $cmd;

    my $sub = $self->check_sub("do_$cmd");

    return $self->default_action($cmd, $args) unless $sub;

    $self->{last_cmd} = $line;

    return $self->$sub($args);
}


sub check_sub {
    my $self = shift;
    my $sub = shift;

    return $self->can($sub) ? $sub : '';
}


sub parse_line {
    my $self = shift;
    my $line = shift;

    chomp $line;

    return ('', '', $line) unless $line;

    if ($line =~ /\?(.*)/) {
        $line = "help $1";
    } elsif ($line =~ /!(.*)/) {
        $line = "shell $1";
    }

    return ($1, $2, $line) if $line =~ /^([@{[IDENT_CHARS]}]+)\s*(.*)\s*$/;
    return ('', '', $line);
}


1;
__END__

=encoding utf-8

=head1 NAME

Cmd::Interpreter - Support for line-oriented command interpreters

=head1 SYNOPSIS

    use Cmd::Interpreter;
    our @ISA = qw(Cmd::Interpreter);

=head1 DESCRIPTION

Cmd::Interpreter provides a simple framework for writing line-oriented
command interpreters.

=head1 USAGE

=over 4

=item Write your class

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

=item Use your class

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use Example::Hello;

    my $ex = Example::Hello->new(prompt => 'example> ');
    $ex->run("Welcome to hello world app.");

=back

=head1 API - may be useful for introduce or overriding

=head2 Class constructor

You can pass program name as C<prog_name>, prompt as C<prompt>.

=head2 Your functions

Loop stoping if function returns true value aka C<stop flag>.

=over 4

=item do_foo

    Will execute on command 'foo'.

=item help_foo

    Will execute on command '?foo' or 'help foo'.

=item help

    Will execute when input is '?' or 'help'.

=back

=head2 Framework functions

=over 4

=item pre_loop

    Will execute before loop.

=item post_loop

    Will execute after loop.

=item pre_cmd

    Receive input line, return one (can be changed).

=item post_cmd

    Receive stop flag, line (from pre_cmd). Return stop flag.

=item default_action

    Will execute when input command not exists.

=item empty_line

    Will execute when input defined but empty. By default execute
    last command if one exists.

=item no_input

    Will execute when input undefined.

=item do_shell

    Will execute when input is '!cmd [args]' or 'shell cmd [args]'.

=back

=head1 FAQ

=head2 Command history

Command history works fine with such module like Term::ReadLine::Perl.

=head2 git ready

You can install Cmd::Interpreter from C<< cpanm git@github.com:oakulikov/Cmd-Interpreter.git >>.

=head1 AUTHOR

Oleg Kulikov E<lt>oakulikov@yandex.ruE<gt>

=head1 THANKS TO

Authors of Python Lib/cmd.py

=head1 LICENSE

Copyright (C) Oleg Kulikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

