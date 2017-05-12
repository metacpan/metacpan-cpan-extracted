package Class::MakeMethods::Template::Array;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.00;
use Carp;

=head1 NAME

Class::MakeMethods::Template::Array - Methods for manipulating positional values in arrays

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

use vars qw( %ClassInfo );

sub generic {
  {
    'params' => {
      'array_index' => undef,
    },
    'code_expr' => { 
      _VALUE_ => '_SELF_->[_STATIC_ATTR_{array_index}]',
      '-import' => { 'Template::Generic:generic' => '*' },
      _EMPTY_NEW_INSTANCE_ => 'bless [], _SELF_CLASS_',
      _SET_VALUES_FROM_HASH_ => 'while ( scalar @_ ) { local $_ = shift(); $self->[ _BFP_FROM_NAME_{ $_ } ] = shift() }'
    },
    'behavior' => {
      '-init' => sub {
	my $m_info = $_[0]; 
	
	# If we're the first one, 
	if ( ! $ClassInfo{$m_info->{target_class}} ) {
	  # traverse inheritance hierarchy, looking for fields to inherit
	  my @results;
	  no strict 'refs';
	  my @sources = @{"$m_info->{target_class}\::ISA"};
	  while ( my $class = shift @sources ) {
	    next unless exists $ClassInfo{ $class };
	    push @sources, @{"$class\::ISA"};
	    if ( scalar @results ) { 
	      Carp::croak "Too many inheritances of fields";
	    }
	    push @results, @{$ClassInfo{$class}};
	  }
	  $ClassInfo{$m_info->{target_class}} = \@sources;
	}
	
	my $class_info = $ClassInfo{$m_info->{target_class}};
	if ( ! defined $m_info->{array_index} ) {
	  foreach ( 0..$#$class_info ) { 
	    if ( $class_info->[$_] eq $m_info->{'name'} ) {
	      $m_info->{array_index} = $_; last }
	  }
	  if ( ! defined $m_info->{array_index} ) {
	    push @ $class_info, $m_info->{'name'};
	    $m_info->{array_index} = $#$class_info;
	  }
	}
	
	return;	
      },
    },
  } 
}

########################################################################

=head2 Standard Methods

The following methods from Generic should be supported:

  scalar
  string
  number 
  boolean
  bits (?)
  array
  hash
  tiedhash (?)
  hash_of_arrays (?)
  object
  instance
  array_of_objects (?)
  code
  code_or_scalar (?)

See L<Class::MakeMethods::Template::Generic> for the interfaces and behaviors of these method types.

The items marked with a ? above have not been tested sufficiently; please inform the author if they do not function as you would expect.

=cut

########################################################################

1;
