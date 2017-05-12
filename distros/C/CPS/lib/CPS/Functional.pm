#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package CPS::Functional;

use strict;
use warnings;

our $VERSION = '0.18';

use Carp;

use Exporter 'import';

use CPS qw( gkloop );

our @CPS_PRIMS = qw(
   kmap
   kgrep
   kfoldl kfoldr
   kunfold
);

our @EXPORT_OK = (
   @CPS_PRIMS,
   map( "g$_", @CPS_PRIMS ),
);

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

C<CPS::Functional> - functional utilities in Continuation-Passing Style

=head1 SYNOPSIS

 use CPS::Functional qw( kmap );

 use Example::HTTP::Client qw( k_get_http );
 use List::Util qw( sum );

 my @URLs = (
    "http://www.foo.com",
    "http://www.bar.com",
 );

 kmap( \@URLs,
    sub {
       my ( $item, $kret ) = @_;

       k_get_http( uri => $item, on_response => sub {
          my ( $response ) = @_;

          $kret->( $response->content_length );
       } );
    },
    sub {
       my ( @sizes ) = @_;

       say "Total length of all URLs: " . sum(@sizes);
    },
 );

=head1 DESCRIPTION

This module provides L<CPS> versions of data-flow functionals, such as Perl's
C<map> and C<grep>, where function bodies are invoked and expected to return
data, which the functional manages. They are built on top of the control-flow
functionals provided by the C<CPS> module itself.

=cut

=head1 FUNCTIONS

=cut

=head2 kmap( \@items, \&body, $k )

CPS version of perl's C<map> statement. Calls the C<body> code once for each
element in C<@items>, capturing the list of values the body passes into its
continuation. When the items are exhausted, C<$k> is invoked and passed a list
of all the collected values.

 $body->( $item, $kret )
    $kret->( @items_out )

 $k->( @all_items_out )

=cut

sub gkmap
{
   my ( $gov, $items, $body, $k ) = @_;

   ref $items eq "ARRAY" or croak 'Expected $items as ARRAY ref';
   ref $body eq "CODE" or croak 'Expected $body as CODE ref';

   my @ret;
   my $idx = 0;

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         goto &$klast unless $idx < scalar @$items;
         @_ = (
            $items->[$idx++],
            sub { push @ret, @_; goto &$knext }
         );
         goto &$body;
      },
      sub { $k->( @ret ) },
   );
}

=head2 kgrep( \@items, \&body, $k )

CPS version of perl's C<grep> statement. Calls the C<body> code once for each
element in C<@items>, capturing those elements where the body's continuation
was invoked with a true value. When the items are exhausted, C<$k> is invoked
and passed a list of the subset of C<@items> which were selected.

 $body->( $item, $kret )
    $kret->( $select )

 $k->( @chosen_items )

=cut

sub gkgrep
{
   my ( $gov, $items, $body, $k ) = @_;

   ref $items eq "ARRAY" or croak 'Expected $items as ARRAY ref';
   ref $body eq "CODE" or croak 'Expected $body as CODE ref';

   my @ret;
   my $idx = 0;

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         goto &$klast unless $idx < scalar @$items;
         my $item = $items->[$idx++];
         @_ = (
            $item,
            sub { push @ret, $item if $_[0]; goto &$knext }
         );
         goto &$body;
      },
      sub { $k->( @ret ) },
   );
}

=head2 kfoldl( \@items, \&body, $k )

CPS version of C<List::Util::reduce>, which collapses (or "folds") a list of
values down to a single scalar, by successively accumulating values together.

If C<@items> is empty, invokes C<$k> immediately, passing in C<undef>.

If C<@items> contains a single value, invokes C<$k> immediately, passing in
just that single value.

Otherwise, initialises an accumulator variable with the first value in
C<@items>, then for each additional item, invokes the C<body> passing in the
accumulator and the next item, storing back into the accumulator the value
that C<body> passed to its continuation. When the C<@items> are exhausted, it
invokes C<$k>, passing in the final value of the accumulator.

 $body->( $acc, $item, $kret )
    $kret->( $new_acc )

 $k->( $final_acc )

Technically, this is not a true Scheme/Haskell-style C<foldl>, as it does not
take an initial value. (It is what Haskell calls C<foldl1>.) However, if such
an initial value is required, this can be provided by

 kfoldl( [ $initial, @items ], \&body, $k )

=cut

sub gkfoldl
{
   my ( $gov, $items, $body, $k ) = @_;

   ref $items eq "ARRAY" or croak 'Expected $items as ARRAY ref';
   ref $body eq "CODE" or croak 'Expected $body as CODE ref';

   $k->( undef ),       return if @$items == 0;
   $k->( $items->[0] ), return if @$items == 1;

   my $idx = 0;
   my $acc = $items->[$idx++];

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         goto &$klast unless $idx < scalar @$items;
         @_ = (
            $acc,
            $items->[$idx++],
            sub { $acc = shift; goto &$knext }
         );
         goto &$body;
      },
      sub { $k->( $acc ) },
   );
}

=head2 kfoldr( \@items, \&body, $k )

A right-associative version of C<kfoldl()>. Where C<kfoldl()> starts with the
first two elements in C<@items> and works forward, C<kfoldr()> starts with the
last two and works backward.

 $body->( $item, $acc, $kret )
    $kret->( $new_acc )

 $k->( $final_acc )

As before, an initial value can be provided by modifying the C<@items> array,
though note it has to be last this time:

 kfoldr( [ @items, $initial ], \&body, $k )

=cut

sub gkfoldr
{
   my ( $gov, $items, $body, $k ) = @_;

   ref $items eq "ARRAY" or croak 'Expected $items as ARRAY ref';
   ref $body eq "CODE" or croak 'Expected $body as CODE ref';

   $k->( undef ),       return if @$items == 0;
   $k->( $items->[0] ), return if @$items == 1;

   my $idx = scalar(@$items) - 1;
   my $acc = $items->[$idx--];

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         goto &$klast if $idx < 0;
         @_ = (
            $items->[$idx--],
            $acc,
            sub { $acc = shift; goto &$knext }
         );
         goto &$body;
      },
      sub { $k->( $acc ) },
   );
}

=head2 kunfold( $seed, \&body, $k )

An inverse operation to C<kfoldl()>; turns a single scalar into a list of
items. Repeatedly calls the C<body> code, capturing the values it returns,
until it indicates the end of the loop, then invoke C<$k> with the collected
values.

 $body->( $seed, $kmore, $kdone )
    $kmore->( $new_seed, @items )
    $kdone->( @items )

 $k->( @all_items )

With each iteration, the C<body> is invoked and passed the current C<$seed>
value and two continuations, C<$kmore> and C<$kdone>. If C<$kmore> is invoked,
the passed items, if any, are appended to the eventual result list. The
C<body> is then re-invoked with the new C<$seed> value. If C<$klast> is
invoked, the passed items, if any, are appended to the return list, then the
entire list is passed to C<$k>.

=cut

sub gkunfold
{
   my ( $gov, $seed, $body, $k ) = @_;

   ref $body eq "CODE" or croak 'Expected $body as CODE ref';

   my @ret;

   gkloop( $gov,
      sub {
         my ( $knext, $klast ) = @_;
         @_ = (
            $seed,
            sub { $seed = shift; push @ret, @_; goto &$knext },
            sub { push @ret, @_; goto &$klast },
         );
         goto &$body;
      },
      sub { $k->( @ret ) },
   );
}

CPS::_governate "g$_" => $_ for @CPS_PRIMS;

=head1 EXAMPLES

The following aren't necessarily examples of code which would be found in real
programs, but instead, demonstrations of how to use the above functions as
ways of controlling program flow.

Without dragging in large amount of detail on an asynchronous or event-driven
framework, it is difficult to give a useful example of behaviour that CPS
allows that couldn't be done just as easily without. Nevertheless, I hope the
following examples will be useful to demonstrate use of the above functions,
in a way which hints at their use in a real program.

=head2 Implementing C<join()> using C<kfoldl()>

 use CPS::Functional qw( kfoldl );

 my @words = qw( My message here );

 kfoldl(
    \@words,
    sub {
       my ( $left, $right, $k ) = @_;

       $k->( "$left $right" );
    },
    sub {
       my ( $str ) = @_;

       print "Joined up words: $str\n";
    }
 );

=head2 Implementing C<split()> using C<kunfold()>

The following program illustrates the way that C<kunfold()> can split a
string, in a reverse way to the way C<kfoldl()> can join it.

 use CPS::Functional qw( kunfold );

 my $str = "My message here";

 kunfold(
    $str,
    sub {
       my ( $s, $kmore, $kdone ) = @_;

       if( $s =~ s/^(.*?) // ) {
          return $kmore->( $s, $1 );
       }
       else {
          return $kdone->( $s );
       }
    },
    sub {
       my @words = @_;
       print "Words in message:\n";
       print "$_\n" for @words;
    }
 );

=head2 Generating Prime Numbers

While the design of C<kunfold()> is symmetric to C<kfoldl()>, the seed value
doesn't have to be successively broken apart into pieces. Another valid use
for it may be storing intermediate values in computation, such as in this
example, storing a list of known primes, to help generate the next one:

 use CPS::Functional qw( kunfold );
 
 kunfold(
    [ 2, 3 ],
    sub {
       my ( $vals, $kmore, $kdone ) = @_;
 
       return $kdone->() if @$vals >= 50;
 
       PRIME: for( my $n = $vals->[-1] + 2; ; $n += 2 ) {
          $n % $_ == 0 and next PRIME for @$vals;
 
          push @$vals, $n;
          return $kmore->( $vals, $n );
       }
    },
    sub {
       my @primes = ( 2, 3, @_ );
       print "Primes are @primes\n";
    }
 );

=head2 Forward-reading Program Flow

One side benefit of the CPS control-flow methods which is unassociated with
asynchronous operation, is that the flow of data reads in a more natural
left-to-right direction, instead of the right-to-left flow in functional
style. Compare

 sub square { $_ * $_ }
 sub add { $a + $b }

 print reduce( \&add, map( square, primes(10) ) );

(because C<map> is a language builtin but C<reduce> is a function with C<(&)>
prototype, it has a different way to pass in the named functions)

with

 my $ksquare = liftk { $_[0] * $_[0] };
 my $kadd = liftk { $_[0] + $_[1] };

 kprimes 10, sub {
    kmap \@_, $ksquare, sub {
       kfoldl \@_, $kadd, sub {
          print $_[0];
       }
    }
 };

This translates roughly to a functional vs imperative way to describe the
problem:

 Print the sum of the squares of the first 10 primes.

 Take the first 10 primes. Square them. Sum them. Print.

Admittedly the closure creation somewhat clouds the point in this small
example, but in a larger example, the real problem-solving logic would be
larger, and stand out more clearly against the background boilerplate.

=head1 SEE ALSO

=over 4

=item *

L<CPS> - manage flow of control in Continuation-Passing Style

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
