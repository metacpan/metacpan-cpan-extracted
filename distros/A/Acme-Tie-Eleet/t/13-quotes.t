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
# Adding quotes.
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;
# use POSIX qw(tmpnam);

# Initialization.
# BEGIN { plan tests => 4 };
BEGIN { plan tests => 2 };

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

# # Beginning of sentence.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, add_before=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^(?!eleet)/);

# # End of sentence.
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, add_after=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/(?!eleet$)/);

# unlink $file;


#------------------------------#
#          TIESCALAR.          #
#------------------------------#

# Beginning of sentence.
tie $line, 'Acme::Tie::Eleet', @opts, add_before=>100;
$line = "eleet";
ok($line, qr/^(?!eleet)/);
untie $line;

# End of sentence.
tie $line, 'Acme::Tie::Eleet', @opts, add_after=>100;
$line = "eleet";
ok($line, qr/(?!eleet$)/);
untie $line;
