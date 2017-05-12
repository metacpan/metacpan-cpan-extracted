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
# Spacer.
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

# # Wrong spacer (pattern non numeric).
# eval {
#     open OUT, ">$file" or die "Unable to create temporary file: $!";
#     tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>"aa";
# };
# ok($@, qr/^spacer: wrong pattern /);

# # Random: no spacing (0).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>0;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^e ?l ?e ?e ?t ?/);

# # Random: spacing (75).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>75;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^e ?l ?e ?e ?t ?/);

# # Random: max spacing (100).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>100;
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^e l e e t /);

# # Pattern: illegal pattern (0/0).
# eval {
#     open OUT, ">$file" or die "Unable to create temporary file: $!";
#     tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>"0/0";
# };
# ok($@, qr!^spacer: illegal pattern 0/0!);

# # Pattern: no spacing (0/1).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>"0/1";
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^eleet/);

# # Pattern: one on two (1/1).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>"1/1";
# print OUT "eleeteleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^e le et el ee t/);

# # Pattern: max spacing (1/0).
# open OUT, ">$file" or die "Unable to create temporary file: $!";
# tie *OUT, 'Acme::Tie::Eleet', *OUT, @opts, spacer=>"1/0";
# print OUT "eleet";
# untie *OUT;
# open IN, "<$file" or die "Unable to open temporary file: $!";
# $line = <IN>;
# ok($line, qr/^e l e e t /);

# unlink $file;


#------------------------------#
#          TIESCALAR.          #
#------------------------------#

# Wrong spacer (pattern non numeric).
eval {
    tie $line, 'Acme::Tie::Eleet', @opts, spacer=>"aa";
};
ok($@, qr/^spacer: wrong pattern /);
untie $line;

# Random: no spacing (0).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>0;
$line = "eleet";
ok($line, qr/^e ?l ?e ?e ?t ?/);
untie $line;

# Random: spacing (75).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>75;
$line = "eleet";
ok($line, qr/^e ?l ?e ?e ?t ?/);
untie $line;

# Random: max spacing (100).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>100;
$line = "eleet";
ok($line, qr/^e l e e t /);
untie $line;

# Pattern: illegal pattern (0/0).
eval {
    tie $line, 'Acme::Tie::Eleet', @opts, spacer=>"0/0";
};
ok($@, qr!^spacer: illegal pattern 0/0!);
untie $line;

# Pattern: no spacing (0/1).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>"0/1";
$line = "eleet";
ok($line, qr/^eleet/);
untie $line;

# Pattern: one on two (1/1).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>"1/1";
$line = "eleeteleet";
ok($line, qr/^e le et el ee t/);
untie $line;

# Pattern: max spacing (1/0).
tie $line, 'Acme::Tie::Eleet', @opts, spacer=>"1/0";
$line = "eleet";
ok($line, qr/^e l e e t /);
untie $line;
