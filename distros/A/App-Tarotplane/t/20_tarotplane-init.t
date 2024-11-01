#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Test::More;

use File::Spec;

use App::Tarotplane qw(%CARD_SORT);

plan tests => 7;

my @files = glob File::Spec->catfile(qw(t data *));

@ARGV = @files;

# Test defaults
my $t1 = App::Tarotplane->init();
isa_ok($t1, 'App::Tarotplane', "init() returns App::Tarotplane object");

is_deeply($t1->get('Files'), \@files, "File list is okay");

is($t1->get('First'), 'Definition',     "Definitions shown first by default");
is($t1->get('Sort'),  $CARD_SORT{None}, "No sorting is done by default");

@ARGV = ('-t', '-r', @files);

my $t2 = App::Tarotplane->init();

is($t2->get('First'), 'Term',            "-t option works");
is($t2->get('Sort'), $CARD_SORT{Random}, "-r option works");

@ARGV = ('-o', 'term', @files);

my $t3 = App::Tarotplane->init();

is($t3->get('Sort'), $CARD_SORT{Order}, "-o option works");
