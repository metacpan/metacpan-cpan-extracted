############################################################
#
# $Header: /mnt/barrayar/d06/home/domi/Tools/perlDev/Async_Group/RCS/Group.pm,v 1.2 1998/11/20 12:31:02 domi Exp $
#
# $Source: /mnt/barrayar/d06/home/domi/Tools/perlDev/Async_Group/RCS/Group.pm,v $
# $Revision: 1.2 $
# $Locker:  $
# 
############################################################

package Async::Group ;

use Carp ;
#use AutoLoader 'AUTOLOAD' ;

use strict ;
use vars qw($VERSION) ;
$VERSION =  substr q$Revision: 1.2 $, 10;

# see loadspecs for other names
sub new 
  {
    my $type = shift ;
    my $self = {} ;
    my %args = @_ ;

    $self->{name}='' ;
    foreach (qw/name test/)
      {
        $self->{$_}= $args{$_} ;
      }
    
    bless $self,$type ;
  }

sub getCbRef
  {
    my $self = shift;
    return sub{$self->callDone(@_)} ;
  }

sub printEvent
  {
    my $self = shift ;
    warn "$self->{name} ",shift if $self->{test} ;
  }

# Call a set of asynchronous functions which MUST have their set of user
# callbacks.. Note that the user call-back invoked when the function MUST
# call the asyncDone function with a result.
#
# When all function calls are over (i.e. all call-back were performed)
# all the returned results are logically 'anded' and the resulting result
# is passed to the main user call-back function
sub run
  {
    my $self = shift ;

    # 'set'    => [ sub { } ,... ]
    # 'callback' => 'method_name'
    my %args = @_ ; 

    foreach (qw/set callback/)
      {
        croak( "No $_ passed to Async::Group::run\n") unless 
          defined $args{$_};
      }
    
    croak( "$self->name:Async::Group: set parameter is not an array ref\n")
      unless ref($args{set}) eq 'ARRAY' ;

    # initialize 
    $self->{result} = 1 ;
    $self->{out} = '' ;

    # compute nb of asynchronous calls that will be done
    $self->{onGoing} = scalar (@{$args{set}}) ;

    # make up some log message
    $self->printEvent("asynCall called for ".
                      $self->{onGoing}." calls");

    # store what to do when the asyncGroup is all done
    $self->{callback} = $args{'callback'} ;

    # call them
    foreach my $func ( @{$args{set}} )
      {
        &$func ;
      }
  }

# expects asyncGroup id and a result as parameter
sub callDone
  {
    my $self= shift ;
    my $result = shift ;
    my $str = shift ;

    # no more info can be passed back, since we don't know what to do with
    # the results until all applied function are finished 
    #store results
    $self->{out} .= $str if defined $str ;
    $self->{result} &&= $result ;
    $self->printEvent("Async::Group call done ($result), ". 
                      -- $self->{onGoing}
                      ." left to do\n");
	
    unless ($self->{onGoing})
      {
        $self->printEvent
          ("Async::Group finished, global result is $self->{result}\n"
           .$self->{out}) ;
        my $cb = $self->{'callback'} ;
        &$cb($self->{result},$self->{out});
      }
  }

1;

__END__

=head1 NAME

Async::Group - Perl class to deal with simultaneous asynchronous calls

=head1 SYNOPSIS

 use Async::Group ;
 use strict ;

 sub sub1 
  {
    print "Dummy subroutine \n";
    my $dummy = shift ;
    my $cb = shift ;

    &$cb(1);
  }

 sub allDone
  {
    print "All done, result is ", shift ,"\n" ;
  }
 my $a = Async::Group->new(name => 'aTest', test => 1) ;

 $a->run(set => [ sub {&sub1( callback => sub {$a->callDone(@_)} )},
                 sub {&sub1( callback => sub {$a->callDone(@_)} )} ],
        callback => \&allDone 
       )

 # or another way which avoids the clumsy nested subs
 my $cb = $a->getCbRef();
 $a->run(set => [ sub {&sub1( callback => $cb)},
                  sub {&nsub1( callback => $cb )} ],
        callback => \&allDone 
       )


=head1 DESCRIPTION

If you sometimes have to launch several asynchronous calls in
parrallel and want to call one call-back function when all these calls
are finished, this module may be for you.

Async::Group is a class which enables you to call several asynchronous
routines.  Each routine may have their own callback. When all the
routine are over (i.e.  all their callback were called), Async::Group
will call the global callback given by the user.

Note that one Async::Group objects must be created for each group of
parrallel calls. This object may be destroyed (or will vanish itself)
once the global callback is called.

Note also that Async::Group does not perform any fork or other system
calls.  It just run the passed subroutines and keep count of the
call-back functions called by the aforementionned subroutines. When
all these subs are finished, it calls another call-back (passed by the
user) to perform whatever function required by the user.

Using fork or threads or whatever is left to the user.

=head1 Methods

=head2 new( set => [sub, sub, ...], [test => 1] )

Creates a new Async::Group object.

parameters are :
 - name: name of the group. The name has no special meaning but it can be
   helpfull for debugging.
 - test:  will print on STDERR  what's going on

=head2 run ('set'    => [ sub { } ,... ], 'callback' => sub{ ...} )

 - set: array ref of a set of subroutine reference that will be called in 
   parrallel
 - callback : global user callback function


=head2 callDone(result, [string])

Function to be called back each time an asynchronous call is finished.

When all function calls are over (i.e. all call-back were performed)
all the returned results are logically 'anded', the passed strings are
concatenated and the resulting result is passed to the global user
call-back function passed with the run() method.

=head2 getCbRef()

Syntactic sugar to avoid nested subs when defining the set of routines
that must be run in parrallel. This function will return a sub ref
that can be used as a callback function by the user's routine.

So you may call run() with the following sequence :

 my $cb = $a->getCbRef();
 $a->run(set => [ sub {&sub1( callback => $cb)},
                  sub {&nsub1( callback => $cb )} ],
        callback => \&allDone 
       )

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut

