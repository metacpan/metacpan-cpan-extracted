#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '1.02';

#----------------------------------------------------------------------------

=head1 NAME

check100.pl - checks the BackPAN 100 list and returns differences

=head1 SYNOPSIS

  perl check100.pl

=head1 DESCRIPTION

Downloads the latest copy of the backpan100.csv file from CPAN Testers Statistics
site. Compares with the previous download, and prints the differences.

=cut

# -------------------------------------
# Library Modules

use File::Basename;
use Text::Diff;
use WWW::Mechanize;

# -------------------------------------
# Variables

# -------------------------------------
# Program

my $base = dirname($0);
chdir($base);
#print "dir=$base\n";

my $mech = WWW::Mechanize->new();
my $source = 'http://stats.cpantesters.org/stats/backpan100.csv';
my $target = basename($source);
$mech->mirror($source,$target);

my $file = 'data/backpan100.csv';

my $diff = diff $file, $target;
print $diff . "\n";

#unlink $target;

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-OneHundred

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
