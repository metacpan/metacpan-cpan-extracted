=head1 NAME

Class::MakeMethods::Template::Ref - Universal copy and compare methods

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Ref (
    'Hash:new'      => [ 'new' ],
    clone           => [ 'clone' ]
  );
  
  package main;

  my $obj = MyObject->new( foo => ["Foozle", "Bozzle"] );
  my $clone = $obj->clone();
  print $obj->{'foo'}[1];

=cut

package Class::MakeMethods::Template::Ref;

$VERSION = 1.008;
use strict;
require 5.00;
use Carp;

use Class::MakeMethods::Template '-isasubclass';
use Class::MakeMethods::Utility::Ref qw( ref_clone ref_compare );

######################################################################

=head1 DESCRIPTION

The following types of methods are provided via the Class::MakeMethods interface:

=head2 clone

Produce a deep copy of an instance of almost any underlying datatype. 

Parameters:

init_method 
  
If defined, this method is called on the new object with any arguments passed in.

=cut

sub clone {
  {
    'params' => { 'init_method' => '' },
    'interface' => {
      default => 'clone',
      clone => { '*'=>'clone',  },
    },
    'behavior' => {
      'clone' => sub { my $m_info = $_[0]; sub {
	  my $callee = shift; 
	  ref $callee or croak "Can only copy instances, not a class.\n";
	  
	  my $self = ref_clone( $callee );
	  
	  my $init_method = $m_info->{'init_method'};
	  if ( $init_method ) {
	    $self->$init_method( @_ );
	  } elsif ( scalar @_ ) {
	    croak "No init_method";
	  }
	  return $self;
	}},
    },
  } 
}

######################################################################

=head2 prototype

Create new instances by making a deep copy of a static prototypical instance. 

Parameters:

init_method 
  
If defined, this method is called on the new object with any arguments passed in.
=cut

sub prototype {
  ( {
    'interface' => {
      default => { '*'=>'set_or_new',  },
    },
    'behavior' => {
      'set_or_new' => sub { my $m_info = $_[0]; sub {
	my $class = shift;
	
	if ( scalar @_ == 1 and UNIVERSAL::isa( $_[0], $class ) ) {
	  # set
	  $m_info->{'instance'} = shift 
	
	} else {
	  # get
	  croak "Prototype is not defined" unless $m_info->{'instance'};
	  my $self = ref_clone($m_info->{'instance'});
	  
	  my $init_method = $m_info->{'init_method'};
	  if ( $init_method ) {
	    $self->$init_method( @_ );
	  } elsif ( scalar @_ ) {
	    croak "No init_method";
	  }
	  return $self;
	}
      }},
      'set' => sub { my $m_info = $_[0]; sub {
	my $class = shift;
	$m_info->{'instance'} = shift 
      }},
      'new' => sub { my $m_info = $_[0]; sub {
	my $class = shift;
	
	croak "Prototype is not defined" unless $m_info->{'instance'};
	my $self = ref_clone($m_info->{'instance'});
	
	my $init_method = $m_info->{'init_method'};
	if ( $init_method ) {
	  $self->$init_method( @_ );
	} elsif ( scalar @_ ) {
	  croak "No init_method";
	}
	return $self;
      }},
    },
  } )
}

######################################################################

=head2 compare

Compare one object to another. 

B<Templates>

=over 4

=item *

default

Three-way (sorting-style) comparison.

=item *

equals

Are these two objects equivalent?

=item *

identity

Are these two references to the exact same object?

=back

=cut

sub compare {
  {
    'params' => { 'init_method' => '' },
    'interface' => {
      default => { '*'=>'compare',  },
      equals => { '*'=>'equals',  },
      identity => { '*'=>'identity',  },
    },
    'behavior' => {
      'compare' => sub { my $m_info = $_[0]; sub {
	  my $callee = shift; 
	  ref_compare( $callee, shift );
	}},
      'equals' => sub { my $m_info = $_[0]; sub {
	  my $callee = shift; 
	  ref_compare( $callee, shift ) == 0;
	}},
      'identity' => sub { my $m_info = $_[0]; sub {
	  $_[0] eq $_[1]
	}},
    },
  } 
}

######################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for more about this family of subclasses.

See L<Class::MakeMethods::Utility::Ref> for the clone and compare functions used above.

=cut

######################################################################

1;
