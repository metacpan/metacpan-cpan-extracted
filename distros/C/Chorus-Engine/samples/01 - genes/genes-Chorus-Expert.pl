use Chorus::Expert;
use GenesExpert;

my $jean = Chorus::Frame->new ();
my $mary = Chorus::Frame->new ();
my $marc = Chorus::Frame->new ();

$marc->set(
     NAME   => 'Marc',
   	 father => $jean,
   	 mother => $mary
);

$jean->set(
     NAME   => 'Jean',
   	 father => {	
   	   eyes => { color => 'blue' }
   	 },
   	 
   	 mother => {	
   	   eyes => { color => 'blue' } 
   	 }
);
   
$mary->set(eyes => { color => 'brown'} );

Chorus::Expert->new()->register($GenesExpert::agent)->process(); # no argument (agent will use fmatch)
