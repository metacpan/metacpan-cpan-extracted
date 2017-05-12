package Data::Predicate::ClosurePredicate;

use strict;
use warnings;
use Carp;

use base qw(Data::Predicate);

sub new {
  my ($class, %args) = @_;
  
  confess('No closure given; cannot create an object without one') 
    unless defined $args{closure};
  
  my $self = $class->SUPER::new();
  $self->closure($args{closure});
  $self->description($args{description});
  return $self;
}

sub closure {
  my ($self, $closure) = @_;
  if(defined $closure) {
    confess("${closure} is not a CodeRef; cannot continue") unless ref($closure) eq 'CODE';
    $self->{closure} = $closure;
  }
  return $self->{closure};
}

sub description {
  my ($self, $description) = @_;
  $self->{description} = $description if defined $description;
  return $self->{description} || 'unknown';
}

sub apply {
  my ($self, $object) = @_;
  return $self->closure()->($object);
}

1;
__END__
=pod

=head1 NAME

=head1 SYNOPSIS

  use Data::Predicate::ClosurePredicate;
  
  #A closure which evaluates if a given object is defined or not
  Data::Predicate::ClosurePredicate->new(closure => sub {
    my ($object) = @_;
    return (defined $object) ? 1 : 0;
  }, description => 'Returns true if the given object is defined');

=head1 DESCRIPTION

A very simple abstraction from C<Data::Predicate> which encapsulates
the predicate logic in a closure given at construction time. This allows
us to build very specific tests whilst keeping our class count down. It
also allows for rapid prototyping of predicates & should speed become
an issue means the code can be easily migrated into a custom version.

=head1 METHODS

=head2 new

  Data::Predicate::ClosurePredicate->new(closure => sub {
    my ($object) = @_;
    return (defined $object) ? 1 : 0;
  }, description => 'Returns true if the given object is defined');
  
Accepts 2 variables; closure & description. closure is a required 
argument where as description is not but recommended.

=head2 closure - required

Takes in a CodeRef and assumes it will return true or false depending on
the outcome of evaluation of an object.

=head2 description

Allows you to tag a predicate with a description as when faced with
multiple predicates all of which are ClosurePredicate instances it can
be somewhat daunting.

Optional & defaults to unknown.

=head2 apply()

Returns the value from an invocation of the attribute C<closure> with
the incoming object.

=head1 AUTHOR

Andrew Yates

=head1 LICENCE

Copyright (c) 2010 - 2010 European Molecular Biology Laboratory.

Author: Andrew Yates (ayatesattheebi - remove the relevant sections accordingly)

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.
   3. Neither the name of the Genome Research Ltd nor the names of its 
      contributors may be used to endorse or promote products derived from 
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR 
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut