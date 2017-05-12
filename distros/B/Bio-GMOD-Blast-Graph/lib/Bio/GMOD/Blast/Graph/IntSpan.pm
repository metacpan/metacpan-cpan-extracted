# $Id: IntSpan.pm,v 1.2 2007-02-07 17:52:39 briano Exp $
# $Log: not supported by cvs2svn $
# Revision 1.1.1.1  2005/11/09 18:20:47  scottcain
# initial import
#
# Revision 1.2  2003/08/28 22:27:16  shuai
# *** empty log message ***
#
# Revision 1.1  2003/05/09 21:07:56  shuai
# Initial revision
#
# Revision 1.1  1999/10/08  22:49:16  blast
# Initial revision
#
# Revision 1.6  1996/06/03  18:28:29  swm
# runs clean under -w
# moved test code to t/*.t
#
# Revision 1.5  1996/05/30  13:34:47  swm
# added valid(), min() and max()
# documentation fixes
#
# Revision 1.4  1996/02/22  20:06:04  swm
# added $Bio::GMOD::Blast::Graph::IntSpan::Empty_String
# made IntSpan an Exporter
# documentation fixes

package Bio::GMOD::Blast::Graph::IntSpan;
BEGIN {
  $Bio::GMOD::Blast::Graph::IntSpan::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::IntSpan::VERSION = '0.06';
}
$Bio::GMOD::Blast::Graph::IntSpan::VERSION = 1.03;

require Exporter;
@ISA = qw(Exporter);

use strict;
use integer;



$Bio::GMOD::Blast::Graph::IntSpan::Empty_String = '-';


sub new
{
    my($class, $set_spec) = @_;

    my $set = bless { }, $class;
    $set->{empty_string} = \$Bio::GMOD::Blast::Graph::IntSpan::Empty_String;
    copy $set $set_spec;
}


sub valid
{
    my($class, $run_list) = @_;

    my $set = new Bio::GMOD::Blast::Graph::IntSpan;
    eval { _copy_run_list $set $run_list };
    return $@ ? 0 : 1;
}


sub copy
{
    my($set, $set_spec) = @_;

  SWITCH:
    {
            $set_spec             or  _copy_empty   ($set           ), last;
        ref $set_spec             or  _copy_run_list($set, $set_spec), last;
        ref $set_spec eq 'ARRAY'  and _copy_array   ($set, $set_spec), last;
                                      _copy_set     ($set, $set_spec)      ;
    }

    $set;
}


sub _copy_empty                 # makes $set the empty set
{
    my $set = shift;

    $set->{negInf} = 0;
    $set->{posInf} = 0;
    $set->{edges } = [];
}


sub _copy_array                 # copies an array into a set
{
    my($set, $array) = @_;
    my($element, @edges);

    $set->{negInf} = 0;
    $set->{posInf} = 0;

    for $element (sort { $Bio::GMOD::Blast::Graph::IntSpan::a <=> $Bio::GMOD::Blast::Graph::IntSpan::b } @$array)
    {
        next if @edges and $edges[-1] == $element; # skip duplicates

        if (@edges and $edges[-1] == $element-1)
        {
            $edges[-1] = $element;
        }
        else
        {
            push @edges, $element-1, $element;
        }
    }

    $set->{edges} = \@edges;
}


sub _copy_set                   # copies one set to another
{
    my($dest, $src) = @_;

    $dest->{negInf} =     $src->{negInf};
    $dest->{posInf} =     $src->{posInf};
    $dest->{edges } = [ @{$src->{edges }} ];
}


sub _copy_run_list              # parses a run list
{
    my($set, $runList) = @_;
    my($run, @edges);

    _copy_empty($set);

    $runList =~ s/\s|_//g;
    return if $runList eq '-';  # empty set

    my($first, $last) = (1, 0); # verifies order of infinite runs

    for $run (split(/,/ , $runList))
    {
        die "Bad order: $runList\n" if $last;

      RUN:
        {
            $run =~ /^ (-?\d+) $/x and do
            {
                push(@edges, $1-1, $1);
                last RUN;
            };

            $run =~ /^ (-?\d+) - (-?\d+) $/x and do
            {
                die "Bad order: $runList\n" if $1 > $2;
                push(@edges, $1-1, $2);
                last RUN;
            };

            $run =~ /^ \( - (-?\d+) $/x and do
            {
                die "Bad order: $runList\n" unless $first;
                $set->{negInf} = 1;
                push @edges, $1;
                last RUN;
            };

            $run =~ /^ (-?\d+) - \) $/x and do
            {
                push @edges, $1-1;
                $set->{posInf} = 1;
                $last = 1;
                last RUN;
            };

            $run =~ /^ \( - \) $/x and do
            {
                die "Bad order: $runList\n" unless $first;
                $last = 1;
                $set->{negInf} = 1;
                $set->{posInf} = 1;
                last RUN;
            };

            die "Bad syntax: $runList\n";
        }

        $first = 0;
    }

    $set->{edges} = [ @edges ];

    _cleanup $set or die "Bad order: $runList\n";
}


# check for overlapping runs
# delete duplicate edges
sub _cleanup
{
    my $set = shift;
    my $edges = $set->{edges};

    my $i=0;
    while ($i < $#$edges)
    {
        my $cmp = $$edges[$i] <=> $$edges[$i+1];
        {
            $cmp == -1 and $i++                  , last;
            $cmp ==  0 and splice(@$edges, $i, 2), last;
            $cmp ==  1 and return 0;
        }
    }

    1;
}


sub run_list
{
    my $set = shift;

    return ${$set->{empty_string}} if empty $set;

    my @edges = @{$set->{edges}};
    my @runs;

    $set->{negInf} and unshift @edges, '(';
    $set->{posInf} and push    @edges, ')';

    while(@edges)
    {
        my($lower, $upper) = splice @edges, 0, 2;

        if ($lower ne '(' and $upper ne ')' and $lower+1==$upper)
        {
            push @runs, $upper;
        }
        else
        {
            $lower ne '(' and $lower++;
            push @runs, "$lower-$upper";
        }
    }

    join(',', @runs);
}


sub elements
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and die "elements: infinite set\n";

    my @elements;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
        my $lower = shift(@edges) + 1;
        my $upper = shift(@edges);
        push @elements, $lower..$upper;
    }

    wantarray ? @elements : \@elements;
}


sub _real_set                   # converts a set specification into a set
{
    my($set_spec) = shift;

  SWITCH:
    {
            $set_spec             or  return new Bio::GMOD::Blast::Graph::IntSpan;
        ref $set_spec             or  return new Bio::GMOD::Blast::Graph::IntSpan $set_spec;
        ref $set_spec eq 'ARRAY'  and return new Bio::GMOD::Blast::Graph::IntSpan $set_spec;
    }

    $set_spec;
}


sub union
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    my $s = new Bio::GMOD::Blast::Graph::IntSpan;
    $s->{negInf} = $a->{negInf} || $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;
    while ($iA<@$eA and $iB<@$eB)
    {
        my $xA = $$eA[$iA];
        my $xB = $$eB[$iB];

        if ($xA < $xB)
        {
            $iA++;
            $inA = ! $inA;
            not $inB and push(@$eS, $xA);
        }
        elsif ($xB < $xA)
        {
            $iB++;
            $inB = ! $inB;
            not $inA and push(@$eS, $xB);
        }
        else
        {
            $iA++;
            $iB++;
            $inA = ! $inA;
            $inB = ! $inB;
            $inA == $inB and push(@$eS, $xA);
        }
    }

    $iA < @$eA and ! $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and ! $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} || $b->{posInf};
    $s;
}


sub intersect
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    my $s = new Bio::GMOD::Blast::Graph::IntSpan;
    $s->{negInf} = $a->{negInf} && $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;
    while ($iA<@$eA and $iB<@$eB)
    {
        my $xA = $$eA[$iA];
        my $xB = $$eB[$iB];

        if ($xA < $xB)
        {
            $iA++;
            $inA = ! $inA;
            $inB and push(@$eS, $xA);
        }
        elsif ($xB < $xA)
        {
            $iB++;
            $inB = ! $inB;
            $inA and push(@$eS, $xB);
        }
        else
        {
            $iA++;
            $iB++;
            $inA = ! $inA;
            $inB = ! $inB;
            $inA == $inB and push(@$eS, $xA);
        }
    }

    $iA < @$eA and $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && $b->{posInf};
    $s;
}


sub diff
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    my $s = new Bio::GMOD::Blast::Graph::IntSpan;
    $s->{negInf} = $a->{negInf} && ! $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;
    while ($iA<@$eA and $iB<@$eB)
    {
        my $xA = $$eA[$iA];
        my $xB = $$eB[$iB];

        if ($xA < $xB)
        {
            $iA++;
            $inA = ! $inA;
            not $inB and push(@$eS, $xA);
        }
        elsif ($xB < $xA)
        {
            $iB++;
            $inB = ! $inB;
            $inA and push(@$eS, $xB);
        }
        else
        {
            $iA++;
            $iB++;
            $inA = ! $inA;
            $inB = ! $inB;
            $inA != $inB and push(@$eS, $xA);
        }
    }

    $iA < @$eA and not $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and     $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && ! $b->{posInf};
    $s;
}


sub xor
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    my $s = new Bio::GMOD::Blast::Graph::IntSpan;
    $s->{negInf} = $a->{negInf} ^ $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $iA = 0;
    my $iB = 0;
    while ($iA<@$eA and $iB<@$eB)
    {
        my $xA = $$eA[$iA];
        my $xB = $$eB[$iB];

        if ($xA < $xB)
        {
            $iA++;
            push(@$eS, $xA);
        }
        elsif ($xB < $xA)
        {
            $iB++;
            push(@$eS, $xB);
        }
        else
        {
            $iA++;
            $iB++;
        }
    }

    $iA < @$eA and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} ^ $b->{posInf};
    $s;
}


sub complement
{
    my $set = shift;
    my $comp = new Bio::GMOD::Blast::Graph::IntSpan $set;

    $comp->{negInf} = ! $comp->{negInf};
    $comp->{posInf} = ! $comp->{posInf};
    $comp;
}


sub superset
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    empty(diff($b, $a));
}


sub subset
{
    my($a, $b) = @_;

    empty(diff($a, $b));
}


sub equal
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    return 0 unless $a->{negInf} == $b->{negInf};
    return 0 unless $a->{posInf} == $b->{posInf};

    my $aEdge = $a->{edges};
    my $bEdge = $b->{edges};
    return 0 unless @$aEdge == @$bEdge;

    my $i;
    for ($i=0; $i<@$aEdge; $i++)
    {
        return 0 unless $$aEdge[$i] == $$bEdge[$i];
    }

    1;
}


sub equivalent
{
    my($a, $set_spec) = @_;
    my $b = _real_set($set_spec);

    cardinality($a) == cardinality($b);
}


sub cardinality
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and return -1;

    my $cardinality = 0;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
        my $lower = shift @edges;
        my $upper = shift @edges;
        $cardinality += $upper - $lower;
    }

    $cardinality;
}


sub empty
{
    my $set = shift;

    not $set->{negInf} and not @{$set->{edges}} and not $set->{posInf};
}


sub finite
{
    my $set = shift;

    not $set->{negInf} and not $set->{posInf};
}


sub neg_inf
{
    my $set = shift;

    $set->{negInf};
}


sub pos_inf
{
    my $set = shift;

    $set->{posInf};
}


sub infinite
{
    my $set = shift;

    $set->{negInf} or $set->{posInf};
}


sub universal
{
    my $set = shift;

    $set->{negInf} and not @{$set->{edges}} and $set->{posInf};
}


sub member
{
    my($set, $n) = @_;

    my $inSet = $set->{negInf};

    my $edge = $set->{edges};
    my $i;

    for ($i=0; $i<@$edge; $i++)
    {
        if ($inSet)
        {
            return 1 if $n <= $$edge[$i];
            $inSet = 0;
        }
        else
        {
            return 0 if $n <= $$edge[$i];
            $inSet = 1;
        }
    }

    $inSet;
}


sub insert
{
    my($set, $n) = @_;

    my $inSet = $set->{negInf};

    my $edge = $set->{edges};
    my $i;

    for ($i=0; $i<@$edge; $i++)
    {
        if ($inSet)
        {
            return if $n <= $$edge[$i];
            $inSet = 0;
        }
        else
        {
            last if $n <= $$edge[$i];
            $inSet = 1;
        }
    }

    return if $inSet;

    splice @{$set->{edges}}, $i, 0, $n-1, $n;
    _cleanup($set);
}

sub remove
{
    my($set, $n) = @_;

    my $inSet = $set->{negInf};

    my $edge = $set->{edges};
    my $i;

    for ($i=0; $i<@$edge; $i++)
    {
        if ($inSet)
        {
            last if $n <= $$edge[$i];
            $inSet = 0;
        }
        else
        {
            return if $n <= $$edge[$i];
            $inSet = 1;
        }
    }

    return unless $inSet;

    splice @{$set->{edges}}, $i, 0, $n-1, $n;
    _cleanup($set);
}


sub min
{
    my $set = shift;

    empty   $set and return undef;
    neg_inf $set and return undef;
    $set->{edges}->[0]+1;
}


sub max
{
    my $set = shift;

    empty   $set and return undef;
    pos_inf $set and return undef;
    $set->{edges}->[-1];
}


1


__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::IntSpan

=head1 SYNOPSIS

    use Bio::GMOD::Blast::Graph::IntSpan;

    $Bio::GMOD::Blast::Graph::IntSpan::Empty_String = $string;

    $set    = new   Bio::GMOD::Blast::Graph::IntSpan $set_spec;
    $valid  = valid Bio::GMOD::Blast::Graph::IntSpan $run_list;
    copy $set $set_spec;

    $run_list   = run_list $set;
    @elements   = elements $set;

    $u_set = union      $set $set_spec;
    $i_set = intersect  $set $set_spec;
    $x_set = xor        $set $set_spec;
    $d_set = diff       $set $set_spec;
    $c_set = complement $set;

    equal       $set $set_spec;
    equivalent  $set $set_spec;
    superset    $set $set_spec;
    subset      $set $set_spec;

    $n = cardinality $set;

    empty       $set;
    finite      $set;
    neg_inf     $set;
    pos_inf     $set;
    infinite    $set;
    universal   $set;

    member      $set $n;
    insert      $set $n;
    remove      $set $n;

    $min = min  $set;
    $max = max  $set;

=head1 DESCRIPTION

Bio::GMOD::Blast::Graph::IntSpan manages sets of integers.
It is optimized for sets that have long runs of consecutive integers.
These arise, for example, in .newsrc files, which maintain lists of articles:

    alt.foo: 1-21,28,31
    alt.bar: 1-14192,14194,14196-14221

Sets are stored internally in a run-length coded form.
This provides for both compact storage and efficient computation.
In particular,
set operations can be performed directly on the encoded representation.

Bio::GMOD::Blast::Graph::IntSpan is designed to manage finite sets.
However, it can also represent some simple infinite sets, such as {x | x>n}.
This allows operations involving complements to be carried out consistently,
without having to worry about the actual value of MAXINT on your machine.

=head1 COPYRIGHT

Copyright (c) 1996 Steven McDougall.  All rights reserved.  This

Module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 NAME

Bio::GMOD::Blast::Graph::IntSpan - Manages sets of integers

=head1 REQUIRES

Perl 5.002

Exporter

=head1 EXPORTS

None

=head1 SET SPECIFICATIONS

Many of the methods take a I<set specification>.
There are four kinds of set specifications.

=head2 Empty

If a set specification is omitted, then the empty set is assumed.
Thus,

    $set = new Bio::GMOD::Blast::Graph::IntSpan;

creates a new, empty, set.  Similarly,

    copy $set;

removes all elements from $set.

=head2 Object reference

If an object reference is given, it is taken to be a
Bio::GMOD::Blast::Graph::IntSpan object.

=head2 Array reference

If an array reference is given,
then the elements of the array are taken to be the elements of the set.
The array may contain duplicate elements.
The elements of the array may be in any order.

=head2 Run list

If a string is given, it is taken to be a I<run list>.
A run list specifies a set using a syntax similar to that in .newsrc files.

A run list is a comma-separated list of I<runs>.
Each run specifies a set of consecutive integers.
The set is the union of all the runs.

Runs may be written in any of several forms.

=head2 Finite forms

=over 2

=item n

{ n }

=item a-b

{x | a<=x && x<=b}

=back

=head2 Infinite forms

=over 3

=item (-n

{x | x<=n}

=item n-)

{x | x>=n}

=item (-)

The set of all integers

=back

=head2 Empty forms

The empty set is consistently written as '' (the null string).
It is also denoted by the special form '-' (a single dash).

=head2 Restrictions

The runs in a run list must be disjoint,
and must be listed in increasing order.

Valid characters in a run list are 0-9, '(', ')', '-' and ','.
White space and underscore (_) are ignored.
Other characters are not allowed.

=head2 Examples

=over 7

=item -

{ }

=item '1'

{ 1 }

=item '1-2'

{ 1, 2 }

=item '-5--1'

{ -5, -4, -3, -2, -1 }

=item (-)

the integers

=item '(--1'

the negative integers

=item '1-3, 4, 18-21'

{ 1, 2, 3, 4, 18, 19, 20, 21 }

=back

=head1 METHODS

=head2 Creation

=over 4

=item new Bio::GMOD::Blast::Graph::IntSpan $set_spec;

Creates and returns a new set.
The initial contents of the set are given by $set_spec.

=item valid Bio::GMOD::Blast::Graph::IntSpan $run_list;

Returns true if $run_list is a valid run list.
Otherwise, returns false and leaves an error message in $@.

=item copy $set $set_spec;

Copies $set_spec into $set.
The previous contents of $set are lost.
For convenience, copy() returns $set.

=item $run_list = run_list $set

Returns a run list that represents $set.
The run list will not contain white space.
$set is not affected.

By default, the empty set is formatted as '-';
a different string may be specified in $Bio::GMOD::Blast::Graph::IntSpan::Empty_String.

=item @elements = elements $set;

Returns an array containing the elements of $set.
The elements will be sorted in numerical order.
In scalar context, returns an array reference.
$set is not affected.

=back

=head2 Set operations

=over 4

=item $u_set = union $set $set_spec;

returns the set of integers in either $set or $set_spec

=item $i_set = intersect $set $set_spec;

returns the set of integers in both $set and $set_spec

=item $x_set = xor $set $set_spec;

returns the set of integers in $set or $set_spec, but not both

=item $d_set = diff $set $set_spec;

returns the set of integers in $set but not in $set_spec

=item $c_set = complement $set;

returns the complement of $set.

=back

For all set operations, a new Bio::GMOD::Blast::Graph::IntSpan object is created and returned.
The operands are not affected.

=head2 Comparison

=over 4

=item equal $set $set_spec;

Returns true iff $set and $set_spec contain the same elements.

=item equivalent $set $set_spec;

Returns true iff $set and $set_spec contain the same number of elements.
All infinite sets are equivalent.

=item superset $set $set_spec

Returns true iff $set is a superset of $set_spec.

=item subset $set $set_spec

Returns true iff $set is a subset of $set_spec.

=back

=head2 Cardinality

=over 4

=item $n = cardinality $set

Returns the number of elements in $set.
Returns -1 for infinite sets.

=item empty $set;

Returns true iff $set is empty.

=item finite $set

Returns true iff $set is finite.

=item neg_inf $set

Returns true iff $set contains {x | x<n} for some n.

=item pos_inf $set

Returns true iff $set contains {x | x>n} for some n.

=item infinite $set

Returns true iff $set is infinite.

=item universal $set

Returns true iff $set contains all integers.

=back

=head2 Membership

=over 4

=item member $set $n

Returns true iff the integer $n is a member of $set.

=item insert $set $n

Inserts the integer $n into $set.
Does nothing if $n is already a member of $set.

=item remove $set $n

Removes the integer $n from $set.
Does nothing if $n is not a member of $set.

=back

=head2 Extrema

=over 4

=item min $set

Returns the smallest element of $set,
or undef if there is none.

=item max $set

Returns the largest element of $set,
or undef if there is none.

=back

=head1 CLASS VARIABLES

=over 4

=item $Bio::GMOD::Blast::Graph::IntSpan::Empty_String

$Bio::GMOD::Blast::Graph::IntSpan::Empty_String contains the string that is returned when
run_list() is called on the empty set.
$Empty_String is initially '-';
alternatively, it may be set to ''.
Other values should be avoided,
to ensure that run_list() always returns a valid run list.

run_list() accesses $Empty_String through a reference
stored in $set->{empty_string}.
Subclasses that wish to override the value of $Empty_String can
reassign this reference.

=back

=head1 DIAGNOSTICS

Any method (except valid()) will die() if it is passed an invalid run list.
Possible messages are:

=over 15

=item Bad syntax

$run_list has bad syntax

=item Bad order

$run_list has overlapping runs or runs that are out of order.

=back

elements $set will die() if $set is infinite.

elements $set can generate an "Out of memory!"
message on sufficiently large finite sets.

=head1 NOTES

=head2 Traps

Beware of forms like

    union $set [1..5];

This passes an element of @set to union,
which is probably not what you want.
To force interpretation of $set and [1..5] as separate arguments,
use forms like

    union $set +[1..5];

or

    $set->union([1..5]);

=head2 Error handling

There are two common approaches to error handling:
exceptions and return codes.
There seems to be some religion on the topic,
so Bio::GMOD::Blast::Graph::IntSpan provides support for both.

To catch exceptions, protect method calls with an eval:

    $run_list = <STDIN>;
    eval { $set = new Bio::GMOD::Blast::Graph::IntSpan $run_list };
    $@ and print "$@: try again\n";

To check return codes, use an appropriate method call to validate arguments:

    $run_list = <STDIN>;
    if (valid Bio::GMOD::Blast::Graph::IntSpan $run_list)
       { $set = new Bio::GMOD::Blast::Graph::IntSpan $run_list }
    else
       { print "$@ try again\n" }

Similarly, use finite() to protect calls to elements():

    finite $set and @elements = elements $set;

Calling elements() on a large, finite set can generate an "Out of
memory!" message, which cannot be trapped.
Applications that must retain control after an error can use intersect() to
protect calls to elements():

    @elements = elements { intersect $set "-1_000_000 - 1_000_000" };

or check the size of $set first:

    finite $set and cardinality $set < 2_000_000 and @elements = elements $set;

=head2 Limitations

Although Bio::GMOD::Blast::Graph::IntSpan can represent some infinite sets,
it does I<not> perform infinite-precision arithmetic.
Therefore,
finite elements are restricted to the range of integers on your machine.

=head2 Roots

The sets implemented here are based on Macintosh data structures called
"regions".
See Inside Macintosh for more information.

=head1 AUTHOR

Steven McDougall <swm@cric.com>

=head1 COPYRIGHT

Copyright (c) 1996 Steven McDougall.
All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

Shuai Weng <shuai@genome.stanford.edu>

=item *

John Slenk <jces@genome.stanford.edu>

=item *

Robert Buels <rmb32@cornell.edu>

=item *

Jonathan "Duke" Leto <jonathan@leto.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by The Board of Trustees of Leland Stanford Junior University.

This is free software, licensed under:

  The Artistic License 1.0

=cut

