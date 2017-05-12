#   Permute.pm
#
#   Copyright (c) 1999 - 2008 Edwin Pratomo
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.

package Algorithm::Permute;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(permute);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.12';

bootstrap Algorithm::Permute $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Algorithm::Permute - Handy and fast permutation with object oriented interface

=head1 SYNOPSIS

  use Algorithm::Permute;

  # default is to create n of n objects permutation generator
  my $p = new Algorithm::Permute(['a'..'d']);

  # but also you can create r of n objects permutation generator, where r <= n
  my $p = new Algorithm::Permute([1..4], 3);

  while (@res = $p->next) {
    print join(", ", @res), "\n";
  }

  # and this one is the speed demon:
  my @array = (1..9);
  Algorithm::Permute::permute { print "@array\n" } @array;

=head1 DESCRIPTION

This handy module makes performing permutation in Perl easy and fast, 
although perhaps its algorithm is not the fastest on the earth. 
It supports permutation r of n objects where 0 < r <= n. 

=head1 METHODS

=over 4

=item new [@list]

Returns a permutor object for the given items. 

=item next

Returns a list of the items in the next permutation. 
The order of the resulting permutation is the same as of the previous version 
of C<Algorithm::Permute>.

=item peek

Returns the list of items which B<will be returned> by next(), but
B<doesn't advance the sequence>. Could be useful if you wished to skip
over just a few unwanted permutations.

=item reset

Resets the iterator to the start. May be used at any time, whether the
entire set has been produced or not. Has no useful return value.

=back

=head1 CALLBACK STYLE INTERFACE

Starting with version 0.03, there is a function - not exported by
default - which supports a callback style interface:

=over 4

=item permute BLOCK ARRAY

A block of code is passed, which will be executed for each permutation. The array will be changed in place,
and then changed back again before C<permute> returns. During the execution of the callback,
the array is read-only and you'll get an error if you try to change its length. (You I<can>
change its elements, but the consequences are liable to confuse you and may change in future
versions.)

You have to pass an array, it can't just be a list. It B<does> work with special arrays
and tied arrays, though unless you're doing something particularly abstruse you'd be
better off copying the elements into a normal array first. Example:

 my @array = (1..9);
 permute { print "@array\n" } @array;

The code is run inside a pseudo block, rather than as a normal subroutine. That means
you can't use C<return>, and you can't jump out of it using C<goto> and so on. Also,
C<caller> won't tell you anything helpful from inside the callback. Such is the price
of speed.

The order in which the permutations are generated is not guaranteed, so don't rely
on it. 

The low-level hack behind this function makes it currently the fastest way of doing
permutation among others. 

=back

=head1 COMPARISON

I've collected some Perl routines and modules which implement permutation,
and do some simple benchmark. The whole result is the following.

Permutation of B<eight> scalars:

  Abigail's                     :  9 wallclock secs ( 8.07 usr +  0.30 sys =  8.37 CPU)
  Algorithm::Permute            :  5 wallclock secs ( 5.72 usr +  0.00 sys =  5.72 CPU)
  Algorithm::Permute qw(permute):  2 wallclock secs ( 1.65 usr +  0.00 sys =  1.65 CPU)
  List::Permutor                : 27 wallclock secs (26.73 usr +  0.01 sys = 26.74 CPU)
  Memoization                   : 32 wallclock secs (32.55 usr +  0.02 sys = 32.57 CPU)
  perlfaq4                      : 36 wallclock secs (35.27 usr +  0.02 sys = 35.29 CPU)

Permutation of B<nine> scalars (the Abigail's routine is commented out, because
it stores all of the result in memory, swallows all of my machine's memory):

  Algorithm::Permute            :  43 wallclock secs ( 42.93 usr +  0.04 sys = 42.97 CPU)
  Algorithm::Permute qw(permute):  15 wallclock secs ( 14.82 usr +  0.00 sys = 14.82 CPU)
  List::Permutor                : 227 wallclock secs (226.46 usr +  0.22 sys = 226.68 CPU)
  Memoization                   : 307 wallclock secs (306.69 usr +  0.43 sys = 307.12 CPU)
  perlfaq4                      : 272 wallclock secs (271.93 usr +  0.33 sys = 272.26 CPU)

The benchmark script is included in the bench directory. I understand that 
speed is not everything. So here is the list of URLs of the alternatives, in 
case you hate this module.

=over 4

=item * 

Memoization is discussed in chapter 4 Perl Cookbook, so you can get it from
O'Reilly: ftp://ftp.oreilly.com/published/oreilly/perl/cookbook

=item *

Abigail's: http://www.foad.org/~abigail/Perl

=item *

List::Permutor: http://www.cpan.org/modules/by-module/List

=item *

The classic way, usually used by Lisp hackers: perldoc perlfaq4

=back

=head1 AUTHOR

Edwin Pratomo, I<edpratomo@cpan.org>. 

The object oriented interface is taken from Tom Phoenix's C<List::Permutor>.
Robin Houston <robin@kitsite.com> invented and contributed the callback
style interface.

=head1 ACKNOWLEDGEMENT

Yustina Sri Suharini - my ex-fiance-now-wife, for providing the permutation
problem to me.

=head1 SEE ALSO

=over 2

=item * B<Data Structures, Algorithms, and Program Style Using C> - 
Korsh and Garrett

=item * B<Algorithms from P to NP, Vol. I> - Moret and Shapiro

=back

=cut
