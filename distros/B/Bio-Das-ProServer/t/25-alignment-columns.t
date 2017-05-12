use Test::More tests => 6;
use strict;

my $sa;
my $basic_template = qq(<alignment name="PF08001" alignType="PfamFull" max="1">
  <alignObject objectVersion="7742c75899e7887415b4ffc42eaf7477" intObjectId="Q80KP4" dbSource="Pfam" dbVersion="20.0" dbAccessionId="PF08001" dbCoordSys="UniProt,Protein Sequence">
    <sequence>MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSDSKSVRLPQYPRGFEDVSGYRVSSSVSECYVQHGVLVAAWLVRGNFSDTAPRAYGTWGNERSATHFKVGAPQLENDGALRYETELPQVDARLSYVMLTVYPCSACNRSVLHCRPASRLPWLPLRATPSDLERLFAERRYLTFLYVVLVQFVKHVALFSFGVQVACCVYLRWIRPWVRGRHRATGRTSREEEAKDD</sequence>
  </alignObject>
  <alignObject objectVersion="c20988ce56202bec5d7cee2985a1d1a6" intObjectId="Q7TD97" dbSource="Pfam" dbVersion="20.0" dbAccessionId="PF08001" dbCoordSys="UniProt,Protein Sequence">
    <sequence>NSVDNLRRLHYEYRHLELGVVIAIRMAMVLLLGYVLARTVYHVSSAYYLRWHACVPQKCEKSLC</sequence>
  </alignObject>
%BLOCKS
</alignment>\n);
my $blocks_template = q(  <block blockOrder="1">
    <segment intObjectId="Q80KP4" start="%START1" end="%END1">
      <cigar>%CIGAR1</cigar>
    </segment>
    <segment intObjectId="Q7TD97" start="%START2" end="%END2">
      <cigar>%CIGAR2</cigar>
    </segment>
  </block>);

my $response;
my $expected_response;

my $template = $basic_template;
$template =~ s/%BLOCKS/$blocks_template/;

$expected_response = $template;
$expected_response =~ s/%CIGAR1/7M8D7M2D7M6I6MI2M2I2M2D3M4I19MI10M5I10MI20M4D31M2I3MIM5I24MID17MD23MI5M3D2M2D5M2DID9M5I5MD3M2D4M/;
$expected_response =~ s/%CIGAR2/31D6I6DI2D2I7D4I5D5I9D2I9D5ID5I4DI14D3I38D2I3DID5I18D2I4DI14D4MD23MI10M4D5MI10M5I5MD3M2D4M/;
$expected_response =~ s/%START1/12/;
$expected_response =~ s/%END1/236/;
$expected_response =~ s/%START2/1/;
$expected_response =~ s/%END2/64/;
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['test'],
                                   'cols'    => '1-290',
                                  });
is_deeply($response, $expected_response, "full alignment");

$expected_response = $template;
$expected_response =~ s/%CIGAR1/7M8D7M2D7M6I6MI2M2I2M2D3M4I19MI10M5I10MI20M4D31M2I3MIM5I24MID17MD23MI5M3DM/;
$expected_response =~ s/%CIGAR2/31D6I6DI2D2I7D4I5D5I9D2I9D5ID5I4DI14D3I38D2I3DID5I18D2I4DI14D4MD23MI9M/;
$expected_response =~ s/%START1/12/;
$expected_response =~ s/%END1/209/;
$expected_response =~ s/%START2/1/;
$expected_response =~ s/%END2/36/;
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['test'],
                                   'cols'    => '1-249',
                                  });
is_deeply($response, $expected_response, "left side alignment, cut in match");

$expected_response = $template;
$expected_response =~ s/%CIGAR1/D5M2DID9M5I5MD3M2D4M/;
$expected_response =~ s/%CIGAR2/3D5MI10M5I5MD3M2D4M/;
$expected_response =~ s/%START1/211/;
$expected_response =~ s/%END1/236/;
$expected_response =~ s/%START2/38/;
$expected_response =~ s/%END2/64/;
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['test'],
                                   'cols'    => '252-290',
                                  });
is_deeply($response, $expected_response, "right side alignment, cut in gap");

$expected_response = $template;
$expected_response =~ s/%CIGAR1/16MD23MI5M3D2MD/;
$expected_response =~ s/%CIGAR2/12D4MD23MI10MD/;
$expected_response =~ s/%START1/165/;
$expected_response =~ s/%END1/210/;
$expected_response =~ s/%START2/1/;
$expected_response =~ s/%END2/37/;
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['test'],
                                   'cols'    => '200-251',
                                  });
is_deeply($response, $expected_response, "middle alignment, cut in match and gap");

$expected_response = $basic_template;
#multi   50M  11  60  50M        61  110 10I30M10I  111  140
#multi     .   .   .  20I10M20I   1  10  50M         11   60
my $block1 = q(  <block blockOrder="1">
    <segment intObjectId="Q80KP4" start="51" end="60">
      <cigar>10M</cigar>
    </segment>
  </block>);
my $block2 = q(  <block blockOrder="2">
    <segment intObjectId="Q80KP4" start="61" end="110">
      <cigar>50M</cigar>
    </segment>
    <segment intObjectId="Q7TD97" start="1" end="10">
      <cigar>20I10M20I</cigar>
    </segment>
  </block>);
my $block3 = q(  <block blockOrder="3">
    <segment intObjectId="Q80KP4" start="111" end="140">
      <cigar>10I30M5I</cigar>
    </segment>
    <segment intObjectId="Q7TD97" start="11" end="55">
      <cigar>45M</cigar>
    </segment>
  </block>);
$expected_response =~ s/%BLOCKS/$block1\n$block2\n$block3/;
 
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['multi'],
                                   'cols'    => '41-145',
                                  });
is_deeply($response, $expected_response, "multi part alignment");

$expected_response = $basic_template;
$block1 = q(  <block blockOrder="1">
    <segment intObjectId="Q80KP4" start="71" end="80" />
  </block>);
$block2 = q(  <block blockOrder="2">
    <segment intObjectId="Q80KP4" start="81" end="85" />
    <segment intObjectId="Q7TD97" start="1" end="5" />
  </block>);
$expected_response =~ s/%BLOCKS/$block1\n$block2/mxs;
$sa = SA::Stub->new();
$response = $sa->das_alignment({
                                   'queries' => ['nocigar'],
                                   'cols'    => '61-75',
                                  });
is_deeply($response, $expected_response, "changed block order, no cigars");

package SA::Stub;

use strict;
use base qw(Bio::Das::ProServer::SourceAdaptor);
our @data;

sub build_alignment {
  my ($self, $query, $rows, $subjects, $sub_coos, $cols) = @_;

  if (!@data) {
    for my $line (<DATA>) {
      chomp $line;
      my @parts = split(/\s+/, $line);
      my $ref   = { 'blocks' => [] };
      for my $f (qw(query pfamseq_acc pfamseq_id md5 sequence)) {
        $ref->{$f} = shift @parts;
      }
      while (@parts) {
        my $block = {};
        for my $key (qw(cigar seq_start seq_end)) {
          my $val = shift @parts;
          $block->{$key} = $val if ($val ne q(.));
        }
        push @{ $ref->{blocks} }, $block;
      }
      push @data, $ref;
    }
  }

  my @aliObjects;
  my @blocks;
  foreach my $row (@data) {
    $row->{'query'} eq $query || next;
      
    push(@aliObjects, { 'version' => $row->{'md5'},
                        'intID' => $row->{'pfamseq_acc'},
                        'dbSource' => "Pfam",
                        'dbVersion' => "20.0",
                        'coos' => "UniProt,Protein Sequence",
                        'accession' =>  "PF08001",
                        'sequence' => $row->{'sequence'}      });
    
    my @rowsegs = @{ $row->{'blocks'} };
    for (my $i=0; $i<@rowsegs; $i++) {
      my $seg = $rowsegs[$i];
      $blocks[$i] ||= {
                       'blockOrder' => $i+1,
                       'segments'   => [],
                      };
      $seg->{'seq_start'} || next;
      push @{ $blocks[$i]->{'segments'} }, {
        'cigar'    => $seg->{'cigar'},
        'objectId' => $row->{'pfamseq_acc'},
        'start'    => $seg->{'seq_start'},
        'end'      => $seg->{'seq_end'},
      };
    }
  }
  
  my @ali;
  my $ali = {
             'type' => "PfamFull",
             'name' => "PF08001",
             'max' => 1,
             'alignObj' => \@aliObjects,
             'blocks' => \@blocks,
             'scores' => undef,
             'geo3D' => undef, #Normally an array
            };
  $self->restrict_alignment_columns($ali, $cols);
  push @ali, $ali;

  return @ali;
}

1;

__DATA__
test    Q80KP4  Q80KP4_HCMV     7742c75899e7887415b4ffc42eaf7477        MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSDSKSVRLPQYPRGFEDVSGYRVSSSVSECYVQHGVLVAAWLVRGNFSDTAPRAYGTWGNERSATHFKVGAPQLENDGALRYETELPQVDARLSYVMLTVYPCSACNRSVLHCRPASRLPWLPLRATPSDLERLFAERRYLTFLYVVLVQFVKHVALFSFGVQVACCVYLRWIRPWVRGRHRATGRTSREEEAKDD  7M8D7M2D7M6I6MI2M2I2M2D3M4I19MI10M5I10MI20M4D31M2I3MIM5I24MID17MD23MI5M3D2M2D5M2DID9M5I5MD3M2D4M        12      236
test    Q7TD97  Q7TD97_HCMV     c20988ce56202bec5d7cee2985a1d1a6        NSVDNLRRLHYEYRHLELGVVIAIRMAMVLLLGYVLARTVYHVSSAYYLRWHACVPQKCEKSLC        31D6I6DI2D2I7D4I5D5I9D2I9D5ID5I4DI14D3I38D2I3DID5I18D2I4DI14D4MD23MI10M4D5MI10M5I5MD3M2D4M       1       64
multi   Q80KP4  Q80KP4_HCMV     7742c75899e7887415b4ffc42eaf7477        MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSDSKSVRLPQYPRGFEDVSGYRVSSSVSECYVQHGVLVAAWLVRGNFSDTAPRAYGTWGNERSATHFKVGAPQLENDGALRYETELPQVDARLSYVMLTVYPCSACNRSVLHCRPASRLPWLPLRATPSDLERLFAERRYLTFLYVVLVQFVKHVALFSFGVQVACCVYLRWIRPWVRGRHRATGRTSREEEAKDD  50M  11  60  50M        61  110 10I30M10I  111  140
multi   Q7TD97  Q7TD97_HCMV     c20988ce56202bec5d7cee2985a1d1a6        NSVDNLRRLHYEYRHLELGVVIAIRMAMVLLLGYVLARTVYHVSSAYYLRWHACVPQKCEKSLC                                                                                                                                                                                           .   .   .  20I10M20I   1  10  50M         11   60
nocigar Q80KP4  Q80KP4_HCMV     7742c75899e7887415b4ffc42eaf7477        MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSDSKSVRLPQYPRGFEDVSGYRVSSSVSECYVQHGVLVAAWLVRGNFSDTAPRAYGTWGNERSATHFKVGAPQLENDGALRYETELPQVDARLSYVMLTVYPCSACNRSVLHCRPASRLPWLPLRATPSDLERLFAERRYLTFLYVVLVQFVKHVALFSFGVQVACCVYLRWIRPWVRGRHRATGRTSREEEAKDD  .  11  60  .  61  80  .  81  90  .  91 110  .   .   .  .  111  140  .   .   .
nocigar Q7TD97  Q7TD97_HCMV     c20988ce56202bec5d7cee2985a1d1a6        NSVDNLRRLHYEYRHLELGVVIAIRMAMVLLLGYVLARTVYHVSSAYYLRWHACVPQKCEKSLC                                                                                                                                                                                         .   .   .  .   .   .  .   1  10  .   .   .  .  11  20  .   21   50  .  51  60