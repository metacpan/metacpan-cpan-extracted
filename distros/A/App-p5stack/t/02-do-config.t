#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 13;
use File::Spec::Functions;
use File::Which;

use lib qw/lib/;
use App::p5stack;

# default config
my $p5stack = App::p5stack->new;

is( $p5stack->{perl}, which('perl'), 'default perl is system' );
is( $p5stack->{deps}, 'dzil', 'default deps is dzil' );
is( $p5stack->{command}, '', 'default command is empty' );
is( $p5stack->{perls_root}, catfile($ENV{HOME}, '.p5stack', 'perls'), 'default config for perls root' );
is_deeply( $p5stack->{orig_argv}, [], 'default argvs list is empty' );
is( $p5stack->{skip_install}, 1, 'default perl is system perl' );

# example config
$ENV{P5STACKCFG} = 't/p5stack.yml';
$p5stack = App::p5stack->new;

is( $p5stack->{perls_root}, catfile($ENV{HOME}, '.p5stack', 'perls'), 'default config for perls root' );
is( $p5stack->{perl_version}, '5.20.3', 'perl version' );
is( $p5stack->{perl}, catfile($p5stack->{perls_root},$p5stack->{perl_version},'bin','perl'), 'perl interpreter' );
is( $p5stack->{deps}, 'dzil', 'deps is dzil' );
is( $p5stack->{command}, '', 'command is empty' );
is_deeply( $p5stack->{orig_argv}, [], 'argvs list is empty' );
is( $p5stack->{skip_install}, (-e $p5stack->{perl} or 0), 'skip install' );

