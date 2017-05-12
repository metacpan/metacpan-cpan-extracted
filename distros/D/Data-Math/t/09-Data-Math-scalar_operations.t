# Perl test file, can be run like so:
#   perl 06-Data-Math-scalar_operations.t
#         jbrenner@ffn.com     2014/09/15 21:1g7:44

use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::MoreUtils qw( any );

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Data::Math' );

{
  my $test_name = "Testing calc '-' on scalars";
  my $dm = Data::Math->new();

  my $gross = 100;
  my $cost  =  25;

  my $profit = $dm->calc( '-', $gross, $cost );
  #print STDERR "profit: ", Dumper( $profit ), "\n";

  my $exp = 75;

  is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}

{
  my $test_name = "Testing calc '+' on scalars";
  my $dm = Data::Math->new();

  my $cost1 = 100;
  my $cost2  =  25;

  my $profit = $dm->calc( '+', $cost1, $cost2 );

  my $exp = 125;

  is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}


{
  my $test_name = "Testing calc '+' on scalars with one undef";
  my $dm = Data::Math->new();

  my $cost1 = 100;
  my $cost2  =  undef;

  my $profit = $dm->calc( '+', $cost1, $cost2 );

  my $exp = 100;

  is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}


{
  my $test_name = "Testing calc '+' on scalars with other undef";
  my $dm = Data::Math->new();

  my $cost1 = undef;
  my $cost2  =  25;

  my $profit = $dm->calc( '+', $cost1, $cost2 );

  my $exp = 25;

  is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}

{
  my $test_name = "Testing calc '+' on scalars with both undef";
  my $dm = Data::Math->new();

  my $cost1  =  undef;
  my $cost2  =  undef;

  my $profit = $dm->calc( '+', $cost1, $cost2 );

  my $exp = 0;

  is_deeply( $profit, $exp, "$test_name:" )
          or print STDERR "profit: ", Dumper( $profit ), "\n";
}


done_testing();
