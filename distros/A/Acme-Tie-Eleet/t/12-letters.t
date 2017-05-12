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
# Translitterations.
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;
# use POSIX qw(tmpnam);

# Initialization.
# BEGIN { plan tests => 6 };
BEGIN { plan tests => 3 };

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

# # No translitteration.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, letters=>0;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^eleet/);

# # Random translitteration.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, letters=>50;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^[e3][l1|][e3][e3][t7+]/);

# # Full translitteration.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, letters=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^3[1|]33[7+]/);

# unlink $file;


#------------------------------#
#          TIESCALAR.          #
#------------------------------#

# No translitteration.
tie $line, 'Acme::Tie::Eleet', @opts, letters=>0;
$line = "eleet";
ok($line, qr/^eleet/);
untie $line;

# Random translitteration.
tie $line, 'Acme::Tie::Eleet', @opts, letters=>50;
$line = "eleet";
ok($line, qr/^[e3][l1|][e3][e3][t7+]/);
untie $line;

# Full translitteration.
tie $line, 'Acme::Tie::Eleet', @opts, letters=>100;
$line = "eleet";
ok($line, qr/^3[1|]33[7+]/);
untie $line;
