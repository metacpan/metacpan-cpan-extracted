package Chorus::Engine;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.03';

use Chorus::Frame;

use constant DEBUG => 0;

=head1 NAME

Chorus::Engine - A very light inference engine combined with the frame model for knowledge representation.

=head1 VERSION

Version 1.04

=cut

=head1 INTRODUCTION

    Chorus-Engine makes possible to simply develop in Perl with an Articial Intelligence approach 
    by defining the knowledge with rules the inference engine will try to apply on your objects.
    
    Because inference engines use to waste a lot of time before finding interesting instanciations
    for rules, the property _SCOPE is used to optimise the space on which each rule must be tested.
    
    This not necessary but, uou can combinate Chorus::Engine with Chorus::Frame which gives a first level 
    for knowledge representation. The inference engine can then work on Frames using the function 'fmatch' 
    top optimise the _SCOPE for the rules which work on frames.  

=cut

=head1 SYNOPSIS

    use Chorus::Engine;

    my $agent = new Chorus::Engine();
    
    $agent->addrule(

      _SCOPE => {             # These arrays will be combinated as parameters (HASH) when calling _APPLY
             a => $subset,    # static array_ref
             b => sub { .. }  # returns an array ref
      },
      
      _APPLY => sub {
        my %opts = @_;        # provides $opt{a},$opt{b} (~ one combinaison of _SCOPE)

        if ( .. ) {
          ..                  
          return 1;           # rule could be applied (~ something has changed)
        }

        return undef;         # rule didn't apply
      }
    );
    
    $agent->loop();

=head1 SUBROUTINES/METHODS
=cut

=head2 addrule()

       Defines a new rule for the Chorus::Engine object
       
       arguments :
        
         _SCOPE : a hashtable defining the variables and their search scope for instanciation
                  Values must be SCALAR or ARRAY_REF
                                        
         _APPLY : function which will be called in a loop with all the possible 
                  combinaisons from scopes on a & b 
                  
       Ex. use Chorus::Engine;
           use Chorus::Frames;
           
           my $e=Chorus::Engine->new();
           
           $e->addrule(
                  
              _SCOPE => {

                  foo  => [ fmatch( .. ) ],         # selection of Frames bases on the filter 'fmatch' (static)
                  bar  => sub { [ fmatch( .. ) ] }, # same kind more dynamic 
                  baz  => [ .. ]                    # any other array (not only frames)

              },
                  
              _APPLY => sub {
                         my %opts = @_;          # provides $opt{foo},$opt{bar},$opt{baz}
        	             
                         return undef if ( .. ); # rule didn't apply

                         if ( .. ) {
                           ..             # some actions
                           return 1;      # rule could be applied
                         }
       
                         return undef;    # rule didn't apply (last instruction)
              });
=cut             
       
=head2 loop()

       Tells the Chorus::Engine object to enter its inference loop.
       The loop will end only after all rules fail (~ return false) in the same iteration
       
           Ex. my $agent = new Chorus::Engine();
           
               $agent->addrule( .. );
               ..
               $agent->addrule( .. );

               $agent->loop();
=cut

=head2 cut()

       Go directly to the next rule (same loop, same agent). This will break all nested instanciation loops
       on _SCOPE of the current rule. -> GO DIRECTLY TO NEXT RULE (SAME AGENT)
       
           Ex. $agent->addrule(
             _SCOPE => { .. },
             _APPLY => sub {
              if ( .. ) {
                 $agent->cut();    # ~ exit the rule
              }
           );
=cut

=head2 last()

       Breaks the current loop (on rules) for the current agent -> GO DIRECTLY TO NEXT AGENT
       This will force a cut() too.
       
           Ex. $agent->addrule(
             _SCOPE => { .. },
             _APPLY => sub {
              if ( .. ) {
                 $agent->last();
              }
           );
=cut

=head2 replay()

       Restart FROM THE BEGINNING (1st rule) for the CURRENT AGENT. This will force a cut() too.
       
           Ex. $agent->addrule(
             _SCOPE => { .. },
             _APPLY => sub {
              if ( .. ) {
                 $agent->replay();
              }
           );
=cut

=head2 replay_all()

       Restart FROM THE BEGINNING for the FIRST AGENT. This will force a cut() too.
       
           Ex. $agent->addrule(
             _SCOPE => { .. },
             _APPLY => sub {
              if ( .. ) {
                 $agent->replay_all();
              }
           );
=cut

=head2 solved()

       Tells the Chorus::Engine to terminate immediately. This will force a last() too
       
           Ex. $agent->addrule(
             _SCOPE => { .. },
             _APPLY => sub {
              if ( .. ) {
                 $agent->solved();
              }
           );
=cut

=head2 reorder()

       the rules of the agent will be reordered according to the function given as argument (works like with sort()).
       Note - The method last() will be automatically invoked.
       
       Exemple : the current rule in a syntax analyser has found the category 'CAT_C' for a word.
                 The next step whould invoque as soon as possible the rules declared as interested 
                 in this category.
       
           sub sortA {
               my ($r1, $r2) = @_;
               return 1  if $r1->_INTEREST->CAT_C;
               return -1 if $r2->_INTEREST->CAT_C; 
               return 0;
           }

           $agent->addrule(     # rule 1
             _INTEREST => {     # user slot
                 CAT_C => 'Y',
                 # ..
             },
             _SCOPE => { .. }
             _APPLY => sub { .. }
           );
       
           $agent->addrule(     # rule n
             _SCOPE => { .. }
             _APPLY => sub { 
               # ..
               if ( .. ) {
                 # ..
                 $agent->reorder(sortA);  # will put rules interested in CAT_A to the head of the queue
               }
             }
           );
=cut
           
=head2 pause()

       Disable a Chorus::Engine object until call to wakeup(). In this mode, the method loop() has no effect.
       This method can optimise the application by de-activating a Chorus::Engine object until it has 
       a good reason to work (ex. when a certain state is reached in the application ). 
=cut
       
=head2 wakeup()

       Enable a Chorus::Engine object -> will try again to apply its rules after next call to loop()
=cut

=head2 reorderRules()

  use from rules body to optimize the engine defining best candidates (rules) for next loop (break the current loop)
=cut

sub reorderRules {
  my ($funcall) = shift;
  return unless $funcall;
  $SELF->{_RULES} = [ sort { &{$funcall}($a,$b) } @{$SELF->{_RULES}} ];
  $SELF->replay;
}

=head2 applyrules()

  main engine loop (iterates on $SELF->_RULES)
=cut

use Data::Dumper;

sub applyrules {

  sub apply_rec {
    my ($rule, $stillworking) = @_;
    my (%opt, $res);
    
    my %scope = map { 
         my $s = $rule->get("_SCOPE $_");
         $_ => ref($s) eq 'ARRAY' ? $s : [$s || ()] 
       } grep { $_ ne '_KEY'} keys(%{$rule->{_SCOPE}});
    
    my $i = 0;
        
    my $head = 'JUMP: {' . join("\n", map { $i++; 'foreach my $k' . $i . ' (@{$scope{' . $_ . '}})' . " {\n\t" . '$opt{' . $_ . '}=$k' . $i . ";" 
               }  keys(%scope)) . "\n";
               
    # TODO - SET variables from  %opt HERE !!
    # ..
     
    my $body = '$res = $rule->get(\'_APPLY\', %opt); last JUMP if $SELF->{_LAST} or $SELF->{_CUT} or $SELF->{_REPLAY} or $SELF->{_REPLAY_ALL} or $SELF->BOARD->SOLVED or $SELF->BOARD->FAILED';
    my $tail = "\n}" x scalar(keys(%scope)) . '}';

    eval $head . $body . $tail; 
    if ($@) {
       warn $@;
       warn "DEBUG 1 - Rule '$rule->{_ID}' _SCOPE was : " . join(', ', keys(%scope)) . "\n";
    }
    
    warn "DEBUG - Rule '$rule->{_ID}' returned TRUE. : " if $res and DEBUG;
    
    $stillworking ||= $res;

    delete $SELF->{_CUT} if $SELF->{_CUT}; # see eval (already processed) on prev line !!
    
    $SELF->{_QUEUE} = [] if $SELF->{_LAST} or $SELF->{_REPLAY} or $SELF->{_REPLAY_ALL} or $SELF->BOARD->SOLVED or $SELF->BOARD->FAILED;
    delete $SELF->{_LAST} if $SELF->{_LAST};
    
    return undef if $SELF->{_REPLAY} or $SELF->{_REPLAY_ALL};

    $SELF->{_SUCCES} ||= $stillworking;
    
    return $stillworking unless $SELF->{_QUEUE}->[0];
    return apply_rec (shift @{$SELF->{_QUEUE}}, $stillworking);
  }

  return undef if $SELF->{_SLEEPING};
  $SELF->{_QUEUE} = [ @{$SELF->{_RULES} || [] } ];
  return apply_rec(shift @{$SELF->{_QUEUE}});  
}

my $AGENT = Chorus::Frame->new(

          cut         => sub { $SELF->{_CUT}        = 'Y' }, # returns true
          last        => sub { $SELF->{_LAST}       = 'Y' }, # returns true
          replay      => sub { $SELF->{_REPLAY}     = 'Y' }, # (returned value ignored)
          replay_all  => sub { $SELF->{_REPLAY_ALL} = 'Y' }, # (returned value ignored)
          
          loop    => sub { $SELF->{_SUCCES} = 0; do {} while(applyrules() and (! $SELF->BOARD or ! $SELF->BOARD->SOLVED or ! $SELF->BOARD->FAILED)) },

          solved  => sub { $SELF->BOARD->{SOLVED} = 'Y'; return undef },
          failed  => sub { $SELF->BOARD->{FAILED} = 'Y'; return undef },
          
          pause   => sub { $SELF->{_SLEEPING} = 'Y' },
          wakeup  => sub { $SELF->delete('_SLEEPING')},
          
          addrule => sub { push @{$SELF->{_RULES}}, Chorus::Frame->new(@_) },
          reorder => sub { reorderRules(@_) },
          
          debug   => sub { $SELF->{_DEBUG} = shift }
);

=head2 new
  contructor : initialize a new engine
=cut

sub new {
	my $class = shift;
	return Chorus::Frame->new(
	  @_,
	  _ISA    => $AGENT,
	  _RULES  => [],
	)
}

=head1 AUTHOR

Christophe Ivorra, C<< <ch.ivorra at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chorus-engine at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chorus-Engine>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chorus::Engine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus-Engine>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chorus-Engine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chorus-Engine>

=item * Search CPAN

L<http://search.cpan.org/dist/Chorus-Engine/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Chorus::Engine
