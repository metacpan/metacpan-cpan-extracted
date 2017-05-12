#################################################################
#
#   Class::DBI::AutoIncrement - Emulate auto-incrementing columns in a Class::DBI table
#
#   $Id: AutoIncrement.pm,v 1.7 2006/06/08 08:58:32 erwan Exp $
#
#   060412 erwan Created
#   060517 erwan Added croak when no other parent than Class::DBI::AutoIncrement
#   060607 erwan Fixed rt 19752, backward compatibility issue with create()
#   060607 erwan Refactor to use maximum_value_of() (credits to David Westbrook)
#
#################################################################

#################################################################
#
#   an object holding data describing one auto-incremented table.
#   in charge of incrementing that table's index
#
#################################################################

package Class::DBI::AutoIncrement::Descriptor;

use 5.006;
use strict;
use warnings;
use base qw(Class::Accessor);

Class::Accessor->mk_accessors('table',  # name of the table to auto-increment
			      'column', # name of the auto-incremented column in that table 
			      'min',    # the start value for the index sequence
			      'step',   # the increment step of the index sequence
			      'cache',  # if true, the index value is cached instead of being queried upon each insert
			      'index',  # value of the index used at the last insert (if caching is on)
			      );

sub new { return bless({},__PACKAGE__); }

1;

#################################################################
#
#   Class::DBI::AutoIncrement
#
#################################################################

package Class::DBI::AutoIncrement;

use 5.006;
use strict;
use warnings;
use Carp qw(croak confess);

our $VERSION = '0.05';

# set at runtime by _set_inheritance()
our @ISA;

##################################################################
#
#   PRIVATE FUNCTIONS
#
##################################################################

#-----------------------------------------------------------------
#
#   _set_inheritance - make Class::DBI::AutoIncrement inherit from the same parents as the calling class
#                      see discussion below.
#

my $inherited = 0;

sub _set_inheritance {
    return if ($inherited);

    my($caller) = shift;
    no strict 'refs';

    my @parents = grep { $_ ne __PACKAGE__ } @{"$caller\::ISA"};
    croak __PACKAGE__." expects class $caller to inherit from at least 1 more parent class" if (scalar @parents == 0);
    
    # inherit from same parents as the calling class, this in order
    # to have the proper inheritance toward the local *::DBI class,
    # without having to know its name and explicitly 'use base' it

    # this might not always work, since it redefines the class hierarchy under time
    # plus we then require twice the same set of parent classes...
    # an alternative would be to emulate ::SUPER-> and skip __PACKAGE__ while
    # calling the methods insert() and create()...

    foreach my $class (@parents) {
        eval qq{ require $class; };
        if (defined $@ && $@ ne "") {
            confess "BUG: \'require $class\' failed because of: ".$@;
        }
    }
    push @ISA, @parents;

    $inherited = 1;
}

#-----------------------------------------------------------------
#
#   _get_descriptor - instanciate an object holding information about the calling class
#

my $descriptors;

sub _get_descriptor {
    my $class = shift;
    if (!exists $descriptors->{$class}) {
        $descriptors->{$class} = new Class::DBI::AutoIncrement::Descriptor($class);
    }
    return $descriptors->{$class};
}

#-----------------------------------------------------------------
#
#   _do_increment - increment sequence if needed, see insert() and create()
#

sub _do_increment {
    my($proto,$class,$values) = @_;

    _set_inheritance($class);

    my $info = _get_descriptor($class);

    # check that we know all that should be known (column name, table name...)
    if (!defined $info->column) {
        croak "no auto-incremented column has been specified for class $class.";
    }

    if (!defined $info->table) {
        croak "no database table has been specified for class $class.";
    }

    my $column = $info->column;

    # if the index column is not set, set it to its next known value
    if (!exists $values->{$column} || !defined $values->{$column}) {
	my $index;

	if (!defined $info->index) {
	    
	    my $id = $proto->maximum_value_of($info->column);
	    
	    if (defined $id) {
		$index = $id + $info->step;
	    } else {
		# table is empty, this will be the first row inserted
		$index = $info->min;
	    }

	    # if caching is on, save the index for next time we need it
	    if ($info->cache) {
		$info->index($index);
	    }
	} else {
	    # we are caching the index, and we know the current highest index
	    $info->index($info->step+$info->index);
	    $index = $info->index;
	}

        $values->{$column} = $index;
    }
}

##################################################################
#
#   PUBLIC (INHERITED) FUNCTIONS
#
##################################################################

#-----------------------------------------------------------------
#
#   autoincrement - register which column should be automatically incremented
#

sub autoincrement {
    my($proto,$column,%args) = @_;
    my $class = ref $proto || $proto;
    _set_inheritance($class);

    if (!defined $column) {
        croak "you must define a column name to autoincrement.";
    }

    my $info = _get_descriptor($class);

    if (defined $info->column()) {
        croak "class $class already has one auto-incremented column";
    }

    $info->column($column);

    if (exists $args{Min}) {
	if ($args{Min} !~ /^-?\d+$/) {
	    croak "parameter 'Min' of method 'autoincrement' must be a number.";
	}
	$info->min($args{Min});
    } else {
	$info->min(0);
    }

    if (exists $args{Step}) {
	if ($args{Step} !~ /^-?\d+$/) {
	    croak "parameter 'Step' of method 'autoincrement' must be a number.";
	}
	$info->step($args{Step});
    } else {
	$info->step(1);
    }

    if (exists $args{Cache} && $args{Cache}) {
	$info->cache(1);
    } else {
	$info->cache(0);
    }
}

#-----------------------------------------------------------------
#
#   table - override *::DBI->table() in order to intercept the table name
#

sub table {
    my($proto,$table,@args) = @_;
    my $class = ref $proto || $proto;
    _set_inheritance($class);

    if (defined $table) {
        my $info = _get_descriptor($class);
        $info->table($table);
    }

    return $class->SUPER::table($table,@args);
}

#-----------------------------------------------------------------
#
#   insert - insert a new value, after incrementing its sequence if necessary
#

sub insert {
    my($proto,$values) = @_;
    my $class = ref $proto || $proto;
    _do_increment($proto,$class,$values);
    return $class->SUPER::insert($values);
}

# backward compatibility
sub create {
    my($proto,$values) = @_;
    my $class = ref $proto || $proto;
    _do_increment($proto,$class,$values);
    return $class->SUPER::create($values);
}

1;

__END__

=head1 NAME

Class::DBI::AutoIncrement - Emulate auto-incrementing columns on Class::DBI subclasses

=head1 VERSION

$Id: AutoIncrement.pm,v 1.7 2006/06/08 08:58:32 erwan Exp $

=head1 SYNOPSIS

Let's assume you have a project making use of Class::DBI. You have implemented
a subclass of Class::DBI called C<MyProject::DBI> that opens a connection
towards your project's database. You also created a class called C<MyProject::Book>
that represents the table C<Book> in your database:

    package MyProject::Book;
    use base qw(MyProject::DBI);

    MyProject::Book->table('book');
    MyProject::Book->columns(Primary => qw(seqid));
    MyProject::Book->table(Others => qw(author title isbn));

Now, you would like the column C<seqid> of the table C<Book> to be auto-incrementing,
but your database unfortunately does not support auto-incrementing sequences. Instead,
use Class::DBI::AutoIncrement to set the value of C<seqid> automagically upon each
C<insert()>:

    package MyProject::Book;
    use base qw(Class::DBI::AutoIncrement MyProject::DBI);

    MyProject::Book->table('book');
    MyProject::Book->columns(Primary => qw(seqid));
    MyProject::Book->table(Others => qw(author title isbn));
    MyProject::Book->autoincrement('seqid');

From now on, when you call:

    my $book = Book->insert({author => 'me', title => 'my life'});

I<$book> gets its seqid field automagically set to the next available value for
that column. If you had 3 rows in the table 'book' having seqids 1, 2 and 3, this
new inserted row will get the seqid 4 (assuming a default setup).

That's it!

=head1 DESCRIPTION

Class::DBI::AutoIncrement emulates an auto-incrementing sequence on a column of a
table managed by a subclass of Class::DBI.

Class::DBI does not natively support self-incrementing sequences, but relies
on the underlying database having support for it, which not all databases
do have. Class::DBI::AutoIncrement provides an emulation layer that automagically
sets a specified column to its next index value when the Class::DBI method
C<insert> is called.

Class::DBI::AutoIncrement does that by querying the table for the current
highest value of the column, upon each call to C<insert> (or only once if
caching is on). You can also specify the increment step and start value of
the sequence.

No more than one column per table can be auto-incremented.

=head1 INTERFACE

A child class of Class::DBI that describes a table with 1 auto-incremented
column must inherit from Class::DBI::AutoIncrement, and Class::DBI::AutoIncrement
must be its first parent class in its @ISA array. The inheritance declaration should
look like:

    package ChildOfClassDBI;

    use base qw(Class::DBI::AutoIncrement Some Other Classes);

This is necessary since Class::DBI::AutoIncrement uses the child class's @ISA
during runtime to access the parent's implementations of the C<insert> method.

Methods:

=over

=item B<autoincrement>($column) or B<autoincrement>($column, [Min => $min,] [Step => $step,] [Cache => 1,])

Tells Class::DBI::AutoIncrement which column should be auto-incremented, and how.

I<$column> is the column name and must be defined. 

I<$min> is the sequence's start value. If I<$min> is not defined, 0 is assumed as the start value. 

I<$step> is the step of increment. If not defined, a step of 1 is assumed.

Example:

    # seqid is automatically incremented by 1 at each insert, starting at 1
    MyProject::Book->autoincrement('seqid', Min => 1);    

    # seqid is automatically incremented by 3 at each insert, starting at 5
    MyProject::Book->autoincrement('seqid', Min => 5, Step => 3);    

By default Class::DBI::AutoIncrement queries the database for the current
highest value of the auto-incremented column upon each call to C<insert>.
If you want to let Class::DBI::AutoIncrement cache this value, set the
'Cache' parameter to true:

    # seqid is automatically incremented by 1 at each insert, and query the database
    # only the first time we need to know the current index value
    MyProject::Book->autoincrement('seqid', Cache => 1);

=item B<insert>(\%data)

Overrides Class::DBI's C<insert> method. If C<< $data->{$column} >> is undefined,
it is automagically set to its next value. If C<< $data->{$column} >> is defined,
this value is used unchanged.

=item B<create>(\%data)

This method is supported for backward compatibility reasons. Do not use it.
Same as C<insert>.

=back

=head1 DIAGNOSTICS

=over

=item "you must define a column name to autoincrement."

You tried to call 'autoincrement' without specifying a column name.

=item "class <class> already has one auto-incremented column"

You tried to call 'autoincrement' twice for the same table/class.

=item "parameter 'Min' of method 'autoincrement' must be a number."

You called the method 'autoincrement' with an invalid number beside the 'Min' attribute. 

=item "no auto-incremented column has been specified for class <class>"

You most likely tried to call 'insert' without having first called 'autoincrement'.

=item "no database table has been specified for class <class>"

You most likely tried to call 'insert' without having first called the Class::DBI methods 'table'.

=item "BUG: 'require <class>' failed because of: ..."

Class::DBI::AutoIncrement failed to find the package <class> in @INC.

=item "Class::DBI::AutoIncrement expects class $caller to inherit from at least 1 more parent class"

A child class of Class::DBI::AutoIncrement must inherit from at least Class::DBI::AutoIncrement and an other class that subclasses Class::DBI 
(or Class::DBI itself).

=back

=head1 BUGS AND LIMITATIONS

Class::DBI::AutoIncrement silently modifies the class hierarchy
of its children classes during runtime. You might get weird
results if your code relies on a static class hierarchy.

If you are using caching, either let Class::DBI::AutoIncrement handle 
the computation of the next sequence index completly or do it all by yourself, 
but do not mix both ways or you will get weird results. Really.

Fetching the current highest value of the sequence from the database
and inserting a new row is not done atomically. You will get race
conditions if multiple threads are inserting into the same table.

=head1 THANKS

Big thanks to David Westbrook for providing me with exemplar
bug reports and usefull inspiration!

=head1 SEE ALSO

See Class::DBI.

See Class::DBI::AutoIncrement::Simple for a simpler alternative that should fit
most of your needs.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Erwan Lemonnier C<< <erwan@cpan.org> >>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut



