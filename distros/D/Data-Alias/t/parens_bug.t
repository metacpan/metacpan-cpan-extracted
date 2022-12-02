#!/usr/bin/perl -w

use strict;
use warnings qw( FATAL all );
no warnings qw( void );
use lib 'lib';
use Test::More tests => 4;

use Data::Alias;

our $y;

sub{ my $x = $y; ok \$x != \$y; }->();

alias;
alias 42;

sub{ my $x = $y; ok \$x != \$y; }->();

alias{};
alias{ 42 };

sub{ my $x = $y; ok \$x != \$y; }->();

alias();
alias(42);

sub{ my $x = $y; ok \$x != \$y; }->();
