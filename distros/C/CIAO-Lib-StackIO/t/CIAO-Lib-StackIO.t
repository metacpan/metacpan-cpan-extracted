use Test::More tests => 80;
BEGIN { use_ok('CIAO::Lib::StackIO') };

use strict;
use warnings;

# tests of the constructor.

my $stack;

# an empty stack
$stack = CIAO::Lib::StackIO->new( );
ok( 0 == $stack->count, "empty stack" );


# simple stack
$stack = CIAO::Lib::StackIO->new( 'foo' );
ok( 1 == $stack->count,   "simple stack: count" );
ok( 0 == $stack->current, "simple stack: current" );

ok( "foo" eq $stack->read, "simple stack: entry" );
ok( 1 == $stack->current,  "simple stack: current" );


# expand stack
$stack = CIAO::Lib::StackIO->new( 'foo#', { expand => 10 } );
ok( 10 == $stack->count, "expand stack: count" );

# test read
ok( "foo01" eq $stack->read(1), "expand stack: entry" );
ok( "foo10" eq $stack->read(-1), "expand stack: entry" );

my $test = "foo00";
while ( my $val = $stack->read )
{
  ok ( ++$test eq $val, "read next/val $test" );
}

ok ( $stack->current == $stack->count, "bounds after read" );

##################################################################
# rewind
$stack->rewind;
ok ( 0 == $stack->current, "rewind" );

##################################################################
# set current
ok ( 0 == $stack->current( 3 ) &&
     3 == $stack->current, "set current" );

# check special end of list value.
ok ( $stack->current( -1 ) &&
     $stack->count == $stack->current, "set current to end" );

# make sure we can do a current(0)
ok( $stack->current(0) && 0 == $stack->current, "set current to pre start");


##################################################################
# test read in list context;

# expect all entries, regardless of where the stack is at.

for my $pos ( 10, 3, 0 )
{
  $stack->current($pos);
  my @list = $stack->read;
  ok ( 10 == @list , "read list ($pos): count" );

  # stack should still be at $pos
  ok( $pos == $stack->current, "read list ($pos): current" );

  # check items now.
  $test = "foo00";
  ok( ++$test eq $_, "read list ($pos): val $test" ) foreach @list;
}

##################################################################

# change the current item
$stack->rewind;
$stack->change( "goo" );
ok( "goo" eq $stack->read(1), "change current" );

# change the 2nd item
$stack->change( "xoo", 2 );
ok( "xoo" eq $stack->read(2), "change second" );

# change the last item
$stack->change( "snoo", -1 );
ok( "snoo" eq $stack->read(-1), "change last" );

# delete the current item
$stack->current(3);
$stack->delete;
ok( 9 == $stack->count, "delete current: count" );
ok( "foo04" eq $stack->read( $stack->current ), "delete current: entry" );

# delete the first item
$stack->delete(1);
ok( 8 == $stack->count, "delete first: count" );
ok( "xoo" eq $stack->read( 1 ), "delete first: entry" );

# delete the last item
$stack->delete(-1);
ok( 7 == $stack->count, "delete last: count" );
ok( "foo09" eq $stack->read( -1 ), "delete last: entry" );


# append, no prepend
$stack->append( "fortuna" );
ok( 8 == $stack->count, "append: count" );
ok( "fortuna" eq $stack->read( -1 ), "append: entry" );



# now try a stack file

$stack = CIAO::Lib::StackIO->new( '@data/stack01' );

ok( $_ eq $stack->read, "stack file prepend: $_" ) foreach
  map { "data/$_" } slurp( 'data/stack01' );

# once again, no prepending

$stack = CIAO::Lib::StackIO->new( '@data/stack01', { prepend => 0 } );

ok( $_ eq $stack->read, "stack file no prepend: $_" )
     foreach slurp( 'data/stack01' );

# now, try appending with prepending!
$stack = CIAO::Lib::StackIO->new;

$stack->append( '@data/stack01', 1 );

ok( $_ eq $stack->read, "stack file append prepend: $_" ) foreach
  map { "data/$_" } slurp( 'data/stack01' );

sub slurp
{
  my ( $file ) = @_;
  open ( FILE, $file  ) or die ( "unable to open $file\n" );
  chomp ( my @lines = <FILE>);
  @lines;
}
