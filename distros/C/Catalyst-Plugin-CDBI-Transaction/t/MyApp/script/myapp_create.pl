#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Pod::Usage;
use Catalyst::Helper;

my $help = 0;
my $nonew = 0;

GetOptions( 'help|?' => \$help,
	    'nonew'  => \$nonew );

pod2usage(1) if ( $help || !$ARGV[0] );

my $helper = Catalyst::Helper->new({'.newfiles' => !$nonew});
pod2usage(1) unless $helper->mk_component( 'MyApp', @ARGV );

1;
