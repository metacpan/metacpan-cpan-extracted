#!/usr/bin/env perl
# created on 2013-07-28

use warnings;
use strict;
use 5.010;

use Data::Printer;
use Bio::Gonzales::Util::File qw/openod/;

use Pod::Usage;
use Getopt::Long qw(:config auto_help);

my %opt = ( comment => '#' );
GetOptions( \%opt, 'comment=s' ) or pod2usage(2);

my $file = shift;
die "$file is no file" unless ( -f $file );

( my $fh, undef ) = openod( $file, '<' );

my $header = <$fh>;

my $first_line;
while ( $first_line = <$fh> ) {
  last if ( $first_line !~ /\s*$opt{comment}/ );
}

$fh->close;

chomp $header;
chomp $first_line;

my @h  = split /\t/, $header;
my @fl = split /\t/, $first_line;

p \@h;
p \@fl;
