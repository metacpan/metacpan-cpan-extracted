use vars qw/ @simplebin_cols/;

@simplebin_cols = my @cols = qw/ rt_x rt_y rt_z rt_kev /;


sub chk_simplebin_piddles
{
  my ( $msg, @pdls ) = @_;

  my $idx = 0;
  foreach my $pdl ( @pdls )
  {
    my $name = $cols[$idx++];

    ok( eq_array ( [ $pdl->dims], [ 20 ] ), "$msg: $name dims" );
    ok( ($pdl == PDL->sequence(20) * $idx)->all, 
	"$msg: $name values" );
  }

}


1;
