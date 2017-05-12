#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
use Module::Build;

my $classpath = Module::Build->current->notes('classpath');

require 't/common.pl';
skip_test("Weka is not installed") unless defined $classpath;

plan tests => 1 + num_standard_tests();


ok(1);

#########################

my @args;
push @args, weka_path => $classpath
  unless $classpath eq '-';

perform_standard_tests(
		       learner_class => 'AI::Categorizer::Learner::Weka',
		       weka_classifier => 'weka.classifiers.functions.SMO',
                                     # or 'weka.classifiers.SMO' for older Weka versions
		       @args,
		      );

