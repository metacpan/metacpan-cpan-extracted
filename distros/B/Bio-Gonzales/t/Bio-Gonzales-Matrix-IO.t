use warnings;
use Test::More;
use Data::Dumper;
use IO::Scalar;
use Test::Exception;

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;

  use_ok( "Bio::Gonzales::Matrix::IO", 'miterate', 'mslurp', 'mspew', 'dict_slurp' );
}

my $data = <<EOD;
a\tb\tc
#d\te\tf

nix
EOD

{
  my $sh = new IO::Scalar \$data;

  my $mit = miterate($sh);
  is_deeply( $mit->(), [ 'a', 'b', 'c' ], 'first line' );
  is( $mit->()->[0], 'nix', 'second line' );
  is( $mit->(),      undef, 'last line' );

  $sh->close;
}
{
  my $sh = new IO::Scalar \$data;

  my $mit = miterate( $sh, { skip => 1 } );
  is_deeply( $mit->(), ['nix'], 'first line' );
  is( $mit->(), undef, 'second line' );

  $sh->close;
}

{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m = mslurp( $sh, { col_idx => [ 0, 2 ] } );
  $sh->close;
  is_deeply( $m, [ [ 1, 3 ], [ 5, 7 ] ] );
}

{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m  = mslurp($sh);
  $sh->close;
  is_deeply( $m, [ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ] ] );
}
{
  my $data;
  my $sh = IO::Scalar->new( \$data );
  my $fh = \*STDOUT;
  my $m  = mspew( $fh, [], { header => [qw/a b/] } );
  #is_deeply($m, [[1,2,3,4],[5,6,7,8]]);
}
{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m = dict_slurp( $sh, { key_idx => 1, val_idx => 0 } );
  $sh->close;
  is_deeply( $m, { 2 => [1], 6 => [5] } );
}
{
  my $data = <<EOF;
c1;c2
a;a1
b;b1
c;c1
c;c2
EOF
  my $sh = IO::Scalar->new( \$data );
  dies_ok {dict_slurp( $sh, { key_idx => 0, val_idx => 1, uniq => 1, strict => 1, sep => ';' } )};
  $sh->close;
  my $sh2 = IO::Scalar->new( \$data );
  my $m = dict_slurp( $sh2, { key_idx => 0, val_idx => 1, uniq => 1, strict => 0, sep => ';' } );
  $sh2->close;
  is_deeply( $m, { c1 => 'c2', a => 'a1', b => 'b1', c => 'c2' } );
}
{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m = dict_slurp( $sh, { key_idx => 1, val_idx => [ 0, 2 ] } );
  $sh->close;
  is_deeply( $m, { 2 => [ [ 1, 3 ] ], 6 => [ [ 5, 7 ] ] } );
}
{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m = dict_slurp( $sh, { key_idx => 1, val_idx => [ 0, 2 ], uniq => 1 } );
  $sh->close;
  is_deeply( $m, { 2 => [ 1, 3 ], 6 => [ 5, 7 ] } );
}

{
  my $data = <<EOF;
1\t2\t3\t4
5\t6\t7\t8
EOF
  my $sh = IO::Scalar->new( \$data );
  my $m  = dict_slurp(
    $sh,
    {
      key_idx       => 1,
      val_idx       => [ 0, 2 ],
      uniq          => 1,
      record_filter => sub { $_[0] =~ /3/ }
    }
  );
  $sh->close;
  is_deeply( $m, { 2 => [ 1, 3 ] } );
}

done_testing();

