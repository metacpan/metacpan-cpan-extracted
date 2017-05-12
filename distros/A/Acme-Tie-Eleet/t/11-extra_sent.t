#!perl
#
# This file is part of Acme::Tie::Eleet.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

#
# Extra sentences.
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;
# use POSIX qw(tmpnam);

# Initialization.
# BEGIN { plan tests => 2 };
BEGIN { plan tests => 1 };

# Our stuff.
require Acme::Tie::Eleet;
# untie *STDIN;
# untie *STDOUT;
# untie *STDERR;

# Vars.
# my $file = tmpnam();
my $line;
my @opts =
    ( letters    => 0,
      spacer     => 0,
      case_mixer => 0,
      words      => 0,
      add_before => 0,
      add_after  => 0,
      extra_sent => 0
);


#------------------------------#
#          TIEHANDLE.          #
#------------------------------#

# # Full extra sentences.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, extra_sent=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/(?!eleet$)/);

# unlink $file;

#------------------------------#
#          TIESCALAR.          #
#------------------------------#

# Full extra sentences.
tie $line, 'Acme::Tie::Eleet', @opts, extra_sent=>100;
$line = "eleet";
ok($line, qr/(?!eleet$)/);
untie $line;
