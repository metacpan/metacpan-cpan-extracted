package App::MyProve;

use Moo;
use File::Which;

sub run {
  my $prove = which('prove');
  my $myperl = which('myperl');
  exec($^X, $prove, '--exec', $myperl, @ARGV);
}

sub run_if_script {
  return 1 if caller(1);
  return shift->new->run;
}

1;
