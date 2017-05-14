use warnings;
use Data::Dumper;
use Test::More;
use Bio::Gonzales::Util::YAML;
use Bio::Gonzales::Util qw/slice/;

BEGIN {
  eval "use Bio::Perl";
  plan skip_all => "bioperl equired for testing" if $@;

  eval "use Bio::SeqIO::fastq";

  use_ok('Bio::Gonzales::Seq::IO::fastq');
}

my $o = Bio::Gonzales::Seq::IO::fastq->new( variant => 'solexa' );
#my $t = Bio::SeqIO::fastq->new(-variant => 'solexa');
#freeze_file("t/Bio-Gonzales-Seq-IO-fastq.solexa.ref.cache.yml", { slice(\%{$t}, qw/phred_int2chr phred_fp2chr sol2phred qual_start qual_end qual_offset chr2qual qual2chr/)});
my $cache = thaw_file('t/Bio-Gonzales-Seq-IO-fastq.solexa.ref.cache.yml');

{
  my %c2q;
  my @c2q = @{ $o->cache->{c2q} };
  for ( my $i = 0; $i < @c2q; $i++ ) {
    if ( defined( $c2q[$i] ) ) {
      $c2q{ chr($i) } = $c2q[$i];
    }
  }
  is_deeply( \%c2q, $cache->{chr2qual} );
}

{
  my %q2c;
  my @q2c = @{ $o->cache->{q2c} };
  for ( my $i = 0; $i < @q2c; $i++ ) {
    if ( defined( $q2c[$i] ) ) {
      $q2c{ $o->cache->{q_start} + $i } = $q2c[$i];
    }
  }
  is_deeply( \%q2c, $cache->{qual2chr} );
}

{
  my %phred_int2chr;
  my @phred_int2chr = @{ $o->cache->{phred_int2chr} };
  for ( my $i = 0; $i < @phred_int2chr; $i++ ) {
    if ( defined( $phred_int2chr[$i] ) ) {
      $phred_int2chr{ $o->cache->{q_start} + $i } = $phred_int2chr[$i];
    }
  }
  is_deeply( \%phred_int2chr, $cache->{phred_int2chr} );
}

{
  my %phred_fp2chr = %{ $o->cache->{phred_fp2chr} };
  is_deeply( \%phred_fp2chr, $cache->{phred_fp2chr} );
}

#phred_int2chr
#phred_fp2chr
#sol2phred
#qual_start
#qual_end
#qual_offset
#chr2qual
#qual2chr

#diag Dumper $o;
#diag Dumper $t;

done_testing();

