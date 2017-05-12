package Example::Hello;
use 5.008001;
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
