package Array::Unique;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.08';

# Strips out any duplicate values (leaves the first occurrence
# of every duplicated value and drops the later occurrences).
# Removes all undef values.
sub unique {
    my $self = shift; # self or class

    my %seen;
    my @unique = grep defined $_ && !$seen{$_}++, @_;
    # based on the Cookbook 1st edition and on suggestion by Jeff 'japhy' Pinyan
    # fixed by  Werner Weichselberger
}


sub TIEARRAY {
    my $class = shift;
    my $self = {
        array => [],
        hash => {},
        };
    bless $self, $class;
}


sub CLEAR     { 
    my $self = shift;
    $self->{array} = [];
    $self->{hash} = {};
}

sub EXTEND {}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->SPLICE($index, 1, $value);
}



sub FETCHSIZE { 
    my $self = shift;
    return scalar @{$self->{array}};
}

sub FETCH { 
    my ($self, $index) = @_;
    ${$self->{array}}[$index];
}


sub STORESIZE { 
    my $self = shift;
    my $size = shift;

    # We cannot enlarge the array as the values would be undef

    # But we can make it smaller
#   if ($self->FETCHSIZE > $size) {
#   $self->{->_splice($size);
#    }

    $#{$self->{array}} = $size-1;
    return $size;
}

sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    # reset length value to positive (this is done by the normal splice too)
    if (defined $length and $length < 0) {
    #$length = @{$self->{array}} + $length;
    $length += $self->FETCHSIZE - $offset;
    }

    # reset offset to positive (this is done by the normal splice too)
    if (defined $offset and $offset < 0) {
    $offset += $self->FETCHSIZE;
    }

    if (defined $offset and $offset > $self->FETCHSIZE) {
        $offset = $self->FETCHSIZE;
        # should give a warning like this: splice() offset past end of array
        # if this was really a splice (and warning set) but no warning if this
        # was an assignment to a high index.
    }

#    my @s = @{$self->{array}}[$offset..$offset+$length]; # the old values to be returned
    my @original;
#    if (defined $length) {
    @original = $self->_splice($self->{array}, $offset, $length, @_);
#    } elsif (defined $offset) {
#   @original = $self->_splice($self->{array}, $offset);
#    } else {
#   @original = $self->_splice($self->{array});
#    }

    return @original;
}



sub PUSH {
    my $self = shift;

    $self->SPLICE($self->FETCHSIZE, 0, @_);
#    while (my $value = shift) {
#   $self->STORE($self->FETCHSIZE+1, $value);
#    }
    return $self->FETCHSIZE;
}

sub POP {
    my $self = shift;
    ($self->SPLICE(-1))[0];
}

sub SHIFT {
    my $self = shift;
#    #($self->{array})[0];
    ($self->SPLICE(0,1))[0];
}

sub UNSHIFT {
    my $self = shift;
    $self->SPLICE(0,0,@_);
}


sub _splice {
    my $self = shift;
    my $a = shift;
    my $offset = shift;
    my $length = shift;

    my @original;
    if (defined $length) {
        @original = splice(@$a, $offset, $length, @_);
    } elsif (defined $offset) {
        @original = splice(@$a, $offset);
    } else {
        @original = splice(@$a);
    }
    @$a = $self->unique(@$a);
    return @original;
}

=head1 NAME

Array::Unique - Tie-able array that allows only unique values

=head1 SYNOPSIS

 use Array::Unique;
 tie @a, 'Array::Unique';

 Now use @a as a regular array.

=head1 DESCRIPTION

This package lets you create an array which will allow
only one occurrence of any value.

In other words no matter how many times you put in 42
it will keep only the first occurrence and the rest will
be dropped.

You use the module via tie and once you tied your array to
this module it will behave correctly.

Uniqueness is checked with the 'eq' operator so 
among other things it is case sensitive.

As a side effect the module does not allow undef as a value in the array.

=head1 EXAMPLES

 use Array::Unique;
 tie @a, 'Array::Unique';

 @a = qw(a b c a d e f);
 push @a, qw(x b z);
 print "@a\n";          # a b c d e f x z

=head1 DISCUSSION

When you are collecting a list of items and you want 
to make sure there is only one occurrence of each item,
you have several option:


=over 4

=item 1) using an array and extracting the unique elements later

You might use a regular array to hold this unique set of values
and either remove duplicates on each update by that keeping the array
always unique or remove duplicates just before you want to use the 
uniqueness feature of the array. In either case you might run a 
function you call @a = unique_value(@a);

The problem with this approach is that you have to implement 
the unique_value function (see later) AND you have to make sure you 
don't forget to call it. I would say don't rely on remembering this.
 

There is good discussion about it in the 1st edition of the 
Perl Cookbook of O'Reilly. I have copied the solutions here, 
you can see further discussion in the book.

Extracting Unique Elements from a List (Section 4.6 in the Perl Cookbook 1st ed.)

# Straightforward

 %seen = ();
 @uniq = ();
 foreach $item (@list) [
     unless ($seen{$item}) {
       # if we get here we have not seen it before
       $seen{$item} = 1;
       push (@uniq, $item);
    }
 } 

# Faster

 %seen = ();
 foreach $item (@list) {
   push(@uniq, $item) unless $seen{$item}++;
 }

# Faster but different

 %seen;
 foreach $item (@list) {
   $seen{$item}++;
 }
 @uniq = keys %seen;

 # Faster and even more different
 %seen;
 @uniq = grep {! $seen{$_}++} @list;


=item 2) using a hash

Some people use the keys of a hash to keep the items and
put an arbitrary value as the values of the hash:

To build such a list:

 %unique = map { $_ => 1 } qw( one two one two three four! );

To print it:

 print join ", ", sort keys %unique;

To add values to it:

 $unique{$_}=1 foreach qw( one after the nine oh nine );

To remove values:

 delete @unique{ qw(oh nine) };

To check if a value is there:

 $unique{ $value };        # which is why I like to use "1" as my value

(thanks to Gaal Yahas for the above examples)

There are three drawbacks I see:

=over 4

=item 1) You type more.

=item 2) Your reader might not understand at first why did you use hash 
    and what will be the values.

=item 3) You lose the order.

=back

Usually non of them is critical but when I saw this the 10th time
in a code I had to understand with 0 documentation I got frustrated.


=item 3) using Array::Unique

So I decided to write this module because I got frustrated
by my lack of understanding what's going on in that code
I mentioned.

In addition I thought it might be interesting to write this and
then benchmark it.

Additionally it is nice to have your name displayed in 
bright lights all over CPAN ... or at least in a module.

Array::Unique lets you tie an array to hmmm, itself (?)
and makes sure the values of the array are always unique.

Since writing this I am not sure if I really recommend its usage.
I would say stick with the hash version and document that the
variable is aggregating a unique list of values.


=item 4) Using real SET

There are modules on CPAN that let you create and maintain SETs.
I have not checked any of those but I guess they just as much of
an overkill for this functionality as Unique::Array.


=back

=head1 BUGS

 use Array::Unique;
 tie @a, 'Array::Unique';

 @c = @a = qw(a b c a d e f b);
 
 @c will contain the same as @a AND two undefs at the end because
 @c you get the same length as the right most list.

=head1 TODO

Test:

Change size of the array
Elements with false values ('', '0', 0) 

   splice:
   splice @a;
   splice @a,  3;
   splice @a, -3;
   splice @a,  3,  5;
   splice @a,  3, -5;
   splice @a, -3,  5;
   splice @a, -3, -5;
   splice @a,  ?,  ?, @b;



Benchmark speed

Add faster functions that don't check uniqueness so if I 
know part of the data that comes from a unique source then
I can speed up the process,
In short shoot myself in the leg.

Enable optional compare with other functions

Write even better implementations.

=head1 AUTHOR

Gabor Szabo <gabor@pti.co.il>

=head1 LICENSE

Copyright (C) 2002-2008 Gabor Szabo <gabor@pti.co.il>
All rights reserved.  http://www.pti.co.il/

You may distribute under the terms of either the GNU 
General Public License or the Artistic License, as 
specified in the Perl README file.

No WARRANTY whatsoever.

=head1 CREDITS

 Thanks for suggestions and bug reports to 
 Szabo Balazs (dLux)
 Shlomo Yona
 Gaal Yahas
 Jeff 'japhy' Pinyan
 Werner Weichselberger

=head1 VERSION

Version: 0.08

Date:    2008 June 04

=cut

1;

