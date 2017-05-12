package Class::Colon;
use strict; use warnings;

our $VERSION = "0.03";

=head1 NAME

Class::Colon - Makes objects out of colon delimited records and vice versa

=head1 VERSION

This document covers version 0.03 of C<Class::Colon>.

=head1 SYNOPSIS

    use Date;
    use Class::Colon
        Person  => [ qw ( first middle family date_of_birth=Date=new ) ],
        Address => [ qw ( street city province code country          ) ];

    Person->DELIM(','); # change from colon to comma for delimeter
    my $names = Person->READ_FILE($file_name);
    foreach my $name (@$names) {
        print $name->family, ",", $name->first, $name->middle, "\n";
    }

    open ADDRESS_FILE, "addresses.dat" or die "...\n";
    my $addresses = Address->READ_HANDLE(*ADDRESS_FILE);
    foreach my $address (@$addresses) {
        print $address->street . "\n"
        print $address->city . ", " . $address->province . "\n";
        print $address->country, "\n" if $address->country;
    }
    close ADDRESS_FILE;

    my $sample_address = Address->OBJECTIFY(
        "1313 Mocking Bird Ln:Adamstown:PA:12345:USA"
    );  # convert one string to an object

    my $first_address = $addresses->[0]->STRINGIFY();
    # puts it back in delimited form

    Address->WRITE_FILE("output.dat", $addresses);
    
    open ADDRESS_FILE, ">newaddr.dat" or die "...\n";
    Address->WRITE_HANDLE(*ADDRESS_FILE, $addresses);
    close ADDRESS_FILE;

=head1 DESCRIPTION

To turn your colon delimited file into a list of objects, use C<Class::Colon>,
giving it the name you want to use for the class and an anonymous array of
column names which will become attributes of the objects in the class.  List
the names in the order they appear in the input.  Missing fields will be set
to "".  Extra fields will be ignored.  Use lower case names for the fields.
Upper case names are reserved for use as methods of the class.

Most fields will be simple scalars, but if one of the fields should be an
object, its entry should be of the form

    attribute_name=package_name=constructor_name

as shown above for C<date_of_birth> which is of type C<Date> whose constructor
is C<new>.  In that example, I could have omitted the constructor name, since
C<new> is the default.

You may objectify as many different record types as you like in one use
statement.  You may have multiple use statements throughout your program
or module.  If you are using this package from another package, you should
worry a little about namespace collision.  There is only one list of classes
made by this package.  The names must be unique or Bad Things will happen.
Feel free to include your module name in the names of the fabricated classes
as in:

    package YourModule;
    use Class::Colon YourModule::Person => [ qw( field names here ) ];

You wouldn't have to use the double colon, but it makes sense to me.

If your delimiter is not colon, call DELIM on I<your> class I<before> calling
C<READ_*>.  Pass it as a string.  It can be any length, but is taken
literally.

Feel free to add code to the generated package(s) before or after using
Class::Colon.  But, keep in mind possible name conflicts.  As pointed out
below (under METHODS), all ALL_CAPS names are reserved.

=head1 ABSTRACT

  This module turns colon separated data files into lists of objects.

=head2 EXPORT

None, this is object oriented.

=head1 METHODS

There are currently only a few methods.  There are two class methods
for reading, READ_FILE and READ_HANDLE, (these work for every class you
requested in your use Class::Colon statement).  There are corresponding
class methods for writing, WRITE_FILE and WRITE_HANDLE.  If you want to handle
the I/O manually (or maybe you don't need I/O), there are two methods to help,
OBJECTIFY (takes a string returns an object) and STRINGIFY (the opposite).
There is also a set of dual use accessors, one for each field in each class.
You name these yourself in the use statement.  Finally, there is a DELIM
method which allows you to set the delimiter.  This can be any literal string,
it applies to all fields in the file.  There is a separate delimiter for
each class.  It defaults to colon.

You should consider every ALL_CAPS name reserved.  I reserve the right to
add methods in the future, their names will be ALL_CAPS, as the current
method names are.  Therefore, don't use ALL_CAPS for field names.

In addition to retrieving the attributes through accessor methods, you
could peek directly at the data.  It is stored in a hash so the following
are equivalent:

    my $country = $address->country();

and

    my $country = $address->{country};

Using this fact might make some things neater in your code (like print
statements).  It also saves a tiny amount of time.  Our OO teachers
will smack our hands, if they hear about this little arrangement, so keep
quite about it :-).  I have no plans to change the implementation, but
they tell me never to make such promises.

=cut

use Carp;

our %simulated_classes;

sub import {
    my $class = shift;
    my %fakes = @_;

    foreach my $fake (keys %fakes) {
        no strict;
        *{"$fake\::NEW"}     = sub { return bless {}, shift; };

        foreach my $proxy_method qw(
            read_file  read_handle  objectify delim
            write_file write_handle stringify
        ) {
            my $proxy_name   = "$fake"  . "::" . uc $proxy_method;
            my $real_name    = "$class" . "::" .    $proxy_method;
            *{"$proxy_name"} = \&{"$real_name"};
        }

        my @attributes;
        foreach my $col (@{$fakes{$fake}}) {
            my ($name, $type, $constructor)  = split /=/, $col;
            *{"$fake\::$name"} = _make_accessor($name, $type, $constructor);
            push @attributes, $name;
        }
        $simulated_classes{$fake} = {ATTRS => \@attributes, DELIM => ':'};
    }
}

sub _make_accessor {
    my $attribute   = shift;
    my $type        = shift;
    my $constructor = shift || "new";

    if (defined $type) { # we need to call a constructor
        return sub {
            my $self            = shift;
            my $new_val         = shift;
            if (defined $new_val) {
                $self->{$attribute} = $type->$constructor($new_val)
            }
            return $self->{$attribute};
        };
    }
    else { # we can just dump the scalar into the attribute
        return sub {
            my $self            = shift;
            my $new_val         = shift;
            $self->{$attribute} = $new_val if defined $new_val;
            return $self->{$attribute};
        };
    }
}

=head2 DELIM

Call this through one of the names you supplied in your use statement.  Pass
it a string.  For example, you could say

    Person->DELIM(';');

this would change the delimiter from colon to semi-colon for Person.  No
other classes would be affected.

=cut

sub delim {
    my $fake_class = shift;
    my $string     = shift;

    if (defined $string) {
        $simulated_classes{$fake_class}{DELIM} = $string;
    }
    return $simulated_classes{$fake_class}{DELIM};
}

=head2 READ_FILE and READ_HANDLE

Call these mehtods through one of the names you supplied in your use
statement.

Both READ_FILE and READ_HANDLE return an array reference with one element
for each line in your input file.  All lines are represented even if they
are blank or start with #.  The array elements are objects of the same type
as the name you used to call the method.  Think of these as super constructors,
instead of making one object at a time, they make as many as they can from
your input.

READ_FILE takes the name of a file, which it opens, reads, and closes.

READ_HANDLE takes an open handle ready for reading.  You must ensure that the
handle is properly opened and closed.

=cut

sub read_file {
    my $class    = shift;
    my $file     = shift;

    open FILE,   "$file" or croak "Couldn't read $file: $!";
    my $retval   = $class->READ_HANDLE(*FILE);
    close FILE;

    return $retval;
}

sub read_handle {
    my $class  = shift;
    my $handle = shift;

    my @rows;
    while (<$handle>) {
        chomp;
        push @rows, $class->OBJECTIFY($_);
    }
    return \@rows;
}

=head2 OBJECTIFY

If you want to control the read loop for your data, this method is here
to help you.  Call it through a class name.  Pass it one line (chomp it
yourself).  Receive one object.

=cut

sub objectify {
    my $class    = shift;
    my $string   = shift;
    my $config   = $simulated_classes{$class};
    my $col_list = $config->{ATTRS};

    my $new_object = $class->NEW();
    my @cols       = split /$config->{DELIM}/, $string;
    foreach my $i (0 .. @cols - 1) {
        my $method = $col_list->[$i];
        $new_object->$method($cols[$i]);
    }
    return $new_object;
}

=head2 WRITE_FILE and WRITE_HANDLE

Call these mehtods through one of the names you supplied in your use
statement.

Both WRITE_FILE and WRITE_HANDLE return an array reference with one element
for each line in your input file.  The lines are made by joining the fields
in the order they appeared in the use statement using the current DELIM.

WRITE_FILE takes the name of a file, which it opens, writes, and closes.

WRITE_HANDLE takes a handle open for writing.  You must ensure that the handle
is properly opened and closed.

=cut

sub write_file {
    my $class    = shift;
    my $file     = shift;

    open FILE,   ">$file" or croak "Couldn't write $file: $!";
    my $retval   = $class->WRITE_HANDLE(*FILE, @_);
    close FILE;

    return $retval;
}

sub write_handle {
    my $class  = shift;
    my $handle = shift;
    my $rows   = shift;

    foreach my $row (@$rows) {
        print $handle $row->STRINGIFY() . "\n";
    }
}

=head2 STRINGIFY

Call this through an object you got by using Class::Colon.  Receive
a colon delimited string suitable for writing back to your file.  The
string comes with no newline, unless the last field happens to have one.
You may need to supply a newline, especially if you chomped.

=cut

sub stringify {
    my $self     = shift;
    my $type     = ref($self);
    my $config   = $simulated_classes{$type};
    my $col_list = $config->{ATTRS};
    my $retval;

    my @fields;
    foreach my $att (@$col_list) {
        push @fields, $self->{$att};
    }
    return join $config->{DELIM}, @fields;
}

=head2 accessors

For each attribute you name in your use statement, there is a corresponding
dual use accessor.  The names of the accessors are the same as the names
you used (how convenient).  You can also fish directly in the hash based
object using the name of attribute as the key, but don't tell your OO
instructor.

=cut

=head1 BUGS and OMISSIONS

There is no quoting.  If a colon (or the DELIM of your choice) is
quoted, it still counts as a field separator.

Comments and blank lines are treated as regular records.

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Phil Crow, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.1 itself. 

=cut

1;
