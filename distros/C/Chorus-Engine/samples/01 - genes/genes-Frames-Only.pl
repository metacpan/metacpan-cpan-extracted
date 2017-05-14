use strict;

use Chorus::Frame;

my $base = Chorus::Frame->new(
   character => {
      eyes => { 
      	 color => {
      	 	dominant => {
      	 		brown => 'y',
      	 		black => 'y'
      	 	},
      	 	recessive => {
      	 		blue => 'y',
      	 		green => 'y'
      	 	}
      	 }
      },
   }
);

my $family_member = Chorus::Frame->new(
    
   get_from_parents => sub {

      my $carac = shift;
      return undef unless $carac and $SELF->father and $SELF->mother;
      
      my $fromFather = $SELF->father->inherit($carac) or return undef;
      my $fromMother = $SELF->mother->inherit($carac) or return undef;
   	    	  
      if($base->get($carac)->dominant->$fromFather) {
   	if ($base->get($carac)->dominant->$fromMother) {
  	   my $res = $fromFather eq $fromMother ? $fromMother : "$fromFather / $fromMother)";
   	   return $SELF->set($carac, $res); # will not ask again (definitive result)
   	} else { 
   	  return $SELF->set($carac, $fromFather);
   	}
      } elsif ($base->get($carac)->recessive->$fromMother) {
   	 my $res = $fromFather eq $fromMother ? $fromMother : "$fromFather / $fromMother)";
   	 return $SELF->set($carac, $res);
      } else { 
   	return $SELF->set($carac, $fromMother);
      }
   },                                      
   
   inherit => sub {
      my $carac = shift or return undef; 
      return $SELF->get($carac) || $SELF->get_from_parents($carac);
   },
);

# --

my $jean = Chorus::Frame->new ( _ISA => $family_member );
my $mary = Chorus::Frame->new ( _ISA => $family_member );
my $marc = Chorus::Frame->new ( _ISA => $family_member );

$marc->set(
     NAME   => 'Marc',
     father => $jean,
     mother => $mary
);
 
$jean->set(
     NAME   => 'Jean',
     father => {	
       _ISA => $family_member,
       character => { eyes => { color => 'blue' } }
     },
   	 
     mother => {	
       _ISA => $family_member,
       character => { eyes => { color => 'blue' } }
     }
);

$mary->set(character => { eyes => { color => 'brown' } } );

# --

my @scope = fmatch( slot => [ 'mother', 'father' ]); # all frames having those 2 slots

print $_->NAME . ": " . $_->inherit("character eyes color") . "\n" for @scope;

