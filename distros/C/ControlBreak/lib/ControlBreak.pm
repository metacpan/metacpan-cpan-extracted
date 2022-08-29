# ControlBreak.pm - Compare values during iteration to detect changes

# Done:
# - switch from using say join to using printf in the Synopsis example

# To Do:
# - provide an accumulate method that counts and sums an arbitrary number of named variables


=head1 NAME

ControlBreak - Compare values during iteration to detect changes

=head1 SYNOPSIS

    use v5.18;

    use ControlBreak;

    # set up two levels, in minor to major order
    my $cb = ControlBreak->new( qw( District Country ) );

    my $country_total = 0;
    my $district_total = 0;

    while (my $line = <DATA>) {
        chomp $line;

        my ($country, $district, $city, $population) = split ',', $line;

        # test the values (minor to major order)
        $cb->test($district, $country);

        # break on District (or Country) detected
        if ($cb->break('District')) {
            printf "%s,%s,%d%s\n", $cb->last('Country'), $cb->last('District'), $district_total, '*';
            $district_total = 0;
        }

        # break on Country detected
        if ($cb->break('Country')) {
            printf "%s total,%s,%d%s\n", $cb->last('Country'), '', $country_total, '**';
            $country_total = 0;
        }

        $country_total  += $population;
        $district_total += $population;
    }
    continue {
        # save the current values (as received by ->test) as the new
        # 'last' values on the next iteration.
        $cb->continue();
    }

    # simulate break at end of data, if we iterated at least once
    if ($cb->iteration > 0) {
        printf "%s,%s,%d%s\n", $cb->last('Country'), $cb->last('District'), $district_total, '*';
        printf "%s total,%s,%d%s\n", $cb->last('Country'), '', $country_total, '**';
    }

    __DATA__
    Canada,Alberta,Calgary,1019942
    Canada,Ontario,Ottawa,812129
    Canada,Ontario,Toronto,2600000
    Canada,Quebec,Montreal,1704694
    Canada,Quebec,Quebec City,531902
    Canada,Quebec,Sherbrooke,161323
    USA,Arizona,Phoenix,1640641
    USA,California,Los Angeles,3919973
    USA,California,San Jose,1026700
    USA,Illinois,Chicago,2756546
    USA,New York,New York City,8930002
    USA,New York,Buffalo,281757
    USA,Pennsylvania,Philadelphia,1619355
    USA,Texas,Houston,2345606

=head1 DESCRIPTION

The B<ControlBreak> module provides a class that is used to detect
control breaks; i.e. when a value changes.

Typically, the data being retrieved or iterated over is ordered and
there may be more than one value that is of interest.  For example
consider a table of population data with columns for country,
district and city, sorted by country and district.  With this module
you can create an object that will detect changes in the district or
country, considered level 1 and level 2 respectively. The calling
program can take action, such as printing subtotals, whenever level
changes are detected.

Ordered data is not a requirement.  An example using unordered data
would be counting consecutive numbers within a data stream; e.g. 0 0
1 1 1 1 0 1 1. Using ControlBreak you can detect each change and
count the consecutive values, yielding two zeros, four 1's, one zero,
and two 1's.

Note that ControlBreak cannot detect the end of your data stream.
The B<test()> method is normally called within a loop to detect changes
in control variables, but once the last iteration is processed there
are no further calls to B<test()> as the loop ends.  It may be necessary,
therefore, to do additional processing after the loop in order to
handle the very last data group; e.g. to print a final set of subtotals.

To simplify this situation, method B<test_and_do())> can be used in
place of B<test()> and B<continue()>.

=cut

########################################################################
# perlcritic rules
########################################################################

## no critic [ProhibitSubroutinePrototypes]

# due to use of postfix dereferencing, we have to disable these warnings
## no critic [References::ProhibitDoubleSigils]

# perlcritic wants POD sections like VERSION, DIAGNOSTICS, CONFIGURATION AND ENVIRONMENT,
# and INCOMPATIBILITIES.  But so far these are unneeded so we'll disable these warnings
# here so that perlcritic gives the module a clean bill of health.

## no critic (Documentation::RequirePodSections)

########################################################################
# Libraries and Features
########################################################################
use strict;
use warnings;
use v5.18;

use Object::Pad 0.66 qw( :experimental(init_expr) );

package ControlBreak;
class   ControlBreak 1.00;

use Carp            qw(croak);

# public attributes
field $iteration    :reader     { 0 };  # [0] counts iterations
field @level_names  :reader;            # [1] list of level names

# private attributes
field $_num_levels;                     # [2] the number of control levels
field %_levname                 {   };  # [3] map of levidx to levname
field %_levidx                  {   };  # [4] map of lenname to levidx
field %_comp_op;                        # [5] comparison operators
field %_fcomp;                          # [6] comparison functions
field $_test_levelnum           { 0 };  # [7] last level returned by test()
field $_test_levelname          { '' }; # [8] last level returned by test()
field @_test_values;                    # [9] the values of the current test()
field @_last_values;                    # [10] the values from the previous test()
field $_continue_count          { 0 };  # [11] the number of types continue was called

=head1 FIELDS

=head2 iteration

A readonly field that provides the current iteration number.

This can be useful if you are doing an final processing after an
iteration loop has ended.  In the event that the data stream is empty
and there were no iterations, then you can condition your final
processing on iteration > 0.

Note that B<interation> is incremented by B<test> (or <test_and_do>).
Therefore, when called wihtin a loop it is effectively zero-based if
referenced within the iteration block before B<test> is invoked, and
then one-based after B<test>.

=head2 level_names

A readonly field that provides a list of the level names that were
provided as arguments to new().

=cut

######################################################################
# Constructor (a.k.a. the new() method)
######################################################################

=head1 METHODS

=head2 new ( <level_name> [, <level_name> ]... )

Create a new ControlBreak object.

Arguments are user-defined names for each level, in minor to major
order.  The set of names must be unique, and they must each start
with a letter or underscore, followed by any number of letters,
numbers or underscores.

A level name can also begin with a '+', which denotes that a numeric
comparison will be used for the values processed at this level.

The number of arguments to new() determines the number of control levels
that will be monitored.  The variables provided to method test() must
match in number and datatype to these operators.

The order of the arguments corresponds to a hierachical level of
control, from lowest to highest; i.e. the first argument corresponds
to level 1, the second to level 2, etc.  This also corresponds
to sort order, from minor to major, when iterating through a data stream.

=cut

BUILD {
    croak '*E* at least one argument is required'
        if @_ == 0;

    foreach my $arg (@_) {
        croak '*E* invalid level name'
            unless $arg =~ m{ \A [+]? [[:alpha:]_]\w+ }xms;
    }

    $_num_levels = @_;

    my %lev_count;

    foreach my $arg (@_) {
        $lev_count{$arg}++;
        croak '*E* duplicate level name: ' . $arg
            if $lev_count{$arg} > 1;
        my $level_name = $arg;
        my $is_numeric = $level_name =~ s{ \A [+] }{}xms;
        push @level_names, $level_name;
        my $op = $is_numeric ? '==' : 'eq';
        $_comp_op{$level_name} = $op;
        $_fcomp{$level_name} = _op_to_func($op);
    }

    @_last_values = ( undef ) x $_num_levels;

    my $ii = 0;
    map { $_levname{$ii++} = $_ } @level_names;

    $ii = 0;
    map { $_levidx{$_} = $ii++ } @level_names;
}

######################################################################
# Public methods
######################################################################

=head2 break ( [ <level_name> ] )

The B<break> method provides a convenient way to check whether the last
invocation of the test method resulted in a control break, or a
control break greater than or equal to the <level_name> optionally
provided as an argument.

For example, if you have levels 'City', 'State' and 'Country', and
there's a control break on level 1 (City), then invoking B<break()>
will return 1 and therefore be treated as true within a condition.
If there was no control break, then 0 (false) is returned.

When invoked with a level name argument, B<break> will map the level name
to a level number and compare it to the control break level determined
by the last invocation of test().  If the tested control break level
number is equal or higher than the argument level, then that level
number is returned and, since it will be non-zero, treated as a true
value within a condition.  Otherwise, zero (false) is returned.

Ultimately the point of this is that you can use it to write a series
of actions, like printing subtotals and clearing subtotal variables,
such that a higher level control break will trigger actions
associated with lower level control breaks. For example:

    my $cb = ControlBreak( qw/City State Country/ );

    if ( $cb->break() ) {
        say '=== control break detected at level: ' . $cb->levelname;
    }
    if ( $cb->break('City') ) {
        say "City total: $city";
        $city = 0;
    }
    if ( $cb->break('State') ) {
        say "State total: $state";
        $state = 0;
    }
    if ( $cb->break('Country') ) {
        say "Country total: $country";
        $country = 0;
    }

In this example, when a Country control break is detected all three
subtotals will be printed.  When a State control break is detected,
only State and City will print.

=cut

method break ( $level_name=undef ) {
    if ($level_name) {
        croak '*E* invalid level name: ' . $level_name
            unless exists $_levidx{$level_name};
        my $levnum = $_levidx{$level_name} + 1;
        return $_test_levelnum >= $levnum;
    }

    return $_test_levelnum;
}

=head2 comparison ( level_name => [ 'eq' | '==' | sub ] ... )

The B<comparison> method accepts a hash which sets the comparison
operations for the designated levels.  Keywords must match the level
names provide in new().  Values can be '==' for numeric comparison,
'eq' for alpha comparison, or anonymous subroutines.

Anonymous subroutines must take two arguments, compare them in some
fashion, and return a boolean. The first argument to the comparison
routine will be the value passed to the test() method.  The second
argument will be the corresponding value from the last iteration.

All levels are provided with default comparison functions as determined
by new().  This method is provided so you can change one or more of
those defaults.  Any level name not referenced by keys in the
argument list will be left unchanged.

Some handy comparison functions are:

    # case-insensitive match
    sub { lc $_[0] eq lc $_[1] }

    # strings coerced to numbers (so 07 and 7 are equal)
    sub { ($_[0] + 0) == ($_[1] + 0) }

    # blank values treated as matched
    sub { $_[0] eq '' ? 1 : $_[0] eq $_[1] }

=cut

method comparison (%h) {
    while ( my ($level_name, $v) = each %h ) {
        croak '*E* invalid level name: ' . $level_name
            unless exists $_levidx{$level_name};
        $_comp_op{$level_name} = $v;
        $_fcomp{$level_name} = _op_to_func($v);
    }
}

=head2 continue ()

Saves the values most recently provided to the test() method so they
can be compared to new values on the next iteration.

On the next iteration these values will be accessible via the last()
method.

B<continue> is best invoked within the continue block of a loop, to
make sure it isn't missed.

B<continue> cannot be used in conjunction with B<test_and_do>, which
internally calls B<test> and B<continue> for you.

=cut

method continue () {
    @_last_values = @_test_values;
    $_continue_count++;
}

=head2 last ($level)

Returns the value (of the corresponding level) that was given to the
B<test()> method called prior to the most recent one.

The argument can be a level name or a level number.

Normally this is used while iterating through a data stream.  When a
level change (i.e. control break) is detected, the current data value
has changed relative to the preceding iteration.  At this point it
may be necessary to take some action, such a printing a subtotal.
But, the subtotal will be for the preceding group of data and the
current value belongs to the next group.  The B<last()> method allows
you to access the value for the group that was just processed so, for
example, the group name can be included on the subtotal line.

For example, if control levels were named 'X' and 'Y' and you are
iterating through data and invoking test($x, $y) at each iteration,
then invoking $cb->last('Y') on iteration 9 will returns the value of
$y on iteration 8.

Note that B<continue()> should not be invoked before last() within the
scope of an iteration loop; i.e. continue() should be the last thing
done before the next turn of the loop.

=cut

method last ($arg) {
    my $retval;

    if ( $arg =~ m{ \A \d+ \Z }xms ) {
        croak '*E* invalid level number: ' . $arg
            unless exists $_levname{$arg};
        $retval = $_last_values[$arg];
    } else {
        croak '*E* invalid level name: ' . $arg
            unless exists $_levidx{$arg};
        $retval = $_last_values[$_levidx{$arg}];
    }

    return $retval;
}

=head2 levelname

Return the level name for the most recent invocation of the B<test>
method.

=cut

method levelname () {
    return $_test_levelname;
}

=head2 levelnum

Return the level number for the most recent invocation of the B<test>
method.

=cut

method levelnum () {
    return $_test_levelnum;
}


=head2 level_numbers

Return a list of level numbers corresponding to the levels defined
in B<new()>.  This can be useful, for example, when you want to
set up some lexical variables for use as indexes into a list you
might use to accumulate subtotals.

    my $cb = ControlBreak->new( qw( L1 L2 EOD ) );
    my @totals;
    my ($L1, $L2, $EOD) = $cb->level_numbers;

    foreach my $sublist (@list_of_lists) {
        my ($control1, $control2, $number) = $sublist->@*;
        ...
        my $sub_totals = sub {
            if ($cb->break('L1')) {
                # report the L1 subtotal here
                $totals[$L1] = 0; # clear the subtotal
            }
            ...
            # accumulate subtotals
            map { $totals[$_] += $number } $cb->level_numbers;
        };

        $cb->test_and_do(
            $control1,
            $control2,
            $cb->iteration == $list_of_lists - 1,
            $sub_totals
        );
    }


=cut

method level_numbers () {
    return 1 .. $_num_levels;
}

=head2 reset

Resets the state of the object so it can be used again for another
set of iterations using the same number and type of controls
establish when the object was instantiated with new().  Any
comparisons that were subsequently modified are retained.

=cut

method reset () {
    $iteration          = 0;
    $_continue_count    = 0;
    $_test_levelnum     = 0;
    $_test_levelname    = 0;
    @_test_values       = ();
    @_last_values = ( undef ) x $_num_levels;
}

=head2 test ( $var1 [, $var2 ]... )

Submits the control variables for testing against the values from the
previous iteration.

Testing is done in reverse order, from highest to lowest (major to
minor) and stops once a change is detected. Where it stops determines
the control break level.  For example, if $var2 changed, method
levelnum will return 2.  If $var2 did not change, but $var1 did, then
method B<levelnum> will return 1.  If nothing changes, then
B<levelnum> will return 0.

Note that the level numbers set by B<test(...)> are true if there was
a level change, and false if there wasn't.  So, they can be used as a
simple boolean test of whether there was a change.  Or you can use
the B<break> method to determine whether any control break has occured.

Because level numbers correspond to the hierachy of data order, they
can be use to trigger multiple actions; e.g. B<levelnum> >= 1 could be
used to print subtotals for levels 1 whenever a control break occured
for level 1, 2 or 3.  It is usually the case that higher control
breaks are meant to cascade to lower control levels and this can be
achieved in this fashion.  The B<break> method simplifies this.

Note that method B<continue()> must be called at the end of each
iteration in order to save the values of the iteration for the next
iteration. If not, the next B<test(...)> invocation will croak.

=cut

method test (@args) {
    croak '*E* number of arguments to test() must match those given in new()'
        if @args != $_num_levels;

    croak '*E* continue() must be called after test()'
        unless $iteration == $_continue_count;

    @_test_values = @args;

    $iteration++;

    my $is_break;
    my $lev_idx = 0;

    # process tests in reverse order of arguments; i.e. major to minor
    my $jj = @args;
    foreach my $arg (reverse @args) {
        $jj--;

        # on the first iteration, make the last values match the current
        # ones so we don't detect any control break
        $_last_values[$jj] //= $arg
            if $iteration == 1;

        my $level_name = $_levname{$jj};

        # compare the current and last values using the comparison function
        # if they don't match, then it's a control break
        $is_break = not $_fcomp{$level_name}->( $arg, $_last_values[$jj] );

        if ( $is_break ) {
            # internally our lists use the usual zero-based indexing
            # but externally our level numbers are 1-based, where
            # 1 is the most minor control variable.  Level 0 is used
            # to denote no level; i.e. no control break.  Since zero
            # is treated as false by perl, and non-zero as true, we
            # can use the level number in a condition to determine if
            # there's been a control break; ie. $level ? 'break' : 'no break'
            $lev_idx = $jj + 1;
            last;
        }
    }
    my $lev_num = $lev_idx;

    $_test_levelnum  = $lev_num;
    $_test_levelname = $_levname{$jj};

    return;
}

=head2 test_and_do ( $var1 [, $var2 ]... $var_end, $coderef )

The B<test_and_do()> method is similar to B<test()>. It takes the same
arguments as B<test()>, plus one additional argument that is an
anonymous code reference.  Internally, it calls B<test()> and then, if
there is a control break, calls the anonymous subroutine provided in
the last argument.  Typically, that code will perform work related to
subtotals or other actions necessary when a control break occurs.

But B<test_and_do> does one other thing.  It expects the last control
variable ($var_end) to be an end of data indicator, such as the perl
builtin operator B<eof>.  This indicator should return false on each
iteration over the data until the very last iteration -- when it
should change to true, thereby triggering a major control break.

What test_and_do does then is to add an extra loop.  This simulates
a final record and will trigger B<test()> to signal control breaks
at all levels.  Thus, the code provided will be executed between
every change of data AND after all data has been iterated over.

This avoids the necessity of repeating the control break actions
you've put inside the data loop immediately after the loop's closing
bracket.  When you just use B<test> and B<continue>, an end-of-data
control break won't occur and the simplist workaround is to just
duplicate your control break code after the loops closing bracket.

Here's a typical use case involving end of file processing.  Note the
extra control level, named 'EOF', and the use of the B<eof> builtin
function as the second last argument of B<test_and_do>:

    my $cb = ControlBreak->new( qw( L1 L2 EOF ) );

    my $lev1_subtotal = 0;
    my $lev2_subtotal = 0;
    my $grand_total = 0;

    while (my $line = <>) {
        chomp $line;

        my ($lev1, $lev2, $data) = split "\t", $line;

        my $subtotal_coderef = sub {
            if ($cb->break('L1')) {
                say $cb->last('L1'), $cb->last('L2'), $lev1_subtotal . '*';
                $lev1_subtotal = 0;
            }
            ...
            if ($cb->break('EOF')) {
                say 'Grand total,,', $grand_total, '***';
            }

            $lev1_subtotal  += $data;
            $lev2_subtotal  += $data;
            $gran_total     += $data;
        }

        $cb->test_and_do($lev1, $lev2, eof, $subtotal_coderef);
    }

Also note that if your subroutine needs to reference variables
defined outside the scope of the loop (as in this case with the
totalling variables) then it needs to be defined within the loop so
it can be a closure over the variables in the enclosing scope.

Another typical use case involves iterating over a list of values.
Here, we have no built in function to tell us when we've reached the
final value, but if we have a fixed list of values we can use the
length of the list and test it against the value returned by the
ControlBreak iterator method.  For example:

    my $cb = ControlBreak->new( qw( L1 L2 EOD ) );

    my $lev1_subtotal = 0;
    my $lev2_subtotal = 0;
    my $grand_total = 0;

    my $last_iter = @data - 1;

    foreach my $line (@data {
        chomp $line;
        my ($lev1, $lev2, $data) = split "\t", $line;

        my $subtotal_coderef = sub {
            if ($cb->break('L1')) {
                say $cb->last('L1'), $cb->last('L2'), $lev1_subtotal . '*';
                $lev1_subtotal = 0;
            }
            ...
            if ($cb->break('EOD')) {
                say 'Grand total,,', $grand_total, '***';
            }

            $lev1_subtotal  += $data;
            $lev2_subtotal  += $data;
            $gran_total     += $data;
        }

        $cb->test_and_do($lev1, $lev2, $cb->iteration == $last_iter, $subtotal_coderef);
    }

=cut

method test_and_do (@args) {

    croak '*E* test_and_do must have one more argument than new()'
        unless @args == $_num_levels + 1;

    my $coderef = pop @args;
    my $eod = 0 + $args[-1];

    croak '*E* last argument of test_and_do must be a code reference'
        unless ref $coderef eq 'CODE';

    for my $ii (0..$eod) {
        $args[-1] = $ii;
        $self->test(@args);
        $coderef->();
        $self->continue;
    }

}

######################################################################
# Private subroutines and functions
######################################################################
sub _op_to_func ($op) {

    my $fcompare;

    if ($op eq '==') {
        $fcompare = sub { $_[0] == $_[1] };
    }
    elsif ($op eq 'eq') {
        $fcompare = sub { $_[0] eq $_[1] };
    }
    elsif (ref $op eq 'CODE') {
        $fcompare = $op;
    }
    else {
        croak '*F* invalid comparison operator: ' . $op;
    }

    return $fcompare;
}

1;

__END__

=head1 AUTHOR

Gary Puckering <jgpuckering@rogers.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

This utility is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/artistic.html>

=cut
