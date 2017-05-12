#!/usr/bin/env perl
# created on 2014-07-06

use warnings;
use strict;
use 5.010;
use Bio::Gonzales::Stat::Util qw/hist_text/;

use Pod::Usage;
use Getopt::Long;

my %opt = ();
GetOptions( \%opt, 'log10|l', 'breaks|b=i', 'help|h' ) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );

my @values = map { chomp; $_ } <STDIN>;

print hist_text( \@values, { skip_empty => 1, breaks => $opt{breaks} , 'log10' => $opt{'log10'} });
