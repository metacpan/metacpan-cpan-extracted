package Algorithm::Loops;
# The command "perldoc Algorithm::Loops" will show you the
# documentation for this module.  You can also seach for
# "=head" below to read the unformatted documentation.

use strict;
BEGIN {     # Some still don't have warnings.pm:
    if(  eval { require warnings }  ) {
        warnings->import();
        if(  eval { require warnings::register; }  ) {
            warnings::register->import();
        }
    } else {
        # $^W= 1;
    }
}

require Exporter;
use vars qw( $VERSION @EXPORT_OK );
BEGIN {
    $VERSION= 1.032_00;
    @EXPORT_OK= qw(
        Filter
        MapCar MapCarE MapCarU MapCarMin
        NestedLoops
        NextPermute NextPermuteNum
    );
    { my @nowarn= ( *import, *isa ) }
    *import= \&Exporter::import;
    *isa= \&UNIVERSAL::isa;
}


sub _Type
{
    my( $val )= @_;
    return  ! defined($val) ? "undef" : ref($val) || $val;
}


sub _Croak
{
    my $depth= 1;
    my $sub;
    do {
        ( $sub= (caller($depth++))[3] ) =~ s/.*:://;
    } while(  $sub =~ /^_/  );
    if(   eval { require Carp; 1; }
      &&  defined &Carp::croak  ) {
        unshift @_, "$sub: ";
        goto &Carp::croak;
    }
    die "$sub: ", @_, ".\n";
}


sub Filter(&@)
{
    my( $code, @vals )= @_;
    isa($code,"CODE")  or  _Croak(
        "No code reference given" );
    # local( $_ ); # Done by the loop.
    for(  @vals  ) {
        $code->();
    }
    wantarray ? @vals : join "", @vals;
}


sub MapCarE(&@)
{
    my $sub= shift(@_);
    isa($sub,"CODE")  or  _Croak(
        "No code reference given" );
    my $size= -1;
    for my $av (  @_  ) {
        isa( $av, "ARRAY" )  or  _Croak(
            "Not an array reference (", _Type($av), ")" );
        if(  $size < 0  ) {
            $size= @$av;
        } elsif(  $size != @$av  ) {
            _Croak( "Arrays with different sizes",
                " ($size and ", 0+@$av, ")" );
        }
    }
    my @ret;
    for(  my $i= 0;  $i < $size;  $i++  ) {
        push @ret, &$sub( map { $_->[$i] } @_ );
    }
    return wantarray ? @ret : \@ret;
}


sub MapCarMin(&@)
{
    my $sub= shift(@_);
    isa($sub,"CODE")  or  _Croak(
        "No code reference given" );
    my $min= -1;
    for my $av (  @_  ) {
        isa( $av, "ARRAY" )  or  _Croak(
            "Not an array reference (", _Type($av), ")" );
        $min= @$av   if  $min < 0  ||  @$av < $min;
    }
    my @ret;
    for(  my $i= 0;  $i < $min;  $i++  ) {
        push @ret, &$sub( map { $_->[$i] } @_ );
    }
    return wantarray ? @ret : \@ret;
}


sub MapCarU(&@)
{
    my $sub= shift(@_);
    isa($sub,"CODE")  or  _Croak(
        "No code reference given" );
    my $max= 0;
    for my $av (  @_  ) {
        isa( $av, "ARRAY" )  or  _Croak(
            "Not an array reference (", _Type($av), ")" );
        $max= @$av   if  $max < @$av;
    }
    my @ret;
    for(  my $i= 0;  $i < $max;  $i++  ) {
        push @ret, &$sub( map { $_->[$i] } @_ );
    }
    return wantarray ? @ret : \@ret;
}


sub MapCar(&@)
{
    my $sub= shift(@_);
    isa($sub,"CODE")  or  _Croak(
        "No code reference given" );
    my $max= 0;
    for my $av (  @_  ) {
        isa( $av, "ARRAY" )  or  _Croak(
            "Not an array reference (", _Type($av), ")" );
        $max= @$av   if  $max < @$av;
    }
    my @ret;
    for(  my $i= 0;  $i < $max;  $i++  ) {
        push @ret, &$sub( map { $i < @$_ ? $_->[$i] : () } @_ );
        # If we assumed Want.pm, we could consider an early return.
    }
    return wantarray ? @ret : \@ret;
}


sub NextPermute(\@)
{
    my( $vals )= @_;
    my $last= $#{$vals};
    return !1   if  $last < 1;
    # Find last item not in reverse-sorted order:
    my $i= $last-1;
    $i--   while  0 <= $i  &&  $vals->[$i] ge $vals->[$i+1];
    # If complete reverse sort, we are done!
    if(  -1 == $i  ) {
        # Reset to starting/sorted order:
        @$vals= reverse @$vals;
        return !1;
    }
    # Re-sort the reversely-sorted tail of the list:
    @{$vals}[$i+1..$last]= reverse @{$vals}[$i+1..$last]
        if  $vals->[$i+1] gt $vals->[$last];
    # Find next item that will make us "greater":
    my $j= $i+1;
    $j++  while  $vals->[$i] ge $vals->[$j];
    # Swap:
    @{$vals}[$i,$j]= @{$vals}[$j,$i];
    return 1;
}


sub NextPermuteNum(\@)
{
    my( $vals )= @_;
    my $last= $#{$vals};
    return !1   if  $last < 1;
    # Find last item not in reverse-sorted order:
    my $i= $last-1;
    $i--   while  0 <= $i  &&  $vals->[$i+1] <= $vals->[$i];
    # If complete reverse sort, we are done!
    if(  -1 == $i  ) {
        # Reset to starting/sorted order:
        @$vals= reverse @$vals;
        return !1;
    }
    # Re-sort the reversely-sorted tail of the list:
    @{$vals}[$i+1..$last]= reverse @{$vals}[$i+1..$last]
        if  $vals->[$last] < $vals->[$i+1];
    # Find next item that will make us "greater":
    my $j= $i+1;
    $j++  while  $vals->[$j] <= $vals->[$i];
    # Swap:
    @{$vals}[$i,$j]= @{$vals}[$j,$i];
    return 1;
}


sub _NL_Args
{
    my $loops= shift(@_);
    isa( $loops, "ARRAY" )  or  _Croak(
        "First argument must be an array reference,",
        " not ", _Type($loops) );

    my $n= 1;
    for my $loop (  @$loops  ) {
        if(  ! isa( $loop, "ARRAY" )
         &&  ! isa( $loop, "CODE" )  ) {
            _Croak( "Invalid type for loop $n specification (",
                _Type($loop), ")" );
        }
        $n++;
    }

    my( $opts )= @_;
    if(  isa( $opts, "HASH" )  ) {
        shift @_;
    } else {
        $opts= {};
    }

    my $code;
    if(  0 == @_  ) {
        $code= 0;
    } elsif(  1 != @_  ) {
        _Croak( "Too many arguments" );
    } else {
        $code= pop @_;
        isa($code,"CODE")  or  _Croak(
            "Expected CODE reference not ", _Type($code) );
    }

    my $when= delete($opts->{OnlyWhen})
        ||  sub { @_ == @$loops };
    if(  keys %$opts  ) {
        _Croak( "Unrecognized option(s): ",
            join ' ', keys %$opts );
    }

    return( $loops, $code, $when );
}

sub _NL_Iter
{
    my( $loops, $code, $when )= @_;

    my @list;
    my $i= -1;
    my @idx;
    my @vals= @$loops;

    return  sub { return }
        if  ! @vals;

    return  sub {
        while( 1 ) {
            # Prepare to append one more value:
            if(  $i < $#$loops  ) {
                $idx[++$i]= -1;
                if(  isa( $loops->[$i], 'CODE' )  ) {
                    local( $_ )= $list[-1];
                    $vals[$i]= $loops->[$i]->(@list);
                }
            }
            ## return   if  $i < 0;
            # Increment furthest value, chopping if done there:
            while(  @{$vals[$i]} <= ++$idx[$i]  ) {
                pop @list;
                return   if  --$i < 0;
            }
            $list[$i]= $vals[$i][$idx[$i]];
            my $act;
            $act= !ref($when) ? $when : do {
                local( $_ )= $list[-1];
                $when->(@list);
            };
            return @list   if  $act;
        }
    };

}

sub NestedLoops
{
    my( $loops, $code, $when )= _NL_Args( @_ );

    my $iter= _NL_Iter( $loops, $code, $when );

    if(  ! $code  ) {
        if(  ! defined wantarray  ) {
            _Croak( "Useless in void context",
                " when no code given" );
        }
        return $iter;
    }

    my @ret;
    my @list;
    while(  @list= $iter->()   ) {
        @list= $code->( @list );
        if(  wantarray  ) {
            push @ret, @list;
        } else {
            $ret[0] += @list;
        }
    }
    return wantarray ? @ret : ( $ret[0] || 0 );
}


"Filtering should not be straining";
__END__

=head1 NAME

Algorithm::Loops - Looping constructs:
NestedLoops, MapCar*, Filter, and NextPermute*

=head1 SYNOPSYS

    use Algorithm::Loops qw(
        Filter
        MapCar MapCarU MapCarE MapCarMin
        NextPermute NextPermuteNum
        NestedLoops
    );

    my @copy= Filter {tr/A-Z'.,"()/a-z/d} @list;
    my $string= Filter {s/\s*$/ /} @lines;

    my @transposed= MapCarU {[@_]} @matrix;

    my @list= sort getList();
    do {
        usePermutation( @list );
    } while(  NextPermute( @list )  );

    my $len= @ARGV ? $ARGV[0] : 3;
    my @list= NestedLoops(
        [  ( [ 1..$len ] ) x $len  ],
        sub { "@_" },
    );

If you want working sample code to try, see below in the section specific
to the function(s) you want to try.  The above samples only give a
I<feel> for how the functions are typically used.

=head1 FUNCTIONS

Algorithm::Loops provides the functions listed below.  By default, no
functions are exported into your namespace (package / symbol table) in
order to encourage you to list any functions that you use in the C<use
Algorithm::Loops> statement so that whoever ends up maintaining your code
can figure out which module you got these functions from.

=over 4

=item Filter

Similar to C<map> but designed for use with s/// and other reflexive
operations.  Returns a modified copy of a list.

=item MapCar, MapCarU, MapCarE, and MapCarMin

All similar to C<map> but loop over multiple lists at the same time.

=item NextPermute and NextPermuteNum

Efficiently find all (unique) permutations of a list, even if it contains
duplicate values.

=item NestedLoops

Simulate C<foreach> loops nested arbitrarily deep.

=back

=head2 Filter(\&@)

=head3 Overview

Produces a modified copy of a list of values.  Ideal for use with s///.
If you find yourself trying to use s/// or tr/// inside of map (or grep),
then you should probably use Filter instead.

For example:

    use Algorithm::Loops qw( Filter );

    @copy = Filter { s/\\(.)/$1/g } @list;
    $text = Filter { s/^\s+// } @lines;

The same process can be accomplished using a careful and more complex
invocation of map, grep, or foreach.  However, many incorrect ways to
attempt this seem rather seductively appropriate so this function helps
to discourage such (rather common) mistakes.

=head3 Usage

Filter has a prototype specification of (\&@).

This means that it demands that the first argument that you pass to it be
a CODE reference.  After that you can pass a list of as many or as few
values as you like.

For each value in the passed-in list, a copy of the value is placed into
$_ and then your CODE reference is called.  Your subroutine is expected
to modify $_ and this modified value is then placed into the list of
values to be returned by Filter.

If used in a scalar context, Filter returns a single string that is the
result of:

    $string= join "", @results;

Note that no arguments are passed to your subroutine (so don't bother
with @_) and any value C<return>ed by your subroutine is ignored.

Filter's prototype also means that you can use the "map BLOCK"-like
syntax by leaving off the C<sub> keyword if you also leave off the
comma after the block that defines your anonymous subroutine:

        my @copy= Filter sub {s/\s/_/g}, @list;
  # becomes:            v^^^       v   ^
        my @copy= Filter {s/\s/_/g} @list;

Most of our examples will use this shorter syntax.

Note also that by importing Filter via the C<use> statement:

    use Algorithm::Loops qw( Filter );

it gets declared before the rest of our code is compiled so we don't have
to use parentheses when calling it.  We I<can> if we want to, however:

        my @copy= Filter( sub {s/\s/_/g}, @list );

=head3 Note on "Function BLOCK LIST" bugs

Note that in at least some versions of Perl, support for the "Filter
BLOCK ..." syntax is somewhat fragile.  For example:

    ... Filter( {y/aeiou/UAEIO/} @list );

may give you this error:

    Array found where operator expected

which can be fixed by dropping the parentheses:

    ... Filter {y/aeiou/UAEIO/} @list;

So if you need or want to use parentheses when calling Filter, it is best
to also include the C<sub> keyword and the comma:

    #         v <--------- These ---------> v
    ... Filter( sub {y/aeiou/UAEIO/}, @list );
    # require   ^^^ <--- these ---> ^ (sometimes)

so your code will be portable to more versions of Perl.

=head3 Examples

Good code ignores "invisible" characters.  So
instead of just chomp()ing, consider removing
all trailing whitespace:

    my @lines= Filter { s/\s+$// } <IN>;

or

    my $line= Filter { s/\s+$// } scalar <IN>;

[ Note that Filter can be used in a scalar
context but always puts its arguments in a
list context.  So we need to use C<scalar> or
something similar if we want to read only one
line at a time from C<IN> above. ]

Want to sort strings that contain mixtures of
letters and natural numbers (non-negative
integers) both alphabetically and numerically
at the same time?  This simple way to do a
"natural" sort is also one of the fastest.
Great for sorting version numbers, file names,
etc.:

    my @sorted= Filter {
        s#\d{2}(\d+)#\1#g
    } sort Filter {
        s#(\d+)# sprintf "%02d%s", length($1), $1 #g
    } @data;

[ Note that at least some versions of Perl have a bug that breaks C<sort>
if you write C<sub {> as part of building the list of items to be sorted
but you don't provide a comparison routine.  This bug means we can't
write the previous code as:

    my @sorted= Filter {
        s#\d{2}(\d+)#\1#g
    } sort Filter sub {
        s#(\d+)# sprintf "%02d%s", length($1), $1 #g
    }, @data;

because it will produce the following error:

    Undefined subroutine in sort

in some versions of Perl.  Some versions of Perl may even require you
to write it like this:

    my @sorted= Filter {
        s#\d{2}(\d+)#\1#g
    } sort &Filter( sub {
        s#(\d+)# sprintf "%02d%s", length($1), $1 #g
    }, @data );

Which is how I wrote it in ex/NaturalSort.plx. ]

Need to sort names?  Then you'll probably want to ignore letter case and
certain punctuation marks while still preserving both:

    my @compare= Filter {tr/A-Z'.,"()/a-z/d} @names;
    my @indices= sort {$compare[$a] cmp $compare[$b]} 0..$#names;
    @names= @names[@indices];

You can also roll your own simple HTML templating:

    print Filter {
        s/%(\w*)%/expand($1)/g
    }   $cgi->...,
        ...
        $cgi->...;

Note that it also also works correctly if you change how you output your
    HTML and accidentally switch from list to scalar context:

    my $html= '';
    ...
    $html .= Filter {
        s/%(\w*)%/expand($1)/g
    }   $cgi->...,
        ...
        $cgi->...;

=head3 Motivation

A reasonable use of map is:

    @copy= map {lc} @list;

which sets @copy to be a copy of @list but with all of the elements
converted to lower case.  But it is too easy to think that that could
also be done like this:

    @copy= map {tr/A-Z/a-z/} @list;  # Wrong

The reason why these aren't the same is similar to why we write:

    $str= lc $str;

not

    lc $str;  # Useless use of 'lc' in void context

and we write:

    $str =~ tr/A-Z/a-z/;

not

    $new= ( $old =~ tr/A-Z/a-z/ );  # Wrong

That is, many things (such as lc) return a modified copy of what they are
given, but a few things (such as tr///, s///, chop, and chomp) modify
what they are given I<in-place>.

This distinction is so common that we have several ways of switching
between the two forms.  For example:

        $two= $one + $other;
  # vs.
        $one += $other;

or

        $two= substr($one,0,4);
  # vs.
        substr($one,4)= '';

I've even heard talk of adding some syntax to Perl to allow you to make
things like C<lc> become reflexive, similar to how += is the reflexive
form of +.

But while many non-reflexive Perl operations have reflexive counterparts,
there are a few reflexive Perl operations that don't really have
non-reflexive counterparts: s///, tr///, chop, chomp.

You can write:

        my $line= <STDIN>;
        chomp( $line );
  # or
        chomp( my $line= <STDIN> );

but it somehow seems more natural to write:

        my $line= chomp( <STDIN> );  # Wrong

So, if you dislike hiding the variable declaration inside of a function
call or dislike using two lines and repeating the variable name, then you
can now use:

        my $line= Filter {chomp} ''.<STDIN>;

[ I used C<''.> to provide a scalar context so that only one line is read
from STDIN. ]

Or, for a better example, consider these valid alternatives:

        my @lines= <STDIN>;
        chomp( @lines );
  # or
        chomp( my @lines= <STDIN> );

And what you might expect to work (but doesn't):

        my @lines= chomp( <STDIN> );  # Wrong

And what you can now use instead:

        my @lines= Filter {chomp} <STDIN>;

Here are some examples of ways to use map/grep correctly to get Filter's
functionality:

        Filter { CODE } @list
  # vs
        join "", map { local($_)= $_; CODE; $_ } @list
  # vs
        join "", grep { CODE; 1 } @{ [@list] }

Not horribly complex, but enough that it is very easy to forget part of
the solution, making for easy mistakes.  I see mistakes related to this
quite frequently and have made such mistakes myself several times.

Some (including me) would even consider the last form above to be an
abuse (or misuse) of C<grep>.

You can also use C<for>/C<foreach> to get the same results as Filter:

        my @copy= Filter { CODE } @list;
  # vs
        STATEMENT  foreach  my @copy= @list;
  # or
        my @copy= @list;
        foreach(  @copy  ) {
            CODE;
        }

=head2 MapCar*

=over 4

=item MapCar(\&@)

=item MapCarU(\&@)

=item MapCarE(\&@)

=item MapCarMin(\&@)

=back

=head3 Usage

The MapCar* functions are all like C<map> except they each loop over more
than one list at the same time.

[ The name "mapcar" comes from LISP. As I understand it, 'car' comes from
the acronym for a register of the processor where LISP was first
developed, one of two registers used to implement lists in LISP.  I only
mention this so you won't waste too much time trying to figure out what
"mapcar" is supposed to mean. ]

The MapCar* functions all have prototype specifications of (\&@).

This means that they demand that the first argument that you pass be a
CODE reference.  After that you should pass zero or more array references.

Your subroutine is called (in a list context) and is passed the first
element of each of the arrays whose references you passed in (in the
corresponding order).  Any value(s) returned by your subroutine are
pushed onto an array that will eventually be returned by MapCar*.

Next your subroutine is called and is passed the B<second> element of
each of the arrays and any value(s) returned are pushed onto the results
array.  Then the process is repeated with the B<third> elements.

This continues until your subroutine has been passed all elements [except
for some cases with MapCarMin()].  If the longest array whose reference
you passed to MapCar() or MapCarU() contained $N elements, then your
subroutine would get called $N times.

Finally, the MapCar* function returns the accumulated list of values.  If
called in a scalar context, the MapCar* function returns a reference to
an array containing these values.

[ I feel that having C<map> return a count when called in a scalar
context is quite simply a mistake that was made when this feature was
copied from C<grep> without properly considering the consequences.
Although it does make for the impressive and very impractical golf
solution of:

    $sum=map{(1)x$_}@ints;

for adding up a list of natural numbers. q-: ]

=head3 Differences

The different MapCar* functions are only different in how they deal with
being pqssed arrays that are not all of the same size.

If not all of your arrays are the same length, then MapCarU() will pass
in C<undef> for any values corresponding to arrays that didn't have
enough values.  The "U" in "MapCarU" stands for "undef".

In contrast, MapCar() will simply leave out values for short arrays (just
like I left the "U" out of its name).

MapCarE() will croak without ever calling your subroutine unless all of
the arrays are the same length.  It considers it an Error if your arrays
are not of Equal length and so throws an Exception.

Finally, MapCarMin() only calls your subroutine as many times as there
are elements in the B<shortest> array.

In other words,

    MapCarU \&MySub, [1,undef,3], [4,5], [6,7,8]

returns

    ( MySub( 1, 4, 6 ),
      MySub( undef, 5, 7 ),
      MySub( 3, undef, 8 ),
    )

While

    MapCar \&MySub, [1,undef,3], [4,5], [6,7,8]

returns

    ( MySub( 1, 4, 6 ),
      MySub( undef, 5, 7 ),
      MySub( 3, 8 ),
    )

While

    MapCarMin \&MySub, [1,undef,3], [4,5], [6,7,8]

returns

    ( MySub( 1, 4, 6 ),
      MySub( undef, 5, 7 ),
    )

And

    MapCarE \&MySub, [1,undef,3], [4,5], [6,7,8]

dies with

    MapCarE: Arrays with different sizes (3 and 2)

=head3 Examples

Transposing a two-dimensional matrix:

    my @transposed= MapCarE {[@_]} @matrix;

or, using references to the matrices and allowing for different row
lengths:

    my $transposed= MapCarU {[@_]} @$matrix;

Formatting a date-time:

    my $dateTime= join '', MapCarE {
        sprintf "%02d%s", pop()+pop(), pop()
    } [ (localtime)[5,4,3,2,1,0] ],
      [ 1900, 1, (0)x4 ],
      [ '// ::' =~ /./g, '' ];

Same thing but not worrying about warnings for using undefined values:

    my $dateTime= join '', MapCarU {
        sprintf "%02d%s", pop()+pop(), pop()
    } [ (localtime)[5,4,3,2,1,0] ],
      [ 1900, 1 ],
      [ '// ::' =~ /./g ];

Combine with C<map> to do matrix multiplication:

    my @X= (
        [  1,  3 ],
        [  4, -1 ],
        [ -2,  2 ],
    );
    my @Y= (
        [ -6,  2, 5, -3 ],
        [  4, -1, 3,  1 ],
    );
    my @prod= map {
        my $row= $_;
        [
            map {
                my $sum= 0;
                $sum += $_   for  MapCarE {
                    pop() * pop();
                } $row, $_;
                $sum;
            } MapCarE {\@_} @Y;
        ]
    } @X;

Report the top winners:

    MapCarMin {
        print pop(), " place goes to ", pop(), ".\n";
    } [qw( First Second Third Fourth )],
      \@winners;

Same thing (scalar context):

    my $report= MapCarMin {
        pop(), " place goes to ", pop(), ".\n";
    } [qw( First Second Third Fourth )],
      \@winners;

Displaying a duration:

    my $ran= time() - $^T;
    my $desc= join ', ', reverse MapCar {
        my( $unit, $mult )= @_;
        my $part= $ran;
        if(  $mult  ) {
            $part %= $mult;
            $ran= int( $ran / $mult );
        }
        $unit .= 's'   if  1 != $part;
        $part ? "$part $unit" : ();
    } [ qw( sec min hour day week year ) ],
      [     60, 60, 24,   7,  52 ];
    $desc ||= '< 1 sec';
    print "Script ran for $desc.\n";

=head2 NextPermute*

=over 4

=item NextPermute(\@)

=item NextPermuteNum(\@)

=back

=head3 Introduction

If you have a list of values, then a "permutation" of that list is the
same values but not (necessarily) in the same order.

NextPermute() and NextPermuteNum() each provide very efficient ways of
finding all of the (unique) permutations of a list (even if the list
contains duplicate values).

=head3 Usage

Each time you pass an array to a NextPermute* routine, the elements of
the array are shifted around to give you a new permutation.  If the
elements of the array are in reverse-sorted order, then the array is
reversed (in-place, making it sorted) and a false value is returned.
Otherwise a true value is returned.

So, if you start out with a sorted array, then you can use that as your
first permutation and then call NextPermute* to get the next permutation
to use, until NextPermute* returns a false value (at which point your
array has been returned to its original, sorted order).

So you would use NextPermute() like this:

    my @list= sort GetValuesSomehow();
    do {
        DoSomethingWithPermutation( @list );
    } while(  NextPermute( @list )  );

or, if your list only contains numbers, you could use NextPermuteNum()
like this:

    my @list= sort {$a<=>$b} GetNumbersSomehow();
    do {
        DoSomethingWithPermutation( @list );
    } while(  NextPermuteNum( @list )  );

=head3 Notes

The NextPermute* functions each have a prototype specifications of (\@).
This means that they demand that you pass them a single array which they
will receive a reference to.

If you instead have a reference to an array, you'll need to use C<@{ }>
when calling a NextPermute* routine:

    } while(  NextPermute( @{$av} )  );

(or use one of several other techniques which I will leave the
consideration of as an "exercise" for the more advanced readers
of this manual).

Note that this particular use of a function prototype is one that I am
not completely comfortable with.  I am tempted to remove the prototype
and force you to create the reference yourself before/when calling these
functions:

    } while(  NextPermute( \@list )  );   # Wrong

because

=over 4

=item

It makes it obvious to the reader of the code that a reference to the
array is what is being used by the routine.  This makes the reader more
likely to realize/suspect that the array is being modified in-place.

=item

Many/most uses of Perl function prototypes are more trouble than they are
worth.  This makes using even the less problematic cases often not a good
idea.

=back

However, I have decided to use a prototype here because:

=item

Several other functions from this module already use prototypes to good
advantage, enough advantage that I'd hate to lose it.

=item

Removing the prototype would require the addition of argument-checking
code that would get run each time a permutation is computed, somewhat
slowing down what is currently quite fast.

=item

The compile-time checking provided by the prototype can save develop time
over a run-time check by pointing out mistakes sooner.

=back

=head3 Features

There are several features to NextPermute* that can be advantages over
other methods of finding permutations.

=over 4

=item Iterators - No huge memory requirements

Some permutation generators return the full set of all permutations (as a
huge list of lists).  Your input list doesn't have to be very big at all
for the resulting set to be too large to fit in your available memory.

So the NextPermute* routines return each permutation, one at a time, so
you can process them all (eventually) without the need for lots of memory.

A programming object that gives you access to things one-at-a-time is
called an "iterator".

=item No context - Hardly any memory required

The NextPermute* routines require no extra memory in the way of context
or lists to keep track of while constructing the permutations.

Each call to a NextPermute* routine shuffles the items in the list
B<in-place>, never making copies of more than a couple of values at a
time (when it swaps them).

[ This also means you don't have to bother with creating an object to do
the iterating. ]

=item Handles duplicate values

Unlike most permutation generators you are likely to find in Perl, both
NextPermute* routines correctly deal with lists containing duplicate
values.

The following example:

    my @list= ( 3, 3, 3, 3 );
    do {
        print "@list\n";
    } while(  NextPermute( @list )  );

will only print the one line, "3 3 3 3\n", because NextPermute() quickly
determines that there are no other unique permutations.

Try out the demonstration program included in the "ex" subdirectory of
the source distribution of this module:

    > perl ex/Permute.plx tool
    1: loot
    2: loto
    3: ltoo
    4: olot
    5: olto
    6: oolt
    7: ootl
    8: otlo
    9: otol
    10: tloo
    11: tolo
    12: tool

Most permutation generators would have listed each of those twice
(thinking that swapping an "o" with another "o" made a new permutation). 
Or consider:

    > perl ex/Permute.plx noon
    1: nnoo
    2: nono
    3: noon
    4: onno
    5: onon
    6: oonn

Most permutation generators would have listed each of those B<four>
times.

Note that using a hash to eliminate duplicates would require a hash table
big enough to hold all of the (unique) permutations and so would defeat
the purpose of iterating.  NextPermute* does not use a hash to avoid
duplicates.

=item Generated in sorted order

If you were to run code like:


    my @list= sort GetValuesSomehow();
    do {
        print join('',@lista, $/);
    } while(  NextPermute( @list )  );

then the lines output would be sorted (assuming none of the values in
@list contained newlines.  This may be convenient in some corcumstances.

That is, the permutations are generated in sorted order.  The first
permutations have the lowest values at the front of the list.  As you
iterate, larger values are shifted to be in front of smaller values,
starting at the back of the list.  So the value at the very front of the
list will change the fewest times (once for each unique value in the
list), while the value at the very end of the list changes between most
iterations.

=item Fast

If you don't have to deal with duplicate values, then Algorithm::Permute
provides some routines written in C (which makes them harder to install
but about twice as fast to run as the NextPermute* routines) that you can
use.

Algorithm::Permute also includes some fun benchmarks comparing different
Perl ways of finding permutations.  I found NextPermute to be faster than
any of the routines included in those benchmarks except for the ones
written in C that I mentioned above.  Though none of the benchmarked
routines deal with duplicates.

=back

=head3 Notes

Note that NextPermute() considers two values (say $x and $y) to be
duplicates if (and only if) C<$x eq $y>.

NextPermuteNum() considers $x and $y to be duplicates if C<$x == $y>.

If you have a list of floating point numbers to permute, you might want
to use NextPermute() [instead of NextPermuteNum()] as it is easy to end
up with $x and $y that both display the same (say as "0.1") but are
B<just barely> not equal numerically.  Thus $x and $y would I<look> equal
and it would be true that C<$x eq $y> but also true that C<$x != $y>.  So
NextPermute() would consider them to be duplicates but NextPermuteNum()
would not.

For example, $x could be slightly more than 1/10, likely about
0.1000000000000000056, while $y is slightly more at about
0.0999999999999999917 (both of which will be displayed as "0.1" by Perl
and be considered C<eq> (on most platforms):

    > perl -w -Mstrict
    my $x= 0.1000000000000000056;
    my $y= 0.0999999999999999917;
    print "x=$x\ny=$y\n";
    print "are eq\n"   if  $x eq $y;
    print "are ==\n"   if  $x == $y;
    print "are !=\n"   if  $x != $y;
    <EOF>
    x=0.1
    y=0.1
    are eq
    are !=

=head2 NestedLoops

=head3 Introduction

Makes it easy to simulate loops nested to an arbitrary depth.

It is easy to write code like:

    for my $a (  0..$N  ) {
     for my $b (  $a+1..$N  ) {
      for my $c (  $b+1..$N  ) {
          Stuff( $a, $b, $c );
      }
     }
    }

But what if you want the user to tell you how many loops to nest
together?  The above code can be replaced with:

    use Algorithm::Loops qw( NestedLoops );

    my $depth= 3;
    NestedLoops(
        [   [ 0..$N ],
            ( sub { [$_+1..$N] } ) x ($depth-1),
        ],
        \&Stuff,
    );

Then you only have to change $depth to 4 to get the same results as:

    for my $a (  0..$N  ) {
     for my $b (  $a+1..$N  ) {
      for my $c (  $b+1..$N  ) {
       for my $d (  $c+1..$N  ) {
          Stuff( $a, $b, $c, $d );
       }
      }
     }
    }

=head3 Usage

The first argument to NestedLoops() is required and must be a reference
to an array.  Each element of the array specifies the values for a single
loop to iterate over.  The first element describes the outermost loop. 
The last element describes the innermost loop.

If the next argument to NestedLoops is a hash reference, then it
specifies more advanced options.  This argument can be omitted if you
don't need it.

If the last argument to NestedLoops is a code reference, then it will be
run inside the simulated loops.  If you don't pass in this code
reference, then NestedLoops returns an iterator (described later) so you
can iterate without the restrictions of using a call-back.

So the possible ways to call NestedLoops are:

    $iter= NestedLoops( \@Loops );
    $iter= NestedLoops( \@Loops, \%Opts );
    ...    NestedLoops( \@Loops, \%Opts, \&Code );
    ...    NestedLoops( \@Loops,         \&Code );

The "..."s above show that, when the final code reference is provided,
NestedLoops can return a few different types of information.

In a void context, NestedLoops simply iterates and calls the provided
code, discarding any values it returns.  (Calling NestedLoops in a void
context without passing a final code reference is a fatal error.)

In a list context, NestedLoops C<push>es the values returned by each call
to \&Code onto an array and then returns (copies of the values from) that
array.

In a scalar contetx, NestedLoops keeps a running total of the number of
values returned by each call to \&Code and then returns this total.  The
value is the same as if you had called NestedLoops in a list context and
counted the number of values returned (except for using less memory).

Note that \&Code is called in a list context no matter what context
NestedLoops was called in (in the current implementation).

In summary:

    NestedLoops( \@loops, \%opts, \&code );
    $count= NestedLoops( \@loops, \%opts, \&code );
    @results= NestedLoops( \@loops, \%opts, \&code );

=head4 \@Loops

Each element of @Loops can be

=over 4

=item an array refernce

which means the loop will iterate over the elements of that array,

=item a code refernce

to a subroutine that will return a reference to the array to loop over.

=back

You don't have to use a reference to a named array.  You can, of course,
construct a reference to an anonymous array using C<[...]>, as shown in
most of the examples.  You can also use any other type of expression that
rerurns an array reference.

=head4 \%Opts

If %Opts is passed in, then it should only zero or more of the following
keys.  How NestedLoops interprets the values associated with each key are
described below.

=over 4

=item OnlyWhen => $Boolean

=item OnlyWhen => \&Test

Value must either be a Boolean value or a reference to a subroutine that
will return a Boolean value.

Specifying a true value is the same as specifying a routine that always
returns a true value.  Specifying a false value gives you the default
behavior (as if you did not include the OnlyWhen key at all).

If it is a code reference, then it is called each time a new item is
selected by any of the loops.  The list of selected items is passed in.

The Boolean value returned says whether to use the list of selected
values.  That is, a true value causes either \&Code to be called (if
specified) or the list to be returned by the iterator (if \&Code was not
specified).

If this key does not exist (or is specified with a false value), then a
default subroutine is used, like:

    sub { return @_ == @Loops }

That is, only complete lists are used (by default).  So:

    my @list= NestedLoops(
        [  ( [ 1..3 ] ) x 3  ],
        {  OnlyWhen => 0  },
        sub { "@_" },
    );

is similar to:

    my @list= qw/ 111 112 113 121 122 123 131 132 133 211 212 ... /;

while

    my @list= NestedLoops(
        [  ( [ 1..3 ] ) x 3  ],
        {  OnlyWhen => 1  },
        sub { "@_" },
    );

is similar to:

    my @list= qw/ 1 11 111 112 113 12 121 122 123
                  13 131 132 133 2 21 211 212 ... /;

Another example:

    NestedLoops(
        [  ( [ 1..3 ] ) x 3  ],
        { OnlyWhen => 1 },
        \&Stuff,
    );

is similar to:

    for my $a (  1..3  ) {
        Stuff( $a );
        for my $b (  1..3  ) {
            Stuff( $a, $b );
            for my $c (  1..3  ) {
                Stuff( $a, $b, $c );
            }
        }
    }

Last example:

    NestedLoops(
        [  ( [ 1..3 ] ) x 3  ],
        { OnlyWhen => \&Test },
        \&Stuff,
    );

is similar to:

    for my $a (  1..3  ) {
        Stuff( $a )   if  Test( $a );
        for my $b (  1..3  ) {
            Stuff( $a, $b )   if  Test( $a, $b );
            for my $c (  1..3  ) {
                Stuff( $a, $b, $c )
                    if  Test( $a, $b, $c );
            }
        }
    }

=back

=head4 \&Code

The subroutine that gets called for each iteration.

=head4 Iterator

If you don't pass in a final code reference to NestedLoops, then
NestedLoops will return an iterator to you (without having performed
any iterations yet).

The iterator is a code reference.  Each time you call it, it returns the
next list of selected values.  Any arguments you pass in are ignored (at
least in this release).

=head3 Examples

=head4 Finding non-repeating sequences of digits.

One way would be to loop over all digit combinations but only selecting
ones without repeats:

    use Algorithm::Loops qw/ NestedLoops /;
    $|= 1;
    my $len= 3;
    my $verbose= 1;
    my $count= NestedLoops(
        [   ( [0..9] ) x $len  ],
        {   OnlyWhen => sub {
                    $len == @_
                &&  join('',@_) !~ /(.).*?\1/;
            #or &&  @_ == keys %{{@_,reverse@_}};
            }
        },
        sub {
            print "@_\n"   if  $verbose;
            return 1;
        },
    );
    print "$count non-repeating $len-digit sequences.\n";

    0 1 2
    0 1 3
    0 1 4
    0 1 5
    0 1 6
    0 1 7
    0 1 8
    0 1 9
    0 2 1
    ...
    9 8 5
    9 8 6
    9 8 7
    720 non-repeating 3-digit sequences.

But it would be nice to not waste time looping over, for example
(2,1,2,0,0) through (2,1,2,9,9).  That is, don't even pick 2 as the
third value if we already picked 2 as the first.

A clever way to do that is to only iterate over lists where the digits
I<increase> from left to right.  That will give us all I<sets> of
non-repeating digits and then we find all permutations of each:

    use Algorithm::Loops qw/ NestedLoops NextPermute /;
    $|= 1;
    my $len= 3;
    my $verbose= 1;
    my $iter= NestedLoops(
        [   [0..9],
            ( sub { [$_+1..9] } ) x ($len-1),
        ],
    );
    my $count= 0;
    my @list;
    while(  @list= $iter->()  ) {
        do {
            ++$count;
            print "@list\n"   if  $verbose;
        } while( NextPermute(@list) );
    }
    print "$count non-repeating $len-digit sequences.\n";

    0 1 2
    0 2 1
    1 0 2
    1 2 0
    2 0 1
    2 1 0
    0 1 3
    0 3 1
    1 0 3
    1 3 0
    3 0 1
    3 1 0
    0 1 4
    0 4 1
    ...
    9 6 8
    9 8 6
    7 8 9
    7 9 8
    8 7 9
    8 9 7
    9 7 8
    9 8 7
    720 non-repeating 3-digit sequences.

A third way is to construct the list of values to loop over by excluding
values already selected:

    use Algorithm::Loops qw/ NestedLoops /;
    $|= 1;
    my $len= 3;
    my $verbose= 1;
    my $count= NestedLoops(
        [   [0..9],
            ( sub {
                my %used;
                @used{@_}= (1) x @_;
                return [ grep !$used{$_}, 0..9 ];
            } ) x ($len-1),
        ],
        sub {
            print "@_\n"   if  $verbose;
            return 1;
        },
    );
    print "$count non-repeating $len-digit sequences.\n";

    0 1 2
    0 1 3
    0 1 4
    0 1 5
    0 1 6
    0 1 7
    0 1 8
    0 1 9
    0 2 1
    0 2 3
    ...
    9 7 8
    9 8 0
    9 8 1
    9 8 2
    9 8 3
    9 8 4
    9 8 5
    9 8 6
    9 8 7
    720 non-repeating 3-digit sequences.

Future releases of this module may add features to makes these last two
methods easier to write.

=cut


    use Algorithm::Loops qw( NestedLoops );
    my @choices= qw/ a b c f /;
    my $picks= 3;
    my %picked;
    print join $/, NestedLoops(
        [ ( \@choices ) x $picks ],
        {   OnlyWhen => sub {
                return -1   if  $picked{$_};
                $picked{$_}= 1;
                return  $picks == @_;
            },
            Post => sub {
                delete $picked{$_};
            },
        },
        sub { join '', @_ },
    ), '';

    return  sub {
        local( $_ );
        my $act;
        while( 1 ) {
            $act ||= 0;
            if(  $act < 0  ) {
                $act= -$act - 1;
                $act= @list   if  @list < $act;
                while(  $act--  ) {
                    if(  $post  ) {
                        $_= $list[$i--];
                        $post->( @_ );
                    }
                    $i--;
                    pop @list;
                }
            } elsif(  $i < $#$loops  ) {
                # Prepare to append one more value:
                $idx[++$i]= -1;
                if(  isa( $loops->[$i], 'CODE' )  ) {
                    $_= $list[-1];
                    $vals[$i]= $loops->[$i]->(@list);
                }
            }
            return   if  $i < 0;
            # Increment furthest value, chopping if done there:
            while( 1 ) {
                if(  $post  ) {
                    $_= $list[-1];
                    $post->( @_ );
                }
                last   if  ++$idx[$i] < @{$vals[$i]};
                pop @list;
                return   if  --$i < 0;
            }
            $list[$i]= $vals[$i][$idx[$i]];
            my $act;
            $act= !ref($when) ? $when : do {
                $_= $list[-1];
                $when->(@list);
            };
            return @list   if  $act;
        }
    };
