package Chorus::Frame;

use 5.006;
use strict;

our $VERSION = '1.03';

=head1 NAME

Chorus::Frame - A short implementation of frames from knowledge representation. 

=head1 VERSION

Version 1.04

=cut

=head1 SYNOPSIS

  use Chorus::Frame;
        
  my $f1 = Chorus::Frame->new(
     b => {
      	     _DEFAULT => 'inherited default for b'
          }	
  );

  my $f2 = Chorus::Frame->new(
    a => { 
           b1 => sub { $SELF->get('a b2') }, # procedural attachment using context $SELF
           b2 => {
                   _ISA    => $f1->{b},
                   _NEEDED => 'needed for b  # needs mode Z to precede inherited _DEFAULT
                 }
         }     
  );
                    
  Chorus::Frame::setMode(GET => 'N');
  print $f2->get('a b1') . "\n";       # print 'inherited default for b'

  Chorus::Frame::setMode(GET => 'Z');
  print $f2->get('a b1') . "\n";       # print 'needed for b'
  
=cut

=head1 DESCRIPTION

  - A frame is a generic object structure described by slots (properties).
  - A frame can inherit slots from other frames.
  - A frame can have specific slots describing :
  
    * how it can be associated to a target information, 
    * how he reacts when its target information changes
    * what it can try when a missing property is requested.
      
  - The slots _VALUE,_DEFAULT,_NEEDED are tested in this order to obtain the target information 
    of a given frame (can be inherited).
  - Two other special slots _BEFORE & _AFTER can define what a frame has to do before or after 
    one of its properties changes.
  - The slot _ISA is used to define the inheritance. 

  Two modes 'N' (default) or 'Z' are used to define the priority between a frame and its inherited 
  frames in order to process its target information
             
  The globale variable $SELF returns the current CONTEXT which is the most recent frame called for the method get().
  A slot defined by a function sub { .. } can refer to the current context $SELF in its body.
  
  All frames are automaticaly referenced in a repository used to optimise the selection of frames for a given action.
  The function fmatch() can be used to quicly select all the frames responding to a given test on their properties.  
=cut

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  @ISA         = qw(Exporter);
  @EXPORT      = qw($SELF &fmatch REQUIRE_FAILED);
  @EXPORT_OK   = qw(%FMAP);	

  # %EXPORT_TAGS = ( );		# eg: TAG => [ qw!name1 name2! ];
}

use strict;
use Carp;			# warn of errors (from perspective of caller)
use Digest::MD5;
use Scalar::Util qw(weaken);

use Data::Dumper;

use constant DEBUG_MEMORY => 0;

use vars qw($AUTOLOAD);

use constant SUCCESS        =>  1;
use constant FAILED         =>  0;
use constant REQUIRE_FAILED => -1;

use constant VALUATION_ORDER => ('_VALUE', '_DEFAULT', '_NEEDED');

use constant MODE_N => 1;
use constant MODE_Z => 2;

my $getMode = MODE_N;       # DEFAULT IS N !!!

my %REPOSITORY;
my %FMAP;
my %INSTANCES;

our $SELF;
my @Heap = ();

sub AUTOLOAD {
  my $frame = shift || $SELF;
  my $slotName = $AUTOLOAD;
  $slotName =~ s/.*://;           # strip fully-qualified portion
  get($frame, $slotName, @_); # or getN or getZ !!
}

sub _isa {
  my ($ref, $str) = @_;
  return (ref($ref) eq $str);
}

=head1 SUBROUTINES
=cut

=head2 setMode

 Defines the inheritance mode of methods get() for the special slots _VALUE,_DEFAULT,_NEEDED
 the default mode is 'N'.
   
    'N' : ex. a single slot from the sequence _VALUE,_DEFAULT,_NEEDED will be tested in all inherited
              frames before trying the next one.
              
    'Z' : the whole sequence _VALUE,_DEFAULT,_NEEDED will be tested from the frame before being 
          tested from the inherited frames
          
    ex. Chorus::Frame::setMode(GET => 'Z');

=cut

sub setMode {
	my (%opt) = @_;
	$getMode = MODE_N if defined($opt{GET}) and uc($opt{GET}) eq 'N';
	$getMode = MODE_Z if defined($opt{GET}) and uc($opt{GET}) eq 'Z';
}

=head1 METHODS
=cut

=head2 _keys

  my @k = $f->_keys;
  same as CORE::keys but excludes the special slot '_KEY' specific to all frames
=cut

sub _keys {
  my ($this) = @_;
  grep { $_ ne '_KEY' } keys %{$this};
}

sub pushself {
  unshift(@Heap, $SELF) if $SELF;
  $SELF = shift;
}

sub popself {
  $SELF = shift @Heap;
}

sub expand {
    my ($info, @args) = @_;
    return expand(&$info(@args)) if _isa($info, 'CODE');
    return $info;       
}

=head2 _push

  push new elements to a given slot (becomes an array if necessary)
=cut

sub _push {
  my ($this, $slot, @elems) = @_;
  return unless scalar(@elems);
  $this->{$slot} = [ $this->{$slot} || () ] unless ref($this->{$slot}) eq 'ARRAY'; 
  unshift @{$this->{$slot}}, @elems;
}

sub _addInstance {
  my ($this, $instance) = @_;
  my $k = $instance->{_KEY};
  
  $INSTANCES{$this->{_KEY}}->{$k} = $instance;
  weaken($INSTANCES{$this->{_KEY}}->{$k});      # will not increase garbage ref counter to $instance !!
}

=head2 _inherits

  add inherited new frame(s) outside constructor
  ex. $f->_inherits($F1,$F2);
=cut
  
sub _inherits {
  my ($this, @inherited) = @_;
  my $k = $this->{_KEY};
  for (grep { ! $INSTANCES{$_->{_KEY}}->{$k} } @inherited) { # clean list
  	$_->_addInstance($this);
  	$this->_push('_ISA', $_);
  }
  return $this;
}

sub _removeInstance {
  my ($this, $instance) = @_;
  my $k = $instance->{_KEY};
  (warn "Instance NOT FOUND !?", return) unless $INSTANCES{$this->{_KEY}}->{$k};
  delete $INSTANCES{$this->{_KEY}}->{$k};
}

sub blessToFrame {

  sub register {

    my ($this) = @_;

    my $k;
    do {
    	$k = Digest::MD5::md5_base64( rand );
    } while(exists($FMAP{$k}));
 
    foreach my $slot (keys(%$this)) { # register all slots
      $REPOSITORY{$slot} = {} unless exists $REPOSITORY{$slot};
      $REPOSITORY{$slot}->{$k} = 'Y';
    }
    
    $this->{_KEY} = $k;
    $FMAP{$k} = $this;
    weaken($FMAP{$k}); # will not increase garbage ref counter to $this !!
    return $this; 
  }

  sub blessToFrameRec {

    local $_ = shift;

    if (_isa($_,'Chorus::Frame')) {
      
      while(my ($k, $val) = each %$_) {
         if (_isa($val,'HASH')) {
            next if $val->{_NOFRAME};
            bless($val, 'Chorus::Frame');
            $val->register();
            blessToFrameRec($val);
         } else {
            if (_isa($val,'ARRAY')) {
               blessToFrameRec($_->{$k});
            }
         }
         if ($k eq '_ISA') {
           foreach my $inherited (_isa($val,'ARRAY') ? map \&expand, @{$val} 
                                                         : (expand($val))) {
              $inherited->_addInstance($_) if $inherited;
           }
         }
      }

      return;
    }

    if (_isa($_,'ARRAY')) { # à revoir (sans $idx)
      foreach my $idx (0 .. scalar(@$_) - 1) {
	    if (_isa($_[$idx], 'HASH')) {
	      next if exists $_[$idx]->{_NOFRAME};
	      bless($_[$idx], 'Chorus::Frame');
	      $_[$idx]->register();
	      blessToFrameRec($_[$idx]);
	    } else {
	      if (_isa($_[$idx],'ARRAY')) {
	        blessToFrameRec($_[$idx]);
	      }
	    }
      }
    }
  }

  my $res = shift;

  return $res if _isa($res, 'Chorus::Frame'); # already blessed

  SWITCH: {

    _isa($res, 'HASH') && do {
	  return $res if exists $res->{_NOFRAME};
	  bless($res, 'Chorus::Frame')->register();
	  blessToFrameRec $res if keys(%$res);
	  last SWITCH;;
    };

    _isa($res, 'ARRAY') && do {
      return $res unless scalar(@$res);
	  blessToFrameRec $res;
	  last SWITCH;
    };

  }; # SWITCH

  return $res;
}

=head2 new

  Constructor : Converts a hashtable definition into a Chorus::Frame object.
  
  Important - All nested hashtables are recursively converted to Chorus::Frame,  
              except those providing a slot _NO_FRAME
              
  All frames are associated to a unique key and registered in an internal repository (see fmatch)
   
  Ex. $f = Chorus::Frame->new(
                       slotA1 => {
        	              _ISA   => [ $f2->slotA, $f3->slotA ] # multiple inheritance
        	              slotA2 => sub { $SELF };             # procedural attachements
        	              slotA3 => 'value for A3'
                       },
                       slotB => {
        	              _NEEDED => sub { .. }
                       }      
                    );
=cut

sub new {
  my ($this, @desc) = @_;
  return blessToFrame({@desc});
}

# WARN - Should be automatically called by carbage collector EVEN with those 2 remaining references : $INSTANCES{$k} AND $FMAP{$k} !!!
#
sub DESTROY { 
  my ($this) = @_;

    my $k = $this->{_KEY} or warn "Undefined _KEY(1) for " . Dumper($this);

    delete $INSTANCES{$k} if exists $INSTANCES{$k};

    foreach my $inherited (_isa($this->{_ISA}, 'ARRAY') ? map \&expand, @{$this->{_ISA}} : (expand($this->{_ISA}))) {	  
      my $ik = $inherited->{_KEY} or next;
      delete $INSTANCES{$ik}->{$k} if exists $INSTANCES{$ik}->{$k};
    }

    foreach my $slot (keys(%$this)) {
      delete($REPOSITORY{$slot}->{$k}) if exists $REPOSITORY{$slot} and exists $REPOSITORY{$slot}->{$k};
    }

    delete $FMAP{$k}; # is a weak reference (not counted by garbage collector)
}

=head2 get

This method provides the information associated to a sequence of slots.
This sequence is given in a string composed with slot names separated by spaces.
The last slot is tested for the target information with the sequence _VALUE,_DEFAULT,_NEEDED.
If a frame doesn't provide any of those slots, the target information is the frame itself.

A frame called with the method get() becomes the current context wich can be referred with the variable $SELF.
  
Note - The short form $f->SLOTNAME() can by used instead of $f->get('SLOTNAME');
  
Ex. $f->foo;                   # equiv to $f->get('foo');
    $f->foo(@args);            # equiv to $f->get('foo')(@args);

    $f->get('foo bar');        # $SELF (context) is $f while processing 'bar'

    $f->get('foo')->get('bar') # $SELF (context) is $f->foo while processing 'bar'
    $f->foo->bar;              # short form
      
=cut

sub get {
	
  sub expandInherits {

    sub first { # uses expand
	  my ($this, $slots, @args) = @_;
          for (@{$slots}) {
  	     return { ret => SUCCESS, res => expand($this->{$_}, @args) } if exists $this->{$_};
          }
	  return undef; 
    }

    my ($this,$tryValuations,@args) = @_;	

    my $res = $this->first($tryValuations,@args);
    return $res if defined($res) and $res->{ret};

    if (exists($this->{_ISA})) {
      my @h = _isa($this->{_ISA}, 'ARRAY') ? map { expand($_) || () } @{$this->{_ISA}} : (expand($this->{_ISA}) || ());
      for (@h) { # upper level
        $res = $_->expandInherits($tryValuations,@args);
        return $res if defined($res) and $res->{ret};
      }
    }
    return { ret => FAILED };
  } # expandInherits

  sub inherited {
	my ($this,$slot,@rest) = @_;

	return $this->{$slot} if exists($this->{$slot}); # first that match (better than buildtree) !!
        $this->{_ISA} and push @rest, _isa($this->{_ISA}, 'ARRAY') ? @{$this->{_ISA}} : $this->{_ISA}; # see expand

	my $next = shift @rest;
	return undef unless $next;
	return $next->inherited($slot,@rest);
  } 

  sub getZ {
  	
  	sub value_Z {
      my ($info, @args) = @_;
      return expand($info,@args) unless _isa($info,'Chorus::Frame');
      my $res = $info->expandInherits([VALUATION_ORDER], @args);
      return $res->{res} if defined($res) and $res->{ret};
      return $info;
    }
    
    my ($this, $way, @args) = @_;

    return $this->value_Z(@args) unless $way;

    $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
    my ($nextStep, $followWay) = ($1,$2);

    return value_Z($this->inherited($nextStep), @args) unless $followWay;

    my $next = $this->inherited($nextStep);  
    return _isa($next,'Chorus::Frame') ? $next->getZ($followWay, @args) : undef;
  }

  sub getN {
  	
    sub value_N {
      my ($info, @args) = @_;
      return expand($info,@args) unless _isa($info,'Chorus::Frame');
      for (VALUATION_ORDER) {
  	    my $res = $info->expandInherits([$_], @args);
  	    return $res->{res} if defined($res) and $res->{ret};
      }  
      return $info;
    }
    
    my ($this, $way, @args) = @_;

    return $this->value_N(@args) unless $way;

    $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
    my ($nextStep, $followWay) = ($1,$2);

    return value_N($this->inherited($nextStep), @args) unless $followWay;

    my $next = $this->inherited($nextStep);
    return _isa($next,'Chorus::Frame') ? $next->getN($followWay, @args) : undef;
  }

  pushself(shift);
  my $res = $getMode == MODE_N ? getN($SELF,@_) : getZ($SELF,@_);
  popself();
  return $res;
}

=head2 delete

   All Frames properties are registered in a single table, especially to optimize the method fmatch().
   This why frames have to use the form $f->delete($slotname) instead of delete($f->{$slotname})
   otherwise a frame will be considered by fmatch() as providing a slot even after this one have been removed.

=cut
    
sub delete {
	
  sub deleteSlot {

    sub unregisterSlot {
      my ($this,$slot) = @_;
      return unless exists $REPOSITORY{$slot};
	  delete $REPOSITORY{$slot}->{$this->{_KEY}} if exists $REPOSITORY{$slot}->{$this->{_KEY}};
    }

    my ($this,$slot) = @_;

    $this->unregisterSlot($slot);	
    delete($this->{$slot}) if exists $this->{$slot};   
  }
	
  sub deleteN {

    my ($this, $way) = @_;

    return undef unless $way;

    $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
    my ($nextStep, $followWay) = ($1,$2);

    return $this->deleteSlot($nextStep) unless $followWay;

    my $next = $this->inherited($nextStep);
    return _isa($next,'Chorus::Frame') ? $next->deleteN($followWay) : undef;
  }
	
  pushself(shift);
  my $res = $SELF->deleteN(@_);
  popself();
  return $res;
}

=head2 set

   This method tells a frame to associated target information to a sequence of slots
   A frame called for this method becomes the new context.

    Ex. $f1 = Chorus::Frame->new(
          a => {
          	  b => { 
          	  	c => 'C'
          	  }
          }
        );
                
    $f1->set('a b', 'B');  # 'B' becomes the target _VALUE for $f1->get('a b')
    $f1->get('a b');       # returns 'B'

    $f1->get('a b c');     # still returns 'C'
    $f1->delete('a b c');
    $f1->get('a b c');     # undef

    $f2 = Chorus::Frame->new(
          _ISA => $1,
    );

    $f2->get('a b c');     # returns 'C'
    
    $f2->set('a b', 'AB'); # cancel inheritance for first slot 'a'
    $f2->get('a b');       # returns 'AB'

    $f2->get('a b c');     # undefined
        
=cut

sub set {

  sub registerSlot {
	my ($this,$slot) = @_;
	$REPOSITORY{$slot} = {} unless exists $REPOSITORY{$slot};
	$REPOSITORY{$slot}->{$this->{_KEY}} = 'Y';
  }
    
  sub setValue {
    my ($this, $val) = @_;

    return undef if $this->getN('_REQUIRE', $val) == REQUIRE_FAILED;
    
    $this->getN('_BEFORE', $val); # or return undef;

    blessToFrame($val);
    $this->{'_VALUE'} = $val;
    $this->registerSlot('_VALUE');

    $this->getN('_AFTER', $val); # or return undef;

    return $val;
  }

  sub setSlot {
    my ($this, $slot, $info) = @_;
    blessToFrame($info);
    $this->{$slot} = $info;
    $this->registerSlot($slot);  
    return $info;
  }
  	
  sub setN {
    my ($this, $way, $info) = @_;

    return $this->setValue($info) unless $way;

    $way =~ /^\s*(\S*)\s*(.*?)\s*$/o or die "Unexpected way format : '$way'";
    my ($nextStep, $followWay) = ($1,$2);
    my $crossedValue = $this->{$nextStep};

    return $crossedValue->setN($followWay, $info) if _isa($crossedValue,'Chorus::Frame');
    
    unless ($followWay) {
      if ($nextStep eq '_VALUE') {
        return $this->setValue($info);
      } else {
        if (_isa($this->{$nextStep}, 'Chorus::Frame') and exists($this->{$nextStep}->{_VALUE})) {
	      return $this->{$nextStep}->setValue($info)
        } else {
	      return $this->setSlot($nextStep, $info);
        }
      }
    }

    $this->{$nextStep} = (exists($this->{$nextStep})) ? new Chorus::Frame (_VALUE => $crossedValue)
                                                      : new Chorus::Frame;
    
    return $this->{$nextStep}->setN($followWay, $info); # (keep current context)
    
  } # set is setN !!!!
	
  pushself(shift);
  my %desc = @_;

  my $res;
 
  while(my($k,$val) = each %desc) {
    $res = $SELF->setN($k, $val);    # set is setN !!
  }
  
  popself();
  return $res;  # wil return last set if multiple pairs (key=>val) !!
 }

=head2 fmatch

 This function returns the list of the frames providing all the slots given as argument.
 The result can contains the frames providing these the slots by inheritance.
 This function can be used to minimise the list of frames that should be candidate for a given process.
 
 An optional argument 'from' can provide a list of frames as search space
 
 ex. @l = grep { $_->score > 5 } fmatch(
                                         slot => ['foo', 'score'],
                                         from => \@framelist       # optional : limit search scope
                                       );
     #
     # all frames, optionnaly from @framelist, providing both slots 'foo' and 'score' (possible 
     # inheritance) and on which the method get('score') returns a value > 5

=cut

sub firstInheriting {
          my ($this) = @_;
          my $k = $this->{_KEY};
          return () unless $INSTANCES{$k};
          return(values(%{$INSTANCES{$k}}));
          
} # firstInheriting

sub fmatch {
  
  sub framesProvidingSlot { # inheritance ok
  
    sub hasSlot {
       my ($slot) = @_;
       return map { $FMAP{$_} || () } keys(%{$REPOSITORY{$slot}})   
    }

    sub wholeTree { 
        
       my ($res, @dig) = @_;
         return $res unless $dig[0];
         my @inheriting = map { $_->firstInheriting || () } @dig;
         push(@$res, @inheriting);
         return wholeTree($res,@inheriting);
         
    } # wholeTree
  
    my ($slot) = @_;
    
    my @res = hasSlot($slot);
    my @inheriting = map { $_->firstInheriting || () } @res;
  
    push @res, @inheriting;
    return wholeTree(\@res, @inheriting);
	
  } # framesProvidingSlot

  my %opts = @_;
  $opts{slot} = [ $opts{slot} || () ] unless _isa($opts{slot},'ARRAY');
  my ($firstslot,@otherslots) = @{$opts{slot} || []};

  return () unless $firstslot;
  
  my %filter = map { $_->{_KEY} => 'Y' || () } @{framesProvidingSlot($firstslot)};
  
  for(@otherslots) {
    %filter = map { $filter{$_->{_KEY}} ? ($_->{_KEY} => 'Y') : () } @{framesProvidingSlot($_)};
  }
  
  if ($opts{from}) {
    return grep { $filter{$_->{_KEY}} } @{$opts{from}};
  }
  
  return map { $FMAP{$_} || ()} keys(%filter);
  
} # fmatch

=head1 AUTHOR

Christophe Ivorra, C<< <ch.ivorra at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chorus-frame at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chorus-Frame>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chorus::Frame


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus-Frame>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chorus-Frame>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chorus-Frame>

=item * Search CPAN

L<http://search.cpan.org/dist/Chorus-Frame/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Chorus::Frame
