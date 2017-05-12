package Class::MakeMethods::Template::StructBuiltin;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.00;
use Carp;

=head1 NAME

Class::MakeMethods::Template::StructBuiltin

=head1 SYNOPSIS

  use Class::MakeMethods::Template::StructBuiltin (
    -TargetClass => 'MyStat',
    builtin_isa => [ 
      '-{new_function}'=>'stat', 
	qw/ dev ino mode nlink / 
    ]
  );


=head1 DESCRIPTION

This class generates a wrapper around some builtin function,
storing the results in the object and providing a by-name interface.

Takes a (core) function name, and a arrayref of return position names
(we will call it pos_list).  Creates:

=over 4

=item	new

Calls the core func with any given arguments, stores the result in the
instance.

=item	x

For each member of pos_list, creates a method of the same name which
gets/sets the nth member of the returned list, where n is the position
of x in pos_list.

=item	fields

Returns pos_list, in the given order.

=item	dump

Returns a list item name, item value, in order.

=back

Example Usage:

  package Stat;

  use Class::MakeMethods::Template::StructBuiltin
    builtin_isa => [ '-{new_function}'=>'stat', qw/ dev ino mode nlink / ],

  package main;

  my $file = "$ENV{HOME}/.template";
  my $s = Stat->new($file);
  print "File $file has ", $s->nlink, " links\n";

Note that (a) the new method does not check the return value of the
function called (in the above example, if $file does not exist, you will
silently get an empty object), and (b) if you really want the above
example, see the core File::stat module.   But you get the idea, I hope.

=cut

sub builtin_isa {  
  ( {
    'template' => {
      default => { 
	'*'=>'get_set', 'dump'=>'dump', 'fields'=>'fields', 'new'=>'new_builtin'
      },
    },
    'behavior' => {
      '-init' => sub {
	my $m_info = $_[0]; 
	
	$m_info->{class} ||= $m_info->{target_class};
	
	my $class_info = 
      ( $Class::MakeMethods::Struct::builtin{$m_info->{class}} ||= [] );
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
	
	if (defined $m_info->{new_function} and ! ref $m_info->{new_function}) {
	  # NOTE Below comments found in original version of MethodMaker. -Simon
	  # Cuz neither \&{"CORE::$func"} or $CORE::{$func} work ...  N.B. this
	  # only works for core functions that take only one arg. But I can't
	  # quite figure out how to pass in the list without it getting 
	  # evaluated in a scalar context. Hmmm.
	  $m_info->{new_function} = eval "sub { 
	      scalar \@_ ? CORE::$m_info->{new_function}(shift) 
			 : CORE::$m_info->{new_function} 
	  }";
	}
	
	return;	
      },
      
      'new_builtin' => sub { my $m_info = $_[0]; sub {
	  my $class = shift;
	  my $function = $m_info->{new_function};
	  my $self = [ &$function(@_) ];
	  bless $self, $class;
	}},
      
      'fields' => sub { my $m_info = $_[0]; sub {
	my $class_info = 
	  ( $Class::MakeMethods::Struct::builtin{$m_info->{class}} ||= [] );
	@$class_info;
	}},
      'dump' => sub { my $m_info = $_[0]; sub {
	my $self = shift;	
	my $class_info = 
	  ( $Class::MakeMethods::Struct::builtin{$m_info->{class}} ||= [] );
	my @keys = @$class_info;
	map ($keys[$_], $self->[$_]), 0 .. $#keys;
      }},
      
      'get_set' => sub { my $m_info = $_[0]; sub {
	my $self = shift;	
	if ( @_ ) {
	  $self->[ $m_info->{array_index} ] = shift;
	}
	$self->[ $m_info->{array_index} ];
	}},
    },
  } ) 
}

1;
