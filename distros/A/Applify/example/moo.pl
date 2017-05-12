#!/usr/bin/perl
use lib 'lib';
use Moo;
use Applify;

has name => is => 'rw';

app {
    my($self, @name) = @_;

    @name or die "No name?";
    $self->name("@name");
    print "Yey! I got name as input: ", $self->name, "\n";

    return 0;
};
