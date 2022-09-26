package Class::Plain::Base;

use strict;
use warnings;

sub new {
  my $class = shift;
  
  my $self = ref $_[0] ? {%{$_[0]}} : {@_};
  
  bless $self, ref $class || $class;
}

1;

=encoding UTF-8

=head1 Name

C<Class::Plain::Base> - Provide Constructor

=head1 Description

This module provides a constructor C<new>.

=head1 Class Methods

=head2 new

  my $object = Class::Plain::Base->new(%args);
  
  my $object = Class::Plain::Base->new(\%args);

Create a new object. The implementation is the following.

  sub new {
    my $class = shift;
    
    my $self = ref $_[0] ? {%{$_[0]}} : {@_};
    
    bless $self, ref $class || $class;
  }
