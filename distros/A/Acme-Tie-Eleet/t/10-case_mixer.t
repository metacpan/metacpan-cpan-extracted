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
# Case mixer test suite.
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;
# use POSIX qw(tmpnam);

# Initialization.
# BEGIN { plan tests => 16 };
BEGIN { plan tests => 8 };

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

# # Wrong case_mixer (pattern non numeric).
# eval {
#     open OUT, ">$file" or die "Unable to create temporary file: $!";
#     tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>"aa";
# };
# ok($@, qr/^case_mixer: wrong pattern /);

# # Random: no case mixing (0).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>0;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^eleet/);

# # Random: case mixing (75).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>75;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^[eE][lL][eE][eE][tT]/);

# # Random: max case mixing (100).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^ELEET/);

# # Pattern: illegal pattern (0/0).
# eval {
#     open OUT, ">$file" or die "Unable to create temporary file: $!";
#     tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>"0/0";
#     print OUT "eleeteleet";
#     untie *OUT;
#     open IN, "<$file" or die "Unable to open temporary file: $!";
#     my $line = <IN>;
#     die $line;
# };
# ok($@, qr!^case_mixer: illegal pattern 0/0!);

# # Pattern: no case mixing (0/1).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>"0/1";
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^eleet/);

# # Pattern: one on two (1/2).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>"1/1";
# print OUT "eleeteleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^ElEeT/);

# # Pattern: max case mixing (1/0).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, case_mixer=>"1/0";
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^ELEET/);

# unlink $file;


#------------------------------#
#          TIESCALAR.          #
#------------------------------#

# Wrong case_mixer (pattern non numeric).
eval {
    tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>"aa";
};
ok($@, qr/^case_mixer: wrong pattern /);

# Random: no case mixing (0).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>0;
$line = "eleet";
ok($line, qr/^eleet/);
untie $line;

# Random: case mixing (75).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>75;
$line = "eleet";
ok($line, qr/^[eE][lL][eE][eE][tT]/);
untie $line;

# Random: max case mixing (100).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>100;
$line = "eleet";
ok($line, qr/^ELEET/);
untie $line;

# Pattern: illegal pattern (0/0).
eval {
    tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>"0/0";
    die $line;
};
ok($@, qr!^case_mixer: illegal pattern 0/0!);
untie $line;

# Pattern: no case mixing (0/1).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>"0/1";
$line = "eleet";
ok($line, qr/^eleet/);
untie $line;

# Pattern: one on two (1/2).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>"1/1";
$line = "eleet";
ok($line, qr/^ElEeT/);
untie $line;

# Pattern: max case mixing (1/0).
tie $line, 'Acme::Tie::Eleet', @opts, case_mixer=>"1/0";
$line = "eleet";
ok($line, qr/^ELEET/);
untie $line;
