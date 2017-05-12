package Array::GroupBy;

use warnings;
use strict;

use 5.008_008;

use List::Util qw(max);

use version; our $VERSION = qv('0.0.4');

use base qw( Exporter );
our @EXPORT = qw( igroup_by );
our @EXPORT_OK = qw( igroup_by str_row_equal num_row_equal);

# Copyright Stanford University. March 8th, 2012
# All rights reserved.
# Author: Sam Brain

use Carp;
use Params::Validate qw(:all);

########################################
sub igroup_by {
  my %opts = validate(@_, {data    => { type => ARRAYREF                },
                           compare => { type => CODEREF                 },
                           args    => { type => ARRAYREF, optional => 1 },
                          }
  );

  my ($data, $compare, $args) = @opts{qw(data compare args)};

  croak "The array passed to igroup_by( data => ... ) is empty, called"
    unless @$data;

  my $previous_line = $data->[0];

  my $i = 1;  # index into @$data

  return sub {
    my @result;
    my $line;

    return unless $previous_line;

    push @result, $previous_line;

    while ($line = $data->[$i++]) {
      last
        unless $compare->($previous_line, $line, $args);

      push @result, $line;
    }
    # line was different from previous, or end-of-data
    $previous_line = $line;

    return \@result;
  }
}

########################################
sub str_row_equal { return _row_equal( sub { $_[0] eq $_[1] }, @_ ) }
sub num_row_equal { return _row_equal( sub { $_[0] == $_[1] }, @_ ) }

########################################
sub _row_equal {
  my ($is_equal, $first, $second, $slice) = @_;

  return 0 if @$first != @$second;

  $slice = [ 0 .. $#$first] unless $slice and @$slice;

  #print "_row_equal(): slice @$slice, ", max(@$slice), ", ", $#$first, " \n";

  # slice out of bounds
  return 0 if max(@$slice) > $#$first;

  #print "_row_equal(): slice @$slice\n";

  foreach (@$slice) {
    # both undef
    next unless defined $first->[$_] or defined $second->[$_];

    # one defined, one not
    return 0 if defined $first->[$_] xor defined $second->[$_];

    #print "first ", $first->[$_], " second ", $second->[$_], "\n";

    return 0 unless $is_equal->($first->[$_], $second->[$_]);
  }

  return 1;
}

1;

__END__

=head1 NAME

Array::GroupBy - Group equal elements of an ordered array, or list.


=head1 VERSION

This document describes Array::GroupBy version 0.0.1


=head1 SYNOPSIS

  use Array::GroupBy;
  # or
  use Array::GroupBy qw(igroup_by str_row_equal num_row_equal);

C<Array::Groupby> exports function C<igroup_by()> by default, and convenience
functions C<str_row_equal()> and C<num_row_equal()> if requested.

=head1 DESCRIPTION

=over

=item igroup_by

C<igroup_by()> returns an iterator which when called, returns sub-arrays of the given
array whose elements are "equal" as determined by a user-supplied boolean
function. The iterator does this by stepping through the given data array, 
comparing adjacent elements, and without sorting the array. The name is
inspired by the SQL C<GROUP BY> clause.

=item str_row_equal

=item num_row_equal

C<str_row_equal()> and C<num_row_equal()> are convenience row-comparison
routines which might be of use
for database-derived two-dimensional arrays (i.e. arrays of arrays, of the
kind returned, for example, by DBI module's C<fetchall_arrayref()>). They compare,
respectively, rows of strings or numbers possibly containing C<undef> values.
(See below)

=back

The general usage for C<igroup_by> is:

    use Array::GroupBy;

    $iter = igroup_by(
                data    => \@data,
                compare => \&compare,
              [ args    => \@args, ]    # optional arguments to compare()
                     );

    while ($a = $iter->()) {
      # do something with array @{ $a } ...
    }

The user-supplied boolean function C<compare()> should return 1 (true)
if the two array elements passed as arguments are "equal",
otherwise return 0 (false).

=head3 Example 1: Simple one-dimensional lists:

    use Array::GroupBy;

    # the data to be "grouped"
    my @a = qw(alpha alpha alpha beta beta charlie alpha alpha);

    my $iter = igroup_by(
                data    => \@a,
                compare => sub { $_[0] eq $_[1] },
    );

On repeated calls of:

    while ( my $b = $iter->() ) {
      ...
    }

Array C<@{ $b }> would contain, in order:

    qw(alpha alpha alpha)
    qw(beta beta)
    qw(charlie)
    qw(alpha alpha)


In Example 1 above, where the data was a list of strings,
the comparison subroutine was:

    compare => sub { $_[0] eq $_[1] }

If the data consisted of a list of numbers, the comparison
subroutine would, of course, become:

    compare => sub { $_[0] == $_[1] }


=head3 Example 2: Two-dimensional arrays:

    use Array::GroupBy;

    # people's favourite colour(s)
    # (John and David each have two favourite colours, Alice only one)
    my $l1 = [ qw( Smith John  red    ) ];
    my $l2 = [ qw( Smith John  blue   ) ];
    my $l3 = [ qw( Smith Alice orange ) ];
    my $l4 = [ qw( Black David green  ) ];
    my $l5 = [ qw( Black David red    ) ];

    my $a = [ $l1, $l2, $l3, $l4, $l5 ]; # array to be grouped

    my $iter = igroup_by(
                data    => $a,
                # the data contains no '|' characters
                compare => sub { my ($row1, $row2, $slice) = @_;
                               join('|', @{ $row1 }[ @{ $slice } ] )
                               eq
                               join('|', @{ $row2 }[ @{ $slice } ] )
                             },
                args    => [ 0, 1 ],  # slice: compare first two columns only
    );
  
On repeated calls of:

    while ( my $b = $iter->() ) {
      ...
    }

Array C<@{ $b }> would contain, in order,

    ( $l1, $l2 ),
    ( $l3      ),
    ( $l4, $l5 )

Note that the comparison function used in Example 2 is for illustration
only. A much better routine for this example would be C<str_row_equal()>
included with the module.


=head3 Routines str_row_equal() and num_row_equal()

C<str_row_equal()> and C<num_row_equal()> are row-comparison routines which
are useful when grouping two-dimensional arrays as in Example 2 above.

The subroutines are called with 2 or 3 arguments:
  
    $bool = str_row_equal($row1, $row2)         # for text data
    $bool = num_row_equal($row1, $row2)         # for numeric data
    # or
    $bool = str_row_equal($row1, $row2, $slice) # for text data
    $bool = num_row_equal($row1, $row2, $slice) # for numeric data

where the third argument, C<$slice>, derives from the "C<args =E<gt> ...>" argument in
C<group_by()>

C<str_row_equal()> compares arrays of I<string> data possibly containing
C<undef> values, typically returned from
database SQL queries in which DBI maps NULL values to C<undef>.

Similarly, C<num_row_equal()> compares arrays of I<numeric> data possibly containing
C<undef> values.

Both routines return 1 (true) if the rows are "equal", 0 (false) if they are
"unequal"

When comparing rows, if C<str_row_equal()> and C<num_row_equal()> encounter
C<undef> elements in I<corresponding> column positions,
they will consider the elements C<equal>.
When I<corresponding> column elements are defined and C<undef> respectively, the
elements are considered C<unequal>.

This truth table demonstrates the various combinations (in this case for
numeric comparisons):

   --------+-----------+---------------+---------------+--------------
    row 1  | (1, 2, 3) | (1, undef, 3) | (1, undef, 3) | (1,     2, 3)
    row 2  | (1, 2, 3) | (1, undef, 3) | (1,     2, 3) | (1, undef, 3)
   --------+-----------+---------------+---------------+--------------
    equal? |   yes     |     yes       |      no       |      no

Also note that neither C<str_row_equal()> nor C<num_row_equal()> generate
diagnostics if called with rows of unequal lengths, or for C<args =E<gt> [...]> slice
arguments which are out of bounds for the rows being compared: in both cases
a value of 0 (false) will be returned.

=head3 Example 3: Simulating SQL "GROUP BY" clause

Given a hypothetical annual salary dataset containing Person Name, Year,
and Salary, in k$ (ordered by Person Name), print
out the max annual salary for each Person and the year(s) during which each Person received
that maximum salary.

  use Array::GroupBy;
  use List::Util qw( max );

  # salary dataset
  my @amounts = (
      [ "Smith, J", 2009, 65 ],
      [ "Smith, J", 2010, 63 ],
        ...
      [ "Brown, F", 2006, 45 ],
      [ "Brown, F", 2007, 47 ],
        ...
  );

  my $iter = igroup_by(
                data    => \@amounts,
                compare => sub { $_[0]->[0] eq $_[1]->[0] },
                      );

  while (my $subset = $iter->()) {
    my $max_sal = max map { $_->[2] } @$subset; # max salary

    print "Name: $subset->[0]->[0], ",
           "Max Salary: $max_sal, Year(s) max salary reached: ",
           join(', ',
               map  { $_->[1] }
               grep { $_->[2] == $max_sal } @$subset
           ),
           "\n";
  }

See C<t/5.t> for code.

=head3 Example 4: Building objects

This is the real, "scratch-my-itch" reason for this module: to be able to take
multi-level data generated by SQL, and build objects from
the returned data, in this example Moose objects.

The hypothetical situation being modelled in the database 
is that patients make multiple
visits to a doctor on several occasions and on each visit receive a diagnosis
of their condition.

So object I<Visit> has three attributes, the date the visit took place, the
name of the doctor, and the diagnosis. Object I<Patient> has a first and last
name and a list of Visits. To keep it simple, all scalar attributes are
strings. We assume all patients have unique (First, Last) name pairs.

  package Visit;
  use Moose;
  has  date      => (is => 'ro', isa => 'Str');
  has  doctor    => (is => 'ro', isa => 'Str');
  has  diagnosis => (is => 'ro', isa => 'Str');

  package Patient;
  use Moose;
  has last      => (is => 'ro', isa => 'Str'); 
  has first     => (is => 'ro', isa => 'Str'); 
  has Visits    => (is => 'ro', isa => 'ArrayRef[Visit]');

  no Moose;

  use DBI;

  ...

  my @result;     # this will contain a list of Patient objects

  my $sql = q{
    SELECT
       P.Last, P.First
      ,V.Date, V.Doctor, V.Diagnosis
    FROM
      Patient P
      ,Visit  V
    WHERE
      V.Patient_key = P.Patient_key   -- join clause
      ...
    ORDER BY
       P.Last, P.First
  };

  my $dbh = DBI->connect(...);

  my $data = $dbh->selectall_arrayref($sql);

  # rows of @$data contain: Last, First, Date, Doctor, Diagnosis
  #           at positions: [0]   [1]    [2]   [3]     [4]

  my $iter = igroup_by(
                data    => $data,
                compare => \&str_row_equal,
                args    => [ 0, 1 ],
                      );

  while (my $subset = $iter->()) {

    my @visits = map { Visit->new(
                        date        => $_[2],
                        doctor      => $_[3],
                        diagnosis   => $_[4],
                                 )
                     } @$subset;

    push @result, Patient->new(
                        last  => $subset->[0]->[0],
                        first => $subset->[0]->[1],
                        Visit => \@visits,
                              );
  }
  
See C<t/6.t> for code.

=head1 DIAGNOSTICS

Most error diagnostics are generated by the C<Params::Validate> module
which C<igroup_by()> uses for argument validation.

The C<data =E<gt> ...> and C<compare =E<gt> ...> parameters are mandatory. 
Omitting one will generate error message:

  Mandatory parameter '<data or compare>' missing in call to
    Array::GroupBy::igroup_by

Similarly, using a parameter  not in the list ( "data", "compare", "args" ),
e.g., typo C<compaer =E<gt> ...>, will generate error:

  The following parameter was passed in the call to Array::GroupBy::igroup_by
  but was not listed in the validation options: compaer

If the argument to the C<compare =E<gt> ...> parameter is not a subroutine reference,
e.g., C<compare =E<gt> 'my_sub'>, this will generate error:

  The 'compare' parameter ("my_sub") to Array::GroupBy::igroup_by was a
  'scalar', which is not one of the allowed types: coderef

If any of values of the parameters are undefined, this will generate error:

  The '<data|compare|args>' parameter (undef) to Array::GroupBy::igroup_by
  was an 'undef', which is not one of the allowed types: ...

Passing an empty data array, e.g., C<data =E<gt> []>, will result in error:

  The array passed to igroup_by( data => ... ) is empty,
  called at <program name> line <nnn>.

=head1 DEPENDENCIES

    Carp
    Params::Validate
    List::Util

=head1 BUGS AND LIMITATIONS

No bugs have been reported (yet).

Please report any bugs or feature requests to
C<bug-array-groupby@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Sam Brain  C<< <samb@stanford.edu> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Sam Brain C<< <samb@stanford.edu> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

##### SUBROUTINE INDEX #####
#                          #
#   gen by index_subs.pl   #
#   on 25 Jun 2012 10:59   #
#                          #
############################


####### Packages ###########

# Array::GroupBy ................ 1
#   igroup_by ................... 1
#   num_row_equal ............... 1
#   str_row_equal ............... 1
#   _row_equal .................. 2

