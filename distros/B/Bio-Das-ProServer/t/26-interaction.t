use Test::More tests => 1;
my $sa = SA::InteractionStub->new();
my $expected_response = q(<INTERACTOR intId="001" shortLabel="Interacting protein one" dbSource="FooDB" dbAccessionId="Prot001" dbCoordSys="Foo,Protein Sequence" dbVersion="42"><SEQUENCE>MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSNSKS</SEQUENCE></INTERACTOR><INTERACTOR intId="002" shortLabel="Interacting protein two" dbSource="FooDB" dbAccessionId="Prot002" dbCoordSys="Foo,Protein Sequence" dbVersion="42"><DETAIL property="description" value="Small protein"/><SEQUENCE>MGVPCLVWCFAVLLCVWGALCAAEDDYGEDDYEGFSSQ</SEQUENCE></INTERACTOR><INTERACTION name="Cuddle interaction" dbSource="CuteDB" dbAccessionId="001-002" dbVersion="3.2"><PARTICIPANT intId="001"><DETAIL property="region" value="donor"><RANGE start="4" end="8"/></DETAIL></PARTICIPANT><PARTICIPANT intId="002"><DETAIL property="region" value="acceptor"><RANGE start="12" end="14"/></DETAIL></PARTICIPANT></INTERACTION>);

my $response = $sa->das_interaction({
				   'interactors' => ['test'],
				  });

#fix screwed up line-endings somewhere
$expected_response =~ s/[\r\n]+/\n/smg;
$response          =~ s/[\r\n]+/\n/smg;

is_deeply($response, $expected_response, "interactions");


package SA::InteractionStub;
use base qw(Bio::Das::ProServer::SourceAdaptor);

sub build_interaction {
  my $self = shift;

  my @interactors = ();
  my @interactions = ();
  while(my $line = <DATA>) {
    chomp $line;
    my @parts = split(/\s{2,}/, $line);
    if ($line =~ m/^\d+/) {
      my $ref   = {};
      for my $f (qw(id label dbSource dbVersion dbAccession dbCoordSys sequence)) {
        $ref->{$f} = shift @parts;
      }
      while (@parts) {
        push @{ $ref->{'details'} }, {
                                      'property' => shift @parts,
                                      'value'    => shift @parts,
                                     };
      }
      push @interactors, $ref;
    }
    else {
      my $ref   = {};
      for my $f (qw(label dbSource dbVersion dbAccession)) {
        $ref->{$f} = shift @parts;
      }
      for my $f (qw(property value)) {
        $ref->{'detail'}{$f} = shift @parts;
      }
      while (@parts) {
        push @{ $ref->{'participants'} }, {
                                           'id'      => shift @parts,
                                           'details' => {
                                                         'property' => shift @parts,
                                                         'value'    => shift @parts,
                                                         'start'    => shift @parts,
                                                         'end'      => shift @parts,
                                                        },
                                          };
      }
      push @interactions, $ref;
    }
  }
  
  my $struct = { 'interactions' => \@interactions, 'interactors' => \@interactors };
  return $struct;
}

1;

__DATA__
001  Interacting protein one  FooDB  42  Prot001  Foo,Protein Sequence  MILWSPSTCSFFWHWCLIAVSVLSSRSKESLRLSWSSDESSASSSSRICPLSNSKS
002  Interacting protein two  FooDB  42  Prot002  Foo,Protein Sequence  MGVPCLVWCFAVLLCVWGALCAAEDDYGEDDYEGFSSQ  description  Small protein
Cuddle interaction  CuteDB  3.2  001-002  type  cuddle  001  region  donor  4  8  002  region  acceptor  12  14
