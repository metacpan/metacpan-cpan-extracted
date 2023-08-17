#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval 'use Perl::Critic::Utils qw(all_perl_files);use Test::Perl::Critic;';
plan skip_all => "Perl::Critic::Utils and Test::Perl::Critic required to check files." if $@;
critic_ok($_) for all_perl_files(qw(lib t));

done_testing;
