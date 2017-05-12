#!/usr/bin/perl -w
# $Author: astoltzfus $
# $Date: 2010/09/22 19:59:57 $
# $Revision: 1.4 $

use strict;
use Carp;
use Getopt::Long;
use Pod::Usage; 

my $nada = "";
my $Id = "";
my $version = "$Id: tree2nex.pl,v 1.4 2010/09/22 19:59:57 astoltzfus Exp $nada"; 

Getopt::Long::Configure("bundling"); # for short options bundling
my %opts = ();
GetOptions( \%opts, 'format|f=s', 'treename|t=s', 'version|V', 'man', 'help|h' ) or pod2usage(2);
if ( $opts{ 'version' } ) { die "Version$version\n"; } 
pod2usage( -exitval => 0, verbose => 2 ) if $opts{ man };
pod2usage( 1 ) if !@ARGV or $opts{ help };

my $treeName = ( $opts{ 'treename' } ?  $opts{ 'treename' } : 'default' ); 
my $i = 0; 
my $treeString = "";
my @treeStrings = (); 

while ( <> ) { 
    chomp;
    s/\s+$//;
    if ( s/([^;]*;)(.*)$/$2/ ) { 
	push( @treeStrings, $treeString.$1 ); 
	$treeString = "";
	$i++; 
    }
    $treeString .= $_; 
}

printf( "#nexus\nbegin trees;\n" );

#
# note: need to implement option for named trees?  if so, then 
#  change below to make tree = $treeName dependent on whether 
#  tree already has a name 
# 
if ( $#treeStrings == 0 ) { 
    printf( "tree $treeName = %s\n", $treeStrings[0] );
}
else { 
    for ( $i = 0; $i <= $#treeStrings; $i++ ) { 
	printf( "tree $treeName%d = %s\n", $i+1, $treeStrings[$i] ); 
    } 
}
printf( "end;\n" );
exit;

=head1 NAME

tree2nex.pl - translate a tree in DND or phylip format into NEXUS TREES block

=head1 SYNOPSIS

tree2nex.pl [options] <infile> 

=head1 DESCRIPTION

Output the tree in <infile> in NEXUS format.  This is currently implemented 
outside the NEXUS package.  It should be re-implemented with NEXUS objects 
and with the capacity to output a TAXA block using the OTU list from 
TreesBlock->get_OTUlist.  But some changes need to be made to the NEXUS 
package first.   

=head1 OPTIONS

=over 8

=item B<-f, --format> 

The format of the input file.  Not implemented. 

=item B<-t, --treename> 

The name to be assigned to this tree in a NEXUS TREES block. 

=item B<-h, --help> 

Print a brief help message and exits.

=item B<--man> 

Print the manual page and exits.

=item B<-V, --version> 

Print the version information and exit.

=back

=head1 VERSION

$Id: tree2nex.pl,v 1.4 2010/09/22 19:59:57 astoltzfus Exp $

=head1 AUTHOR

Arlin Stoltzfus (stoltzfu@umbi.umd.edu)

=cut
