use Test::More tests => 3;
my $sa = SA::Stub->new();
my $expected_responses = {
  'EMD1017' => q(<VOLMAP id="EMD1017" class="volume_map" type="ccp4" version="1.0"><LINK href="ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1017/map/emd_1017.map.gz">ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1017/map/emd_1017.map.gz</LINK></VOLMAP><NOTE>This is the only note.</NOTE>),
  'EMD1018' => q(<VOLMAP id="EMD1018" class="volume_map" type="ccp4" version="1.0"><LINK href="ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1018/map/emd_1018.map.gz">Link to data</LINK></VOLMAP>),
  'EMD1019' => q(<VOLMAP id="EMD1019" class="volume_map" type="ccp4" version="1.0"><LINK href="ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1019/map/emd_1019.map.gz">Link to data</LINK></VOLMAP><NOTE>This is note number one.</NOTE><NOTE>This is note number two.</NOTE>),
};


#open(my $o1, ">out1"); print $o1 $expected_response; close($o1);
#open(my $o2, ">out2"); print $o2 $sa->das_alignment->({'query'=>'PF08001'}); close($o2);
for my $query (qw(EMD1017 EMD1018 EMD1019)) {
  my $response = $sa->das_volmap( {'query'=>$query} );
  my $expected_response = $expected_responses->{$query};
  is_deeply($response, $expected_response, "volmap-$query");
}

package SA::Stub;
use base qw(Bio::Das::ProServer::SourceAdaptor);

sub build_volmap {
  my $self = shift;
  my $query = shift;
  
  my $templates = {
    'EMD1017' => {
      'link' => 'ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1017/map/emd_1017.map.gz',
      'note' => 'This is the only note.',
    },
    'EMD1018' => {
      'link'    => 'ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1018/map/emd_1018.map.gz',
      'linktxt' => 'Link to data',
    },
    'EMD1019' => {
      'link'    => {
		    'ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-1019/map/emd_1019.map.gz',
		    'Link to data',
		   },
      'note'    => [
	            'This is note number one.',
		    'This is note number two.',
		   ],
    },
  };
  
  return undef unless exists $templates->{$query};
  my $struct = $templates->{$query};
  $struct->{'id'}      = $query;
  $struct->{'class'}   = 'volume_map';
  $struct->{'type'}    = 'ccp4';
  $struct->{'version'} = '1.0';
  
  return $struct;
}

1;

