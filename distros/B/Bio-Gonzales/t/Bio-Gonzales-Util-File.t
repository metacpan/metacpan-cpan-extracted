use warnings;
use Test::More;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use File::Temp qw/tempfile tmpnam tempdir/;
use File::Which;
use Bio::Gonzales::Util::Cerial;


BEGIN { use_ok( 'Bio::Gonzales::Util::File', 'slurpc' ); }

my $tmpdir = tempdir( CLEANUP => 1 );


{
  my $linesa = slurpc_old("t/data/mini.fasta");
  my $linesb = slurpc("t/data/mini.fasta");
  is_deeply( $linesa, $linesb );
}

SKIP: {
  my $gzip_bin = which('gzip');
  skip "no gzip executable found", 1 unless $gzip_bin;

  my $tempfn = catfile($tmpdir, '1.gz');

  diag $gzip_bin;
  my $ofh = Bio::Gonzales::Util::File::_pipe_z($gzip_bin, $tempfn, '>' );


  open my $ifh, '<', 't/data/mini.fasta' or die "Can't open filehandle: $!"; # check
  my @lines = <$ifh>;
  $ifh->close;

  for my $l (@lines) {
    print $ofh $l;
  }
  $ofh->close;

  my $linesa = slurpc("t/data/mini.fasta");
  open my $fh, '-|', $gzip_bin, '-dc', $tempfn or die "Can't open filehandle: $!"; #check
  my @linesb = map { chomp; $_ } <$fh>;
  $fh->close;
  is_deeply(\@linesb, $linesa );
}

SKIP: {
  my $gzip_bin = which('gzip');
  skip "no gzip executable found", 2 unless $gzip_bin;

  my $tempfn = catfile($tmpdir, '2.gz');


  $Bio::Gonzales::Util::File::EXTERNAL_GZ = $gzip_bin;

  my $ofh = Bio::Gonzales::Util::File::open_on_demand($tempfn, '>' );
  isnt(ref $ofh, 'IO::Zlib');

  open my $ifh, '<', 't/data/mini.fasta' or die "Can't open filehandle: $!"; # check
  my @lines = <$ifh>;
  $ifh->close;

  for my $l (@lines) {
    print $ofh $l;
  }
  $ofh->close;

  my $linesa = slurpc("t/data/mini.fasta");
  open my $fh, '-|', $gzip_bin, '-cd', $tempfn or die "Can't open filehandle: $!"; #check
  my @linesb = map { chomp; $_ } <$fh>;
  is_deeply( $linesa, \@linesb );
  $fh->close;
}

{
  my $tempfn = catfile($tmpdir, '3.gz');

  undef $Bio::Gonzales::Util::File::EXTERNAL_GZ;
  my $ofh = Bio::Gonzales::Util::File::open_on_demand($tempfn, '>' );
  is(ref $ofh, 'IO::Zlib');

  open my $ifh, '<', 't/data/mini.fasta' or die "Can't open filehandle: $!"; #check
  my @lines = <$ifh>;
  $ifh->close;

  for my $l (@lines) {
    print $ofh $l;
  }
  $ofh->close;

  my $linesa = slurpc("t/data/mini.fasta");
  open my $fh, '-|', 'gunzip', '-c', $tempfn or die "Can't open filehandle: $!"; #check
  my @linesb = map { chomp; $_ } <$fh>;
  $fh->close;
  is_deeply( $linesa, \@linesb );
  unlink $tempfn;
}
{
  my $tempfn = catfile($tmpdir, '4.gz');

  undef $Bio::Gonzales::Util::File::EXTERNAL_GZ;
  my $ofh = Bio::Gonzales::Util::File::open_on_demand($tempfn, '>' ); #check
  is(ref $ofh, 'IO::Zlib');

  open my $ifh, '<', 't/data/mini.fasta' or die "Can't open filehandle: $!"; #check
  my @lines = map { chomp; $_ } <$ifh>;
  $ifh->close;

  jspew($ofh, \@lines);

  $ofh->close;

  my $linesa = slurpc("t/data/mini.fasta");
  open my $fh, '-|', 'gunzip', '-c', $tempfn or die "Can't open filehandle: $!"; #check
  my $linesb = do { local $/; <$fh> };
  $fh->close;
  $linesb = jthaw($linesb);
  is_deeply( $linesb,$linesa );
  unlink $tempfn;
}

sub slurpc_old {
  my @lines;
  open my $fh, '<', $_[0] or die "Can't open filehandle: $!"; #check
  while (<$fh>) {
    chomp;
    push @lines, $_;
  }
  $fh->close;

  return wantarray ? @lines : \@lines;
}

done_testing();
