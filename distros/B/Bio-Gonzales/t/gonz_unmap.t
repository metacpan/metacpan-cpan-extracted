use warnings;
use Test::More;
use Data::Dumper;
use File::Temp qw/tempfile tmpnam tempdir/;
use File::Spec::Functions qw/catfile/;
use Bio::Gonzales::Matrix::IO;

my $tmpdir = tempdir( CLEANUP => 1 );

{
  open my $fh, '>', catfile( $tmpdir, 'data.tsv' ) or die "Can't open filehandle: $!";
  say $fh "aglF";
  $fh->close;

  system( $^X,
    qw(bin/gonz_unmap.pl -k 4 -v 1 -m 0 t/data/map.tsv),
    catfile( $tmpdir, 'data.tsv' ),
    catfile( $tmpdir, 'data.map.tsv' )
  );
  my $f = catfile( $tmpdir, 'data.map.tsv' );

  open my $res_fh, '<', $f or die "Can't open filehandle: $!";
  my @res = map { chomp; $_ } <$res_fh>;
  $res_fh->close;

  is_deeply( \@res, ['AGLF_HALVD'] );
}

{
  open my $fh, '>', catfile( $tmpdir, 'data.tsv' ) or die "Can't open filehandle: $!";
  say $fh "aglF";
  $fh->close;

  system( $^X,
    qw(bin/gonz_unmap.pl --multi -k 4 -v 1 -m 0 t/data/map.tsv),
    catfile( $tmpdir, 'data.tsv' ),
    catfile( $tmpdir, 'data.map.tsv' )
  );
  my $f = catfile( $tmpdir, 'data.map.tsv' );

  open my $res_fh, '<', $f or die "Can't open filehandle: $!";
  my @res = map { chomp; $_ } <$res_fh>;
  $res_fh->close;

  is_deeply( \@res, [ 'AGLF_HALVD', 'AGLX_HALVD' ] );
}

done_testing();

