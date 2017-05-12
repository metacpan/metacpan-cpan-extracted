use Test::More tests => 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Astro::QDP::Parse ':all';

use Cwd;

require Data::Dumper;

my $qdpfile = 'data/phvavn1.qdp';
die "Can't read qdpfile >$qdpfile<"
  unless -e $qdpfile;

my $lines = read_qdpfile( $qdpfile );

is( scalar @$lines, 66, "no. of lines" );
is( $lines->[65], 
   '2.91269994 0.0657000542 -5.22391474E-6 6.65455591E-5 7.86789315E-6 -0.196734503 1',
   "last line" );
      
