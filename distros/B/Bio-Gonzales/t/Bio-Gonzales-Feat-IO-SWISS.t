use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Bio::Gonzales::Feat::IO::SWISS'); }

my $swissin = Bio::Gonzales::Feat::IO::SWISS->new("t/data/uniprot_trembl.dat");

my %acc = (
  A0A171 => 1,
  A0AQI4 => 1,
  A0AQI5 => 1,
  A0AQI7 => 1,
  A0AQI8 => 1,
  A0EQA2 => 1,
  A0FGX9 => 1,
  A0FGY0 => 1,
  A0FGY1 => 1,
  A0FGY2 => 1,
  A0FGY3 => 1,
  A0FGY4 => 1,
  A0FGY6 => 1,
  A0FGY8 => 1,
  A0FGZ0 => 1,
  A0FGZ1 => 1,
  A0FGZ2 => 1,
  A0FGZ3 => 1,
  A0FGZ4 => 1,
  A0FGZ8 => 1,
  A0FGZ9 => 1,
  A0FH00 => 1,
  A0FH02 => 1,
  A0FH03 => 1,
  F8VC58 => 1
);

my %feats;
while ( my $f = $swissin->next_feat ) {
  #diag Dumper $f;
  ok( !exists( $feats{ $f->id } ) );
  $feats{ $f->id } = $f;
  $acc{ $f->id }++;
}

is( ( grep { $_ > 1 } values %acc ), ( scalar keys %acc ) );

#my @entries;
#{
#local $/ = "\n//\n";
#open my $fh, '<', '' or die "Can't open filehandle: $!";
#while (<$fh>) {
#push @entries, $_;
#}
#close $fh;
#}

#my $res = Bio::Gonzales::Feat::IO::SWISS::Parse_entry(\$entries[-1]);

#diag Dumper $res;

#diag Dumper $res->attr_list('accession_number');
done_testing();

