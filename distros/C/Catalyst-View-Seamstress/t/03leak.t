#!/usr/bin/perl

# check that the changes to stop this view leaking worked (and stay working!)

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Spec;

eval('require Devel::Leak' );

if ( $@ ) {
    plan 'skip_all' => 'No Devel Leak' ;
    exit;
}

eval( 'require Catalyst::Test;' );

if ( $@ ) {
    plan 'skip_all' => 'No Catalyst::Test' ;
    exit;
}

plan 'tests' => 2;
my $stderr;

eval(qq{ use Catalyst::Test 'TestApp'; } );
my $handle;

#
# So Devel::Leak makes a lot of NOISE which obscures cpan testers reports,
# hence the stderr on/off business. It's worth defusing those occasionally to make sure this isn't
# masking any REAL stderr/stdout output!
#

stderrOFF();
my $count = Devel::Leak::NoteSV( $handle );
get( 'index.html' );
my $count2 = Devel::Leak::CheckSV( $handle );
stderrON();

# If this isn't working then...
ok( $count2 > $count, 'Leak is seeing us allocate resources' );

stderrOFF();
Devel::Leak::NoteSV( $handle );
# Make 100 requests for index.html!
get( 'index.html' ) for( 1..100 );
stderrON();

my $count3 = Devel::Leak::CheckSV( $handle );
ok( $count3 <= $count2 , 'Making 100 requests didn\'t inflate the object count' )
    or diag( "$count3 vs $count2" );



sub stderrOFF{
    $stderr = \*STDERR;
    open STDERR, '>', File::Spec->devnull;
}
sub stderrON{
    close(*STDERR);
    *STDERR = $stderr;
}
