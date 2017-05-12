package Class::Random;

# $Id: Random.pm,v 1.3 2002/08/06 17:02:37 pmh Exp $

use overload '""','stringify';
use strict;
use Carp;
use vars qw($VERSION);

$VERSION=0.2;

sub stringify{
  my($self)=@_;

  if($self->{mode} eq 'choose'){
    @{$self->{isa}}=($self,@{$self->{list}[rand @{$self->{list}}]});
  }elsif($self->{mode} eq 'shuffle'){
    my @list=@{$self->{list}};
    my @isa;
    while(@list){
      push @isa,splice @list,rand @list,1;
    }
    @{$self->{isa}}=($self,@isa);
  }
  # Return a class with no methods, so the method search doesn't stop here
  'Class::Random::Empty';
}

sub import{
  my($pack,$mode,@list)=@_;
  @_>3
    or croak "Usage: use $pack BEHAVIOUR => LIST;";
  my $callpkg=caller;

  if($mode eq 'choose' || $mode eq 'shuffle'){
    if($mode eq 'choose'){
      foreach(@list){
        ref eq 'ARRAY'
          or croak "choose argument must be list of lists";
      }
    }

    my $self=bless {
      mode => $mode,
      list => \@list,
      isa => do{
        no strict 'refs';
        \@{$callpkg.'::ISA'};
      },
    };
    unshift @{$self->{isa}},$self;
    return "$self"; # Force setting of caller's @ISA
  }elsif($mode eq 'subclass'){
    my $new=sub{
      my $pkg=shift;
      $list[rand @list]->new(@_);
    };
    no strict 'refs';
    *{$callpkg.'::new'}=$new;
  }else{
    croak "Unknown $pack mode: $mode\n";
  }
}

package Class::Random::Empty;

1;

__END__

=head1 NAME

Class::Random - Random behaviour for instances

=head1 SYNOPSIS

  package RandomSubclass;
  use Class::Random subclass => qw(A B);

  package ShufflePerMethod;
  use Class::Random shuffle => qw(C D);

  package ChoosePerMethod;
  use Class::Random choose => [qw(E F)],[qw(G H)];

=head1 DESCRIPTION

This module allows you to create classes which randomly change
their behaviour or implementation according to a specified behaviour.
This is done simply by using the module, passing a parameter list
which dictates the required behaviour.  A number of behaviours are
possible, determined by the first argument in the C<use Class::Random>
line:

=over 4

=item subclass

The C<subclass> behaviour is given a list of class names, and installs a
C<new> class method in the calling package. This method picks one of the
class names given, and calls that class' C<new> method. Note that if
a C<new> method is defined after this C<use> statement, it will
override the one defined by C<Class::Random>.

This behaviour implements Damian Conway's idea of choosing a random
implementation for each object created, in order to discourage
users from directly accessing the object's internals, rather than
using the interface like they are supposed to do.

=item shuffle

The C<shuffle> behaviour is given a list of class names, which are used to
populate the calling package's C<@ISA> array. It also installs an object
in the first element of C<@ISA>, which shuffles the rest of the array
when accessed. This has the effect of causing each method called on the
object to change the inheritance hierarchy.

=item choose

The C<choose> behaviour is like the C<shuffle> behaviour, except that each
element of the list is a complete C<@ISA> array. This allows one of a
number of different lists of base classes to be chosen with each method
call.

=back

=head1 BUGS

The C<subclass> method is the only remotely useful behaviour of this class,
and even that's arguable.

Due to perl's normal sensible strategy of method caching, if the same method
is called repeatedly under the C<choose> or C<shuffle> behaviours, without
any others being called in between, it will always call the same method.

=head1 ACKNOWLEDGEMENTS

Damian Conway inspired the first version of this module (with the C<choose>
and C<shuffle> behaviours), by wondering what would happen if you put
something other than class names in a package's C<@ISA> array. He immediately
turned around and told us not to do that, but I'd already had this stupid idea.

Damian also came up with the idea for the C<subclass> behaviour, only that
was deliberate on his part. Still, I don't think he was expecting anyone to
implement it.

=head1 AUTHOR

Peter Haworth E<lt>pmh@edison.ioppublishing.comE<gt>

