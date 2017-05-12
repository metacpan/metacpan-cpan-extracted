#!/usr/bin/env perl

## no critic (ProhibitMultiplePackages)

package MyDownloader;
use strict;
use utf8;
use warnings qw(all);

use Moo;

extends 'YADA::Worker';

has '+use_stats'=> (default => sub { 1 });
has '+retry'    => (default => sub { 10 });

after init => sub {
    my ($self) = @_;

    $self->setopt(
        encoding            => '',
        verbose             => 1,
    );
};

after finish => sub {
    my ($self, $result) = @_;

    if ($self->has_error) {
        print "ERROR: $result\n";
    } else {
        printf "Finished downloading %s: %d bytes\n", $self->final_url, length ${$self->data};
    }
};

around has_error => sub {
    my $orig = shift;
    my $self = shift;

    return 1 if $self->$orig(@_);
    return 1 if $self->getinfo('response_code') =~ m{^5[0-9]{2}$}x;
};

1;

package main;
use strict;
use utf8;
use warnings qw(all);

use Carp;
use Data::Printer;

use YADA;

my $q = YADA->new(
    max     => 8,
    timeout => 30,
);

open(my $fh, '<', 'queue')
    or croak "can't open queue: $!";
while (my $url = <$fh>) {
    chomp $url;

    $q->append(sub {
        MyDownloader->new($url)
    });
}
close $fh;
$q->wait;

p $q->stats;
