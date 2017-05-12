# *%) $Id: test.pl,v 1.1.1.1 2004/05/25 01:34:52 scottz Exp $

use lib './lib';
use Bio::SAGE::Comparison;
use strict;

print "Creating new Bio::SAGE::Comparison instance...\n";
my $sage = Bio::SAGE::Comparison->new();
print "  ...complete.\n";

print "Creating a fake tag data files...\n";

# create a fake FASTA sequence file
open( SCRIPT, $0 ) || die( "Couldn't open this script: $0" );
open( TAG1, '>fakelib1.tags' ) || die( "Could create file fakelib1.tags" );
my $bParsing = 0;
while( my $line = <SCRIPT> ) {
  chomp( $line ); $line =~ s/\r//g;
  if( $line =~ /^\/\/ START_LIBRARY$/ ) {
    $bParsing = 1; next;
  }
  if( $line =~ /^\/\/ END_LIBRARY$/ ) {
    $bParsing = 0; last;
  }
  if( $bParsing == 1 ) {
    print TAG1 $line . "\n";
  }
}
close( TAG1 );
open( TAG2, '>fakelib2.tags' ) || die( "Could create file fakelib2.tags" );
$bParsing = 0;
while( my $line = <SCRIPT> ) {
  chomp( $line ); $line =~ s/\r//g;
  if( $line =~ /^\/\/ START_LIBRARY$/ ) {
    $bParsing = 1; next;
  }
  if( $line =~ /^\/\/ END_LIBRARY$/ ) {
    $bParsing = 0; last;
  }
  if( $bParsing == 1 ) {
    print TAG2 $line . "\n";
  }
}
close( TAG2 );
close( SCRIPT );

print "  ...complete.\n";

print "Inputting fake tag files...\n";

# read the fake file in
open( FAKETAGS1, 'fakelib1.tags' ) || die( "Could not open file fakelib1.tags" );
$sage->add_library( 'LIB1', $sage->load_library( *FAKETAGS1 ) );
close( FAKETAGS1 );
unlink( 'fakelib1.tags' );
open( FAKETAGS2, 'fakelib2.tags' ) || die( "Could not open file fakelib2.tags" );
$sage->add_library( 'LIB2', $sage->load_library( *FAKETAGS2 ) );
close( FAKETAGS2 );
unlink( 'fakelib2.tags' );

print "Getting library labels...\n";
foreach my $l ( $sage->get_library_labels() ) {
  print "  " . $l . "\n";
}
print "  ...complete.\n";

print "Getting library sizes...\n";
print "  LIB1 = " . $sage->get_library_size( 'LIB1' ) . "\n";
print "  LIB2 = " . $sage->get_library_size( 'LIB2' ) . "\n";
print "  ...complete.\n";

print "Calculating and printing comparison...\n";
print $sage->print_library_comparison( $sage->get_library_comparison( 'LIB1', 'LIB2' ) );
print "  ...complete.\n";

print "Tests completed successfully.\n";

exit( 0 );

=pod

=for comment

// START_LIBRARY
AAAAAAAAAAA	100
AAACAGAGTAA	50
GATACAGATAA	10
CCAGATAGGCC	2
// END_LIBRARY

// START_LIBRARY
AAAAAAAAAAA	80
AAACAGAGTAA	60
GATACAGATAA	9
CCAGATAGGCC	2
TAGAGACCAAA	5
// END_LIBRARY

=cut
