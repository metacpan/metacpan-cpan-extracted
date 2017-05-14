# Chorus-Engine

A light rules based programming framework for Perl 

# Introduction

Like many other powerful interpreted languages, Perl can be considered as slow compared to C++ or even Java. Therefore, the purpose here is to use Perl for declarative programming and allow to develop with an Artificial Intelligence approach,
making use of rules engines and staying in the same time the nearest as possible to Perl itself.

With structural programming, the flow control is totally determined by the succession of well defined instructions sequences (function calls, conditional statements, ..)
and datas are just a place to store more or less structured informations.
With object programming, a part of the control is performed by the inheritance of properties and methods between classes.
But still, a method, inherited or not, is invoked according to the same kind of instructions sequences as in structural programming. 

On the contrary, with rules engines, the idea just consists in describing the knowledge of a system with facts and rules and let it evolve by himself, by applying rules on facts (generating new facts) .. until the system reaches a stable state.

Chorus-Engine is a set of 3 small libraries allowing to use Perl to implement rules engines. 

## Provides

* Chorus-Frame.pm   : Compact frame oriented object library (implementing the two other libraries)
* Chorus-Engine.pm  : Engine iterating on a set of rules, each one focusing on a dynamic scope of objects (frames or any other Perl object) 
* Chorus-Expert     : Multiple-engines combination allowing to implement different levels/layers of knowledge, each one contributing to the stabilization (~ resolution) 
                      of the whole system.


## Chorus-Engine

    use Chorus::Engine;
    
    my $agent = new Chorus::Engine();
    
    $agent->addrule(

      _SCOPE => {             # These arrays will be combinated as parameters (HASH)
                              # when calling _APPLY
             a => $subset,    # 1st arg : static array_ref
             b => sub { .. }  # 2nd arg : should returns an array ref
      },
      
      _APPLY => sub {
        my %opts = @_;   # provides $opt{a},$opt{b} (~ one COMBINATION of _SCOPE)

        if ( .. ) {
          ..                  
          return 1;      # rule could be applied (~ something has changed)
        }

        return undef;    # rule didn't apply
      }
    );
    
    $agent->loop();      # will test rules until an explicitly call to $SELF->solved() 
                         # or no more rule can be applied
    

## Chorus-Expert

    # 1 - Registers one or more Chorus::Engine objects
    # 2 - Provides to each of them a shared working area ($SELF->BOARD)
    # 3 - Enter an infinite loop on each engine until one of them declares the whole system as SOLVED.

    package A;
    use Chorus::Engine;
    our $agent = Chorus::Engine->new();
    $agent->addrule(...);
    $agent->addrule(...);
    
    # --
      
    package B;
    use Chorus::Engine;
    our $agent = Chorus::Engine->new();
    $agent->addrule(...);
    $agent->addrule(...);
   
    # --
     
    use Chorus::Expert;
    use A;
    use B;
   
    my $xprt = Chorus::Expert->new();
    $xprt->register($A::agent);
    $xprt->register($B::agent);
   
    $xprt->process();
    
## Sample

    #!/usr/bin/perl 
    #
    use Chorus::Frame;
    use Chorus::Expert;
    use Chorus::Engine;

    my $eng  = Chorus::Engine->new();
    my $xprt = Chorus::Expert->new()->register($eng); # entry point ($xprt->process())

    my @stock = ();

    # --

    use Term::ReadKey;

    sub pressKey {
      while (not defined (ReadKey(-1))) {}
    }

    sub displayState {
     foreach my $l (0 .. 10) {
      	  my $lineChar = $l == 5 ? '-' : ' ';
      	  print (int($_->level + 0.5) == $l ? '+' : $lineChar) for (@stock);
          print "\n";
      	}
      print "\n\n";
      select(undef, undef, undef, 0.02); # pause for display
    }

    # -- MODELIZING SYSTEM WITH FRAMES

    use constant STOCK_SIZE => 100;   # RESIZE YOUR TERMINAL TO HAVE AT LEAST 100 COLUMNS
    use constant TARGET     => 0.5;   # mini ecart-type wanted

    my $count = 0;

    my $CURSOR = Chorus::Frame->new(
       increase => sub { $SELF->set('level', $SELF->level + 0.5); }, # dont use syntax $SELF->{level} with frames (see _VALUE)
       decrease => sub { $SELF->set('level', $SELF->level - 0.5); },
       increase_counter => sub { ++$count }
    );

    my $LEVEL = Chorus::Frame->new(
       _AFTER   => sub { $SELF->increase_counter } # Note -$SELF (~ the current context) is a CURSOR (not a LEVEL) !
    );

    push @stock, Chorus::Frame->new(
        _ISA     => $CURSOR,
        level    => {
 	                  _ISA   => $LEVEL,
 	                  _VALUE => int(rand(10) + 0.5)
        }
    ) for (1 .. STOCK_SIZE); # populating

    # --

    $eng->addrule( # RULE 1
      _SCOPE => {
             once => 'Y', # once a loop (always true)
      },
      _APPLY => \&displayState
    );

    # --

    sub checksolved {
      my ($average, $ecart) = (0,0);
      $average += $_->level for(@stock);
      $average /= STOCK_SIZE;
      $ecart += abs($_->level - $average) for(@stock); # @stock equiv. to fmatch(slots=>'level') here
      $ecart /= STOCK_SIZE;
      return ($ecart < TARGET);
    }

    $eng->addrule( # RULE 2

      _SCOPE => {
             once => 1, # once a loop (always true)
      },
      
      _APPLY => sub {
        return $SELF->solved if checksolved(); # delared the whole system as solved (will exit from current $xprt->process())
        return undef;                          # rule didn't apply
      }
    );

    # ----------------------------------------------------------------------------------------------------------
    #
    # fmatch() [Chorus-Frame.pm] : optimized (fast) built of an array of frames according to one more properties 
    #
    # ----------------------------------------------------------------------------------------------------------
        
    $eng->addrule( # RULE 3
      _SCOPE => { frame => sub { [ grep { $_->level < 5 } fmatch(slot=>'level') ] } }, # frames having level < 5
      _APPLY => sub {
      	my %opt = @_;
      	$opt{frame}->increase;
      }
    );

    # --

    $eng->addrule( # RULE 4
      _SCOPE => { frame => sub { [ grep { $_->level > 5 } fmatch(slot=>'level') ] } }, # frames having level > 5
      _APPLY => sub {
      	my %opt = @_;
      	$opt{frame}->decrease;
      }
    );

    # --

    displayState();
    print "Press a key to start"; pressKey();
    $xprt->process();
    print "Total : $count updates\n";

   
## Installation

Download tar.gz archive, expand it and change directory:

    curl -kL https://github.com/maelink/Chorus-Engine/archive/master.zip > Chorus-Engine.zip
    unzip Chorus-Engine.zip
    cd Chorus-Engine-master/release

Setup. Needed module supposed to is installed.

    perl Makefile.PL
    make test
    sudo make install

## Web Site

* [Github Web Site] (http://maelink.github.io/Chorus-Engine)
* [Meta-CPAN Web Site] (https://metacpan.org/release/Chorus-Expert)

## Internally Using Library

* [Digest::MD5] (https://metacpan.org/pod/Digest::MD5)
* [Scalar::Util] (https://metacpan.org/pod/Scalar::Util)    
* [Data::Dumper] (https://metacpan.org/pod/Data::Dumper)


## Bug

If you find bug, please tell me on GitHub issue.

* [Github Issue](https://github.com/maelink/Chorus-Engine/issues?state=open)

## Request

If you want new features, please tell me on GitHub issue.

## Copyright & license

Copyright 2015 Maelink - All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
