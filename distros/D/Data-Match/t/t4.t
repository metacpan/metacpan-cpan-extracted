#!/usr/bin/perl

# $Id: t4.t,v 1.2 2002/04/22 06:36:58 stephens Exp $

# Test for find adapter.

use strict;
use Test;

my $verbose = do { no warnings; $ENV{TEST_VERBOSE} > 1 };
my $debug = 1;

my $passes;

BEGIN 
{ 
  $passes = 10;
  plan tests => 4 * $passes;
};

use Data::Match qw(:all);
use Data::Dumper;
use Data::Compare;


##############################################################


package Foo;
sub new
{
  my ($cls, %opts) = @_;
  $opts{children} = [ ];
  bless \%opts, $cls;
}
sub x { shift->{x}; }
sub parent { shift->{parent}; }
sub children { shift->{children}; }
sub set_parent
{
  my ($self, $new_parent) = @_;
  if ( my $p = $self->{parent} ) {
    $self->{parent} = undef;
    $p->remove_child($self);
  }
  $self->{parent} = $new_parent;
}
sub add_child 
{ 
  my $self = shift; 
  for my $c ( @_ ) {
    $c->{parent}->remove_child($c) if $c->{parent};
    $c->{parent} = $self;
  }
  push(@{$self->{children}}, @_);
}
sub remove_child
{
  my $self = shift;
  for my $c ( @_ ) {
    @{$self->{children}} = grep($c ne $_, @{$self->{children}});
  }
}
sub all_children
{
  my ($self, $visited) = @_;
  $visited ||= {};

  if ( ! $visited->{$self} ) {
    $visited->{$self} = $self;
    for my $c ( @{$self->{children}} ) {
      $c->all_children($visited);
    }
  }
  values %$visited;
}


##############################################################


package main;

$Data::Match::match_opts{'find'}{'Foo'} = 
sub {
  my ($self, $visitor, $matchobj) = @_;
  
  warn "find in Foo $self->{x}" if ( $main::verbose );

  # Always do 'x'.
  $visitor->($self->x, 'METHOD', 'x');
  
  # Optional children traversal.
  if ( $matchobj->{'Foo_find_children'} ) {
    warn "Foo $self->{x} children = " . join(', ', map($_->x, @{$self->children}))  if ( $main::verbose );
    $visitor->($self->children, 'METHOD', 'children');
  }
  
  # Optional parent traversal.
  if ( $matchobj->{'Foo_find_parent'} ) {
    warn "Foo $self->{x} parent = " . join(', ', map($_->x, $self->parent))  if ( $main::verbose );
    $visitor->($self->parent, 'METHOD', 'parent');
  }
};

$Data::Match::match_opts{'no_collect_path'} = 1;
$Data::Match::match_opts{'collect_path_str'} = 1;


for my $pass ( 1 .. $passes ) {
  # Ten Foos.
  my $foos = [ map(new Foo('x' => $_), 1 .. 10) ];
  
  # Randomize parent child relationship until $foos->[0] has at least one child.
  do {
    for my $f ( @$foos ) { $foos->[rand($#$foos)]->add_child($f); }
  } while ( ! @{$foos->[0]->children} );
  
  ###################################################
  # Look for all Foos that are a child of $foos->[0].
  #

  my $is_a_child_of_foos_0 = sub {$_[0]->parent eq $foos->[0]};

  my $children_of_foos_0 = [ sort grep($is_a_child_of_foos_0->($_), @$foos) ];

  print "foos->[0]->children = ", join(', ', map($_->x, @{$foos->[0]->{children}})), "\n"
    if $verbose;

  my $pat1 = FIND(COLLECT('Foo', ISA('Foo', EXPR($is_a_child_of_foos_0))));
    
  ###################################################
  # Look for all subchildren of $foos->[0] where x is even.
  #

  my $is_x_even = sub {$_[0]->x % 2 == 0};

  my $all_children_of_foos_0_x_even = [ sort grep($is_x_even->($_), $foos->[0]->all_children) ];
 
  print "all_children_of_foos_0_x_even = ", join(', ', map($_->x, @$all_children_of_foos_0_x_even)), "\n"
    if $verbose;
  
  my $pat2 = FIND(COLLECT('Foo', ISA('Foo', EXPR($is_x_even))));

  ###################################################
  # Validate the tests.
  #

  my ($matches, $result);
  
#0
  ok( Compare($children_of_foos_0, [ sort @{$foos->[0]->children} ]) );
  ok( $matches = matches($foos, $pat1) ); $DB::single = $debug;
  ok( Compare($children_of_foos_0, [ sort @{$matches->{'COLLECT'}{'Foo'}{'v'}} ]) );
  ($result, $matches) = match($foos->[0], $pat2, 'Foo_find_children' => 1); $DB::single = $debug;
  ok( Compare($all_children_of_foos_0_x_even, [ sort @{$matches->{'COLLECT'}{'Foo'}{'v'} || []} ]) );

#5
  
#10
#15
#20
#25
};

1;

### Keep these comments at end of file: kurtstephens@acm.org 2001/12/28 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

