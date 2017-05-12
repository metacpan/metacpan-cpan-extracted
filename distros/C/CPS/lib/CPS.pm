#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package CPS;

use strict;
use warnings;

our $VERSION = '0.18';

use Carp;

our @CPS_PRIMS = qw(
   kloop
   kwhile
   kforeach
   kdescendd kdescendb

   kpar
   kpareach

   kseq
);

our @EXPORT_OK = (
   @CPS_PRIMS,
   map( "g$_", @CPS_PRIMS ),

qw(
   liftk
   dropk
),
);

use Exporter 'import';

use CPS::Governor::Simple;

# Don't hard-depend on Sub::Name since it's only a niceness for stack traces
BEGIN {
   if( eval { require Sub::Name } ) {
      *subname = \&Sub::Name::subname;
   }
   else {
      # Ignore the name, return the CODEref
      *subname = sub { return $_[1] };
   }
}

=head1 NAME

C<CPS> - manage flow of control in Continuation-Passing Style

=head1 OVERVIEW

The functions in this module implement or assist the writing of programs, or
parts of them, in Continuation Passing Style (CPS). Briefly, CPS is a style
of writing code where the normal call/return mechanism is replaced by explicit
"continuations", values passed in to functions which they should invoke, to
implement return behaviour. For more detail on CPS, see the SEE ALSO section.

What this module implements is not in fact true CPS, as Perl does not natively
support the idea of a real continuation (such as is created by a co-routine).
Furthermore, for CPS to be efficient in languages that natively support it,
their runtimes typically implement a lot of optimisation of CPS code, which
the Perl interpreter would be unable to perform. Instead, CODE references are
passed around to stand in their place. While not particularly useful for most
regular cases, this becomes very useful whenever some form of asynchronous or
event-based programming is being used. Continuations passed in to the body
function of a control structure can be stored in the event handlers of the
asynchronous or event-driven framework, so that when they are invoked later,
the code continues, eventually arriving at its final answer at some point in
the future.

In order for these examples to make sense, a fictional and simple
asynchronisation framework has been invented. The exact details of operation
should not be important, as it simply stands to illustrate the point. I hope
its general intention should be obvious. :)

 read_stdin_line( \&on_line ); # wait on a line from STDIN, then pass it
                               # to the handler function

This module itself provides functions that manage the flow of control through
a continuation passing program. They do not directly facilitate the flow of
data through a program. That can be managed by lexical variables captured by
the closures passed around. See the EXAMPLES section.

For CPS versions of data-flow functionals, such as C<map> and C<grep>, see
also L<CPS::Functional>.

=head1 SYNOPSIS

 use CPS qw( kloop );

 kloop( sub {
    my ( $knext, $klast ) = @_;

    print "Enter a number, or q to quit: ";

    read_stdin_line( sub {
       my ( $first ) = @_;
       chomp $first;

       return $klast->() if $first eq "q";

       print "Enter a second number: ";

       read_stdin_line( sub {
          my ( $second ) = @_;

          print "The sum is " . ( $first + $second ) . "\n";

          $knext->();
       } );
    } );
 },
 sub { exit }
 );

=cut

=head1 FUNCTIONS

In all of the following functions, the C<\&body> function can provide results
by invoking its continuation / one of its continuations, either synchronously
or asynchronously at some point later (via some event handling or other
mechanism); the next invocation of C<\&body> will not take place until the
previous one exits if it is done synchronously.

They all take the prefix C<k> before the name of the regular perl keyword or
function they aim to replace. It is common in CPS code in other languages,
such as Scheme or Haskell, to store a continuation in a variable called C<k>.
This convention is followed here.

=cut

=head2 kloop( \&body, $k )

CPS version of perl's C<while(true)> loop. Repeatedly calls the C<body> code
until it indicates the end of the loop, then invoke C<$k>.

 $body->( $knext, $klast )
    $knext->()
    $klast->()

 $k->()

If C<$knext> is invoked, the body will be called again. If C<$klast> is
invoked, the continuation C<$k> is invoked.

=head2 kwhile( \&body, $k )

Compatibility synonym for C<kloop>; it was renamed after version 0.10. New
code should use C<kloop> instead.

=cut

sub _fix
{
   my ( $func ) = @_;
   sub {
      unshift @_, _fix( $func );
      goto &$func;
   };
}

sub gkloop
{
   my ( $gov, $body, $k ) = @_;

   # We can't just call this as a method because we need to tailcall it
   # Instead, keep a reference to the actual method so we can goto &$enter
   my $enter = $gov->can('enter') or croak "Governor cannot ->enter";

   my $kfirst = _fix subname gkloop => sub {
      my $knext = shift;

      my $sync = 1;
      my $do_again;
      $enter->( $gov, $body,
         sub {
            if( $sync ) { $do_again=1 }
            else        { goto &$knext; }
         },
         sub { @_ = (); goto &$k },
      );
      $sync = 0;

      if( $do_again ) {
         $do_again = 0;
         goto &$knext;
      }
   };

   goto &$kfirst;
}

*gkwhile = \&gkloop;

=head2 kforeach( \@items, \&body, $k )

CPS version of perl's C<foreach> loop. Calls the C<body> code once for each
element in C<@items>, until either the items are exhausted or the C<body>
invokes its C<$klast> continuation, then invoke C<$k>.

 $body->( $item, $knext, $klast )
    $knext->()
    $klast->()

 $k->()

=cut

sub gkforeach
{
   my ( $gov, $items, $body, $k ) = @_;

   my $idx = 0;

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         goto &$klast unless $idx < scalar @$items;
         @_ =(
            $items->[$idx++],
            $knext,
            $klast
         );
         goto &$body;
      },
      $k,
   );
}

=head2 kdescendd( $root, \&body, $k )

CPS version of recursive descent on a tree-like structure, defined by a
function, C<body>, which when given a node in the tree, yields a list of
child nodes.

 $body->( $node, $kmore )
    $kmore->( @child_nodes )

 $k->()

The first value to be passed into C<body> is C<$root>. 

At each iteration, a node is given to the C<body> function, and it is expected
to pass a list of child nodes into its C<$kmore> continuation. These will then
be iterated over, in the order given. The tree-like structure is visited 
depth-first, descending fully into one subtree of a node before moving on to
the next.

This function does not provide a way for the body to accumulate a resultant
data structure to pass into its own continuation. The body is executed simply
for its side-effects and its continuation is invoked with no arguments. A
variable of some sort should be shared between the body and the continuation
if this is required.

=cut

sub gkdescendd
{
   my ( $gov, $root, $body, $k ) = @_;

   my @stack = ( $root );

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         @_ = (
            shift @stack,
            sub {
               unshift @stack, @_;

               goto &$knext if @stack;
               goto &$klast;
            },
         );
         goto &$body;
      },
      $k,
   );
}

=head2 kdescendb( $root, \&body, $k )

A breadth-first variation of C<kdescendd>. This function visits each child
node of the parent, before iterating over all of these nodes's children,
recursively until the bottom of the tree.

=cut

sub gkdescendb
{
   my ( $gov, $root, $body, $k ) = @_;

   my @queue = ( $root );

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         @_ = (
            shift @queue,
            sub {
               push @queue, @_;

               goto &$knext if @queue;
               goto &$klast;
            },
         );
         goto &$body;
      },
      $k,
   );
}

=head2 kpar( @bodies, $k )

This CPS function takes a list of function bodies and calls them all
immediately. Each is given its own continuation. Once every body has invoked
its continuation, the main continuation C<$k> is invoked.

 $body->( $kdone )
   $kdone->()

 $k->()

This allows running multiple operations in parallel, and waiting for them all
to complete before continuing. It provides in a CPS form functionality
similar to that provided in a more object-oriented fashion by modules such as
L<Async::MergePoint> or L<Event::Join>.

=cut

sub gkpar
{
   my ( $gov, @bodies ) = @_;
   my $k = pop @bodies;

   $gov->can('enter') or croak "Governor cannot ->enter";

   my $sync = 1;
   my @outstanding;
   my $kdone = sub {
      return if $sync;
      $_ and return for @outstanding;
      goto &$k;
   };

   gkforeach( $gov, [ 0 .. $#bodies ],
      sub {
         my ( $idx, $knext ) = @_;
         $outstanding[$idx]++;
         $gov->enter( $bodies[$idx], sub {
               $outstanding[$idx]--;
               @_ = ();
               goto &$kdone;
            } );
         goto &$knext;
      },
      sub {
         $sync = 0;
         @_ = ();
         goto &$kdone;
      }
   );
}

=head2 kpareach( \@items, \&body, $k )

This CPS function takes a list of items and a function body, and calls the
body immediately once for each item in the list. Each invocation is given its
own continuation. Once every body has invoked its continuation, the main
continuation C<$k> is invoked.

 $body->( $item, $kdone )
   $kdone->()

 $k->()

This is similar to C<kforeach>, except that the body is started concurrently
for all items in the list list, rather than each item waiting for the previous
to finish.

=cut

sub gkpareach
{
   my ( $gov, $items, $body, $k ) = @_;

   gkpar( $gov,
      (map {
         my $item = $_;
         sub {
            unshift @_, $item;
            goto &$body
         }
      } @$items),
      $k
   );
}

=head2 kseq( @bodies, $k )

This CPS function takes a list of function bodies and calls them each, one at
a time in sequence. Each is given a continuation to invoke, which will cause
the next body to be invoked. When the last body has invoked its continuation,
the main continuation C<$k> is invoked.

 $body->( $kdone )
   $kdone->()

 $k->()

A benefit of this is that it allows a long operation that uses many
continuation "pauses", to be written without code indenting further and
further to the right. Another is that it allows easy skipping of conditional
parts of a computation, which would otherwise be tricky to write in a CPS
form. See the EXAMPLES section.

=cut

sub gkseq
{
   my ( $gov, @bodies ) = @_;
   my $k = pop @bodies;

   my $enter = $gov->can('enter') or croak "Governor cannot ->enter";

   while( @bodies ) {
      my $nextk = $k;
      my $b = pop @bodies;
      $k = sub {
         @_ = ( $gov, $b, $nextk );
         goto &$enter;
      };
   }

   @_ = ();
   goto &$k;
}

=head1 GOVERNORS

All of the above functions are implemented using a loop which repeatedly calls
the body function until some terminating condition. By controlling the way
this loop re-invokes itself, a program can control the behaviour of the
functions.

For every one of the above functions, there also exists a variant which takes
a L<CPS::Governor> object as its first argument. These functions use the
governor object to control their iteration.

 kloop( \&body, $k )
 gkloop( $gov, \&body, $k )

 kforeach( \@items, \&body, $k )
 gkforeach( $gov, \@items, \&body, $k )

 etc...

In this way, other governor objects can be constructed which have different
running properties; such as interleaving iterations of their loop with other
IO activity in an event-driven framework, or giving rate-limitation control on
the speed of iteration of the loop.

=cut

# The above is a lie. The basic functions provided are actually the gk*
# versions; we wrap these to make the normal k* functions by passing a simple
# governor.
sub _governate
{
   my $pkg = caller;
   my ( $func, $name ) = @_;

   my $default_gov = CPS::Governor::Simple->new;

   no strict 'refs';

   my $code = $pkg->can( $func ) or croak "$pkg cannot $func()";
   *{$pkg."::$name"} = subname $name => sub {
      unshift @_, $default_gov;
      goto &$code;
   };
}

_governate "g$_" => $_ for @CPS_PRIMS;

=head1 CPS UTILITIES

These function names do not begin with C<k> because they are not themselves
CPS primatives, but may be useful in CPS-oriented code.

=cut

=head2 $kfunc = liftk { BLOCK }

=head2 $kfunc = liftk( \&func )

Returns a new CODE reference to a CPS-wrapped version of the code block or 
passed CODE reference. When C<$kfunc> is invoked, the function C<&func> is
called in list context, being passed all the arguments given to C<$kfunc>
apart from the last, expected to be its continuation. When C<&func> returns,
the result is passed into the continuation.

 $kfunc->( @func_args, $k )
    $k->( @func_ret )

The following are equivalent

 print func( 1, 2, 3 );

 my $kfunc = liftk( \&func );
 $kfunc->( 1, 2, 3, sub { print @_ } );

Note that the returned wrapper function only has one continuation slot in its
arguments. It therefore cannot be used as the body for C<kloop()>,
C<kforeach()> or C<kgenerate()>, because these pass two continuations. There
does not exist a "natural" way to lift a normal call/return function into a
CPS function which requires more than one continuation, because there is no
way to distinguish the different named returns.

=cut

sub liftk(&)
{
   my ( $code ) = @_;

   return sub {
      my $k = pop;
      @_ = $code->( @_ );
      goto &$k;
   };
}

=head2 $func = dropk { BLOCK } $kfunc

=head2 $func = dropk $waitfunc, $kfunc

Returns a new CODE reference to a plain call/return version of the passed
CPS-style CODE reference. When the returned ("dropped") function is called,
it invokes the passed CPS function, then waits for it to invoke its
continuation. When it does, the list that was passed to the continuation is
returned by the dropped function. If called in scalar context, only the first
value in the list is returned.

 $kfunc->( @func_args, $k )
    $k->( @func_ret )

 $waitfunc->()

 @func_ret = $func->( @func_args )

Given the following trivial CPS function:

 $kadd = sub { $_[2]->( $_[0] + $_[1] ) };

The following are equivalent

 $kadd->( 10, 20, sub { print "The total is $_[0]\n" } );

 $add = dropk { } $kadd;
 print "The total is ".$add->( 10, 20 )."\n";

In the general case the CPS function hasn't yet invoked its continuation by
the time it returns (such as would be the case when using any sort of
asynchronisation or event-driven framework). For C<dropk> to actually work in
this situation, it requires a way to run the event framework, to cause it to
process events until the continuation has been invoked.

This is provided by the block, or the first passed CODE reference. When the
returned function is invoked, it repeatedly calls the block or wait function,
until the CPS function has invoked its continuation.

=cut

sub dropk(&$)
{
   my ( $waitfunc, $kfunc ) = @_;

   return sub {
      my @result;
      my $done;

      $kfunc->( @_, sub { @result = @_; $done = 1 } );

      while( !$done ) {
         $waitfunc->();
      }

      return wantarray ? @result : $result[0];
   }
}

=head1 EXAMPLES

=head2 Returning Data From Functions

No facilities are provided directly to return data from CPS body functions in
C<kloop>, C<kpar> and C<kseq>. Instead, normal lexical variable capture may
be used here.

 my $bat;
 my $ball;

 kpar(
    sub {
       my ( $k ) = @_;
       get_bat( on_bat => sub { $bat = shift; goto &$k } );
    },
    sub {
       my ( $k ) = @_;
       serve_ball( on_ball => sub { $ball = shift; goto &$k } );
    },

    sub {
       $bat->hit( $ball );
    },
 );

The body function can set the value of a variable that it and its final
continuation both capture.

=head2 Using C<kseq> For Conditionals

Consider the call/return style of code

 A();
 if( $maybe ) {
    B();
 }
 C();

We cannot easily write this in CPS form without naming C twice

 kA( sub {
    $maybe ?
       kB( sub { kC() } ) :
       kC();
 } );

While not so problematic here, it could get awkward if C were in fact a large
code block, or if more than a single conditional were employed in the logic; a
likely scenario. A further issue is that the logical structure becomes much
harder to read.

Using C<kseq> allows us to name the continuation so each arm of C<kmaybe> can
invoke it indirectly.

 kseq(
    \&kA,
    sub { my $k = shift; $maybe ? kB( $k ) : goto &$k; },
    \&kC
 );

=head1 SEE ALSO

=over 4

=item *

L<CPS::Functional> - functional utilities in Continuation-Passing Style

=item *

L<http://en.wikipedia.org/wiki/Continuation-passing_style> on wikipedia

=item *

L<Coro> - co-routines in Perl

=back

=head1 ACKNOWLEDGEMENTS

Matt S. Trout (mst) <mst@shadowcat.co.uk> - for the inspiration of C<kpareach>
and with apologies to for naming of the said. ;)

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
