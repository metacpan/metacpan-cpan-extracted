package # hide from PAUSE
  Algorithm::SpatialIndex::Test;
use parent 'Exporter';
use JSON ();

our @EXPORT = qw(test_redis_config);

sub test_redis_config {
  open my $fh, "<", "test_redis_config" or return();
  local $/;
  my $str = <$fh>;
  my $config;
  my $j = JSON->new;
  $j->relaxed(1);
  $config = $j->decode($str) if defined $str;
  close $fh;
  return $config;
}

1;

