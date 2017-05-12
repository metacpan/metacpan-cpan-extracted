package Data::Iterator::Hierarchical;

use warnings;
use strict;

=head1 NAME

Data::Iterator::Hierarchical - Iterate hierarchically over tabular data

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

      my $sth = $db->prepare(<<SQL);
        SELECT agent, co, co_name, sound
        FROM some_view_containing_left_joins 
        ORDER BY agent, co, sound
      SQL

      $sth->execute;

      my $it = hierarchical_iterator($sth);

      while( my($agent) = $it->(my $it_co, 1)) {
	print "agent=$agent\n";
	while( my ($co,$co_name) = $it_co->(my $it_sound, 2) ) {
	  print "  co=$co, co_name=$co_name\n";
	  while( my($sound) = $it_sound->() ) {
	    print "    sound=$sound\n";   
	  }
	}
      }

=head1 DESCRIPTION

This module allows nested loops to iterate in the natural way over a
sorted rowset as would typically be returned from an SQL database
query that is the result of naturally left joining several tables.

In the example from the synopsis we want an interator that iterates
over each distict agent. Within that we want another interator to
iterate over each distict country (code and name).  Finally within
that we want to iterate over sound.

And mostly that's all there is to say.  The iterator should just "Do
What I Mean" (DWIM).

=head2 input

     agent   |  co     | co_name  | sound
    =========|=========|==========|========
      X      |  B      | Belgium  | fizz
      X      |  D      | Germany  | bang
      X      |  D      | Germany  | pow
      X      |  D      | Germany  | zap
      Y      |  NULL   | NULL     | NULL
      Z      |  B      | Belgium  | NULL
      Z      |  E      | Spain    | bar 
      Z      |  E      | Spain    | bar 
      Z      |  I      | Italy    | foo

=head2 output

    agent=X
      co=B, co_name=Belgium
        sound=fizz
      co=D, co_name=Germany
        sound=bang
        sound=pow
        sound=zap
    agent=Y
    agent=Z
      co=B, co_name=Belgium
      co=E, co_name=Spain
        sound=bar
        sound=bar
      co=I, co_name=Italy
        sound=foo

=head1 EXPORT

C<hierarchical_iterator>

=cut 

use base qw(Exporter);
our @EXPORT = qw(hierarchical_iterator);

=head1 FUNCTIONS

=head2 hierarchical_iterator($rowset_source)

A factory for iterator functions. Takes a rowset source as an argument
and returns an iterator as CODE reference (blessed to the
Data::Iterator::Hierarchical class).

The input (or rowset source) is canonically presented as an iterator
function. For each row the iterator function is called in a list
context with an empty argument list. It must return the next row from
the set as a list.  When the source is exhausted the iterator function
must return an empty list.

For convenience the source can also be specified simply as C<\@array>
in which case the iterator C<sub { @{ shift @array } }> is
assumed. Finally, if the data source is specified as anything other
than an unblessed ARRAY or CODE reference then it is assumed to be an
object that provides a C<fetchrow_array()> method (such as a L<DBI>
handle).

=cut

sub hierarchical_iterator {
    my ($input) = @_;
    my $get = do {
	if (ref($input) eq 'CODE') { 
	    $input;
	} elsif ( ref($input) eq 'ARRAY' ) {
	    +sub { @{ shift @$input || [] } } ;
	} else {
	    +sub { $input->fetchrow_array }; 
	};       
    };
    my ($row,$unchanged,$returned,$undef_after);

    my $make_iterator = sub {
	my $fixed = shift;
	my $mk_another = shift;
	bless sub {
	    unless ( wantarray ) {
		require Carp;
		Carp::croak('Data::Iterator::Hierarchical iterator called in non-LIST context');
	    }
	    my ($inner,$cols) ;

	    if ( @_ ) {
		$inner = \shift;
		$cols = shift;
		unless ( defined $cols ) {
		    unless ( eval { require Want; 1 }) {
			require Carp;
			Carp::croak('Number of columns to consume must be specified if Want is not installed');
		    }

		    unless ( $cols = Want::howmany() ) {
			require Carp;
			Carp::croak('Number of columns to consume must be specified if not implicit');
		    }
		}
	    }

	    my $last_col;
	    $last_col = $fixed + $cols - 1 if $cols;

	  GET:
	    while(1) {
		if ( $row ) {
		    # Input exhasted
		    return unless @$row;

		    # This level exhasted
		    return if defined $unchanged && $unchanged < $fixed;

		    # Unspecifed cols => all
		    $last_col = $#$row unless $cols;

		    # Skip duplicate data when we are not at the innermost
		    next if defined $unchanged &&
			$inner &&
			$unchanged > $last_col; 

		    # Skip if everything to the right is undef
		    next if $undef_after <= $fixed;

		    # There is more to come from the current row
		    last if $returned < $fixed;
		}
	    } continue {
		my $prev_row = $row;
		$row = [ $get->() ];
		
		# Release input when we have consumed it all 
		# as a work-round for pre 5.10 where we leak.
		unless ( @$row ) {
		    undef $get;
		    undef $input;
		}

		# Nothing of this data has been returned yet
		$returned = -1;

		# Count unchanged columns at left
		$unchanged=0;
		if ( $prev_row ) {
		    for ( @$row ) {
			last unless @$prev_row;
			last unless defined ==
			    defined ( my $old_datum = shift @$prev_row);
			no warnings 'uninitialized';
			last unless $_ eq $old_datum;
			$unchanged++;
		    }
		}

		# Count undef colums at right
		$undef_after = @$row;
		for ( reverse @$row ) {
		    last if defined;
		    $undef_after--;
		}

	    }
	    undef $unchanged;

	    if ($inner) {
		# Must pass $mk_another in each time as if we were
		# to use $make_iterator directly we would create
		# a circular reference and break garbage
		# collection.
		$$inner = $mk_another->($last_col + 1,$mk_another);
	    }	    

	    $returned = $fixed;
	    return @$row[$fixed .. $last_col];
	};
    };
    $make_iterator->(0,$make_iterator);
}

=head2 $iterator->($inner_iterator,$want)

The interesting function from this module is, of course, the iterator
function returned from the iterator factory.  This iterator, like the
source iterator, should be called in a list context to return a row of
data or or an empty list to denote exhaustion. It is an error to call
the iterator in a non-LIST context.

If the iterator returned by the C<hierarchical_iterator()> factory is
called I<without arguments> it behaves pretty much the same as the
iterator that was supplied as the input except that rows that consist
entirely of undef()s are skipped.

The interesting stuff starts happening when you pass arguments to the
iterator function.

The I<second> argument instructs the iterator to return only a limited
number of leading columns from the next row. The I<first> argument is
used to return another Data::Iterator::Hierarchical iterator that
iterates over successive rows of the input only I<until the leading
columns> change and return only the I<remaining> columns.

    my ($col1,$col2) = $iterator->(my $inner_iterator,2);

The two arguments are specified in a seemingly illogical order because
the second argument becomes optional if the L<Want> module is
installed. When the iterator is called in a simple list assignment (as
above) it can infer the number of columns to returned from the number
of variables on the left hand side of the assignment.

If the iterator C<$inner_iterator> is not read to exhaustion then the
next invocation of C<$iterator> will discard all rows from the source
rowset until there is a different pair of values in the first two
columns. Note that just as C<$iterator> skips rows that consit
entirely of undef()s, C<$inner_iterator> will skip rows from the
rowset where the third column onwards are all undef().

=head1 METHODS

=head2 new($rowset_source)

An alternative to C<hierarchical_iterator>. If you use this
constructor you can suppress the export of the factory function and
just treat this module as providing an object API.

=cut

sub new {
    shift;
    goto &hierarchical_iterator;
}

=head2 slurp(%args)

Hierarchical iterators are useful for processing a large rowsets
without slurping the whole lot into memory. But oftentimes, in the
innermost levels of looping you really do just want to populate a hash
or an array.

The C<slurp> method reads all the remaining input from a iterator and
returns a reference to an simple structure of hashes and
arrays. Without any arguments C<slurp()> returns the rowset as an
array of arrays. The following arguments can be passed as hash
reference or as an key-value list and modify the behaviour of C<slurp>.

=over

=item hash_depth 

A number of leading columns to be used as keys of a multi level-hash. A
C<hash_depth> greater than the number of columns results in a hash
with a depth one more than the number of columns but with the
innermost hashes all being empty.

=item one_column

A flag indicating that for (the remainder of) each row return just the
first column rather than a reference to an array.

=item one_row

A flag indicating that just the first row should be returned not an
array containing all rows. This is only useful when C<hash_depth> is
non-zero as otherwise you may just as well simply call the iteratator
directly a single time. This option is mostly useful to get rid of a
reduntant level of indirection when the source rowset is known to be
such that there will only be a single row for each hash element.

The one_row flag used in conjunction with a C<hash_depth> equal to the
number of columns results in a nested hash of the desired depth with
all the leaf values being undef.

=back

Used together the combination C<slurp( hash_depth=>1, one_row=>1,
one_column=>1 )> is most likely to be useful as tranforms an interator
that would provide successive key-value pairs in a simple hash.

Consider, for example, an iterator for which a simple C<slurp> would
yeild the following (where C<U> is short for C<undef>):

    [ [ 1, 1, 1 ],
      [ 2, 2, 2 ],
      [ 2, 2, 3 ],
      [ 2, 3, 2 ],
      [ 3, 1, 2 ],
      [ 3, 2, U ],
      [ 4, U, U ]];

For the same rowset C<slurp( hash_depth => 1 )> would yeild:

    { 1 => [[ 1, 1 ]],
      2 => [[ 2, 2 ],
	    [ 2, 3 ],
	    [ 3, 2 ]],
      3 => [[ 1, 2,],
	    [ 2, U ]],
      4 => [        ]};

C<slurp( hash_depth => 2 )> would yeild:

    { 1 => { 1 => [[ 1 ]] },
      2 => { 2 => [[ 2 ],
		   [ 3 ]],
	     3 => [[ 2 ]] },
      3 => { 1 => [[ 2 ]],
	     2 => [     ] },
      4 => {              }};

C<slurp( hash_depth => 3, one_row => 1 )> would yeild:

    { 1 => { 1 => { 1 => U }},
      2 => { 2 => { 2 => U,
		    3 => U },
	     3 => { 2 => U }},
      3 => { 1 => { 2 => U },
	     2 => {        }},
      4 => {                }};

C<slurp( hash_depth => 99 )> would yeild:

    { 1 => { 1 => { 1 => {} }},
      2 => { 2 => { 2 => {},
		    3 => {} },
	     3 => { 2 => {} }},
      3 => { 1 => { 2 => {} },
	     2 => {         }},
      4 => {                 }};

C<slurp( hash_depth=>1, one_row=>1, one_column=>1 )> would yeild:

    { 1 => 1,
      2 => 2,
      3 => 1,
      4 => U };

=cut

 sub slurp {
    my $self = shift;
    my $args = @_ == 1 ? shift : { @_ };
    if ( my $depth = $args->{hash_depth} ) {
	my %inner_args = ( %$args, hash_depth => $depth - 1 );
	my %hash;
	while ( my ($key) = $self->(my $inner,1) ) {
	    $hash{$key} = $inner->slurp( \%inner_args ); 
	}
	return \%hash;
    } else {
	my @rowset;
	while ( my @row = $self->() ) {
	    push @rowset => $args->{one_column} ? shift @row : \@row;
	}
	return $args->{one_row} ? shift @rowset : \@rowset;
    }
}

=head1 BUGS AND CAVEATS

In versions of Perl before 5.10 this module leaks closures as a
consequence of a bug in Perl's handling of reference counts.
Consequently the rowset source iterator will not get released on these
versions of Perl unless it is read to exhaustion.

In judging if the leading columns have changed the C<eq> operator
is used so empty string and undefined values will be considered equal.

If you do silly things like change the number of leading columns
requested half way through an iterator's life or request more columns
than are present in the source rowset then the iterator function will
I<do the right thing>.  But don't do that!

=head1 AUTHOR

Brian McCauley, C<< <nobull at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-iterator-hierarchical at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Iterator::Hierarchical>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Iterator::Hierarchical

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Iterator::Hierarchical>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Iterator::Hierarchical>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Iterator::Hierarchical>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Iterator::Hierarchical>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Brian McCauley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::Iterator::Hierarchical
