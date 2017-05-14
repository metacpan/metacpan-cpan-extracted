package GenesExpert;

use Chorus::Frame;
use Chorus::Engine; 
use strict;

our $agent = Chorus::Engine->new();

my $genes = Chorus::Frame->new(
      eyes => { 
      	 color => {
      	 	dominant => {
      	 		brown => 'y',
      	 		black => 'y'
      	 	},
      	 	recessive => {
      	 		blue  => 'y',
      	 		green => 'y'
      	 	}
      	 }
      },
);

$agent->addrule(

    _SCOPE  => { # values MUST ALWAYS be of type ARRAY_REF

  	  child  => sub { 
  	                  [ fmatch(slot => ['mother', 'father']) ]
  	                },

  	  carac => [ 'eyes color' ]
    },
    
    _APPLY => sub {
      
  	  my %opts = @_; # values will be instanciated by Chorus::Engine object
  	  my ($child, $carac) = ($opts{child}, $opts{carac});
  	    
  	  my $solved = $child->get($carac);

  	  return undef if $solved;                               # question already solved
          return undef unless $child->father and $child->mother; # no way to solve the question

   	  my $fromFather = $child->father->get($carac) or return undef; # not yet solved for the parent
   	  my $fromMother = $child->mother->get($carac) or return undef;

   	  if($genes->get($carac)->dominant->$fromFather) {
   	  	if ($genes->get($carac)->dominant->$fromMother) {
   	  		my $res = $fromFather eq $fromMother ? $fromMother : "$fromFather/$fromMother)";
   	  		print "FOUND(1) .. " . $child->NAME . ": $res\n";
   	  		return $child->set($carac, $res); # returns something true (~ something happened)
   	  	} else {
   	  		my $res = $child->set($carac, $fromFather);
   	  		print "FOUND(2) .. " . $child->NAME . ": $res\n";
   	  		return $res;
   	  	}
   	  } elsif ($genes->get($carac)->recessive->$fromMother) {
   	  		my $res = $fromFather eq $fromMother ? $fromMother : "$fromFather/$fromMother)";
   	  		print "FOUND(3) .. " . $child->NAME . ": $res\n";
   	  		$SELF->last; # will terminate current loop on rules !! 
   	  		return $child->set($carac, $res);
   	  } else { 
   	  		my $res = $child->set($carac, $fromMother);
   	  		print "FOUND(4) .. " . $child->NAME . ": $res\n";
   	  		$SELF->cut;  # go directly to next rule !!
   	  		return $res;
   	  }	     	
  	  return undef; # rule didn't apply for those values (%opts) !  	  
    }
);

$agent->addrule(  # will not declare the system as solved while eyes color is unknown 
                  # for a frame providing slots 'mother' & 'father'
    _SCOPE  => {
  	  carac => [ 'eyes color' ]
    },
    
    _APPLY => sub { 
  	  my %opts = @_;
  	  my $carac = $opts{carac};
          $agent->solved unless grep { ! $_->get($carac) } fmatch(slot => ['mother', 'father']);  	    
    }
);

END { }

1;
