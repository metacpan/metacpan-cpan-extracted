use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Rust;

use Path::Tiny qw( path );
use Env qw($RUSTUP_HOME);

alien_diag 'Alien::Rust';
alien_ok 'Alien::Rust';

if(Alien::Rust->needs_rustup_home) {
  $RUSTUP_HOME = Alien::Rust->rustup_home;

  if( Alien::Rust->install_type eq 'share' ) {
    my $rustup_home = path($RUSTUP_HOME);
    my $from_prefix = path(Alien::Rust->runtime_prop->{prefix});
    my $to_prefix   = path(Alien::Rust->dist_dir);
    if( $from_prefix->subsumes( $rustup_home ) ) {
      $RUSTUP_HOME = $rustup_home->relative( $from_prefix )->absolute($to_prefix)->stringify;
    }
  }
}

diag "RUSTUP_HOME = $RUSTUP_HOME";

 run_ok([ qw(rustc --version) ])
   ->success
   ->out_like(qr/^rustc ([0-9\.]+)/);

 run_ok([ qw(cargo --version) ])
   ->success
   ->out_like(qr/^cargo [0-9\.]+/);

done_testing;
