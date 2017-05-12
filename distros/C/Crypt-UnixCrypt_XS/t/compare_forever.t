use Test::More  skip_all => "your machine is to slow for that much tests";

# feeling boring? run this test for years ;-)
#use Test::More qw/no_plan/;    # eigentlich 58 ** 13 but this is too large

BEGIN { use_ok "Crypt::UnixCrypt_XS"; }

SKIP: {
  eval { require Algorithm::Loops };
  skip "Algorithm::Loops is not installed" if $@;

  my @chars = ( "a" .. "z", "A" .. "Z", 0 .. 9 );

  my $depth = 13;
  Algorithm::Loops::NestedLoops(
    [ ( [ 0 .. $#chars ] ) x $depth, ],
    sub {
      my ( $passwd, $salt ) = join( '', @chars[@_] ) =~ /(.{11})(..)/;
      ok(
          crypt( $passwd, $salt ) eq
            Crypt::UnixCrypt_XS::crypt( $passwd, $salt ),
          $0
      );
    }
  );
}
