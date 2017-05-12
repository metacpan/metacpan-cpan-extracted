package Class::PObject::Type;

# Type.pm,v 1.6 2004/05/19 06:07:52 sherzodr Exp

use strict;
#use diagnostics;
use vars ('$VERSION', '@ISA');
use overload (
    '""' => 'id',
    bool  => sub { shift->{id} ? 1 : 0 },
    fallback => 1
);
use Carp;


$VERSION = '1.03';









# meant to be overwritten
sub _init {
    my $self = shift;

}








sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $self = { @_ };

    bless $self, $class;
    $self->_init();
    return $self
}



sub id {
    my $self = shift;
    return $self->{id}
}




sub load {
    my $class = shift;
    $class = ref($class) || $class;
    return bless { id=>$_[0], args=>$_[1] }, $class
}




sub dump {
    my $self = shift;

    require Data::Dumper;
    my $d = Data::Dumper->new([$self], [ref $self]);
    $d->Indent(2);
    return $d->Dump()
}




# member functions for each  column type
sub substr {
	my $self = shift;
	unless ( @_ ) {
		croak "$self->substr(): usage error";
	}
	return unless defined $self->id();
	return CORE::substr($self->id, $_[0], $_[1])
}



sub ucfirst {
    my $self = shift;

    if ( @_ ) {
        croak "$self->ucfirst(): usage error";
    }
    return unless defined $self->id();
    return CORE::ucfirst( $self->id );
}



sub lcfirst {
    my $self = shift;

    if ( @_ ) {
        croak "$self->lcfirst(): usage error";
    }
    return unless defined $self->id();
    return CORE::lcfirst( $self->id );
}



sub lc {
    my $self = shift;

    if ( @_ ) {
        croak "$self->lc(): usage error";
    }
    return unless defined $self->id();
    return CORE::lc( $self->id );
}



sub uc {
    my $self = shift;

    if ( @_ ) {
        croak "$self->uc(): usage error";
    }
    return unless defined $self->id();
    return CORE::uc( $self->id );
}



1;
__END__

=head1 NAME

Class::PObject::Type - Column type specification

=head1 SYNOPSIS

    pobject User => {
        columns => ['id', 'login', 'psswd', 'email', 'bio'],
        tmap    => {
            id      => 'INTEGER',
            login   => 'VARCHAR(18)',
            psswd   => 'ENCRYPT',
            email   => 'VARCHAR(40)',
            bio     => 'TEXT',
            key     => 'MD5'
        }
    };

=head1 DESCRIPTION

L<Class::PObject|Class::PObject> allows you to specify types for values
that each column will hold. There are several uses for this:

=over 4

=item 1 

Allows specific drivers to be able to optimize object storage as well as
retrieval

=item 2

Allows to filter certain column values before being inserted. Good example would
be, I<MD5> and I<ENCRYPT> column types, where each value should be encrypted before
being stored in the database. This encryption will also apply while loading objects

=back

=head1 TYPE SPECIFICATION

The rest of this manual will talk about how column specification is designed. 
This information will be useful only if you want to be able to extend this type-mapping
functionality.

Each column type is treated as the name of the class with the same specs as any other
class created using C<pobject> construct. Any attributes, if applicable, should be
enclosed into parenthesis. 

For example, types, C<VARCHAR(100)>, C<INTEGER>, C<ENCRYPT>, C<MD5> and C<TEXT> 
are all valid column types.

Let's assume the following class declaration:

    pobject Author => {
        columns => ['id', 'name'],
        tmap    => {
            name    => 'VARCHAR(32)'
        }
    };

=head2 DEFAULT COLUMN TYPE

While declaring classes, we don't have to declare types of all columns. If we don't 
all the columns would default to I<VARCHAR(255)>, with the exception of I<id> column, 
which defaults to I<INTEGER>.

=head2 TYPE CLASS

We said each I<type> was a class. These classes have the same interface as any other
class generated through C<pobject> construct. Instead of being generated out of
Class::PObject::Template, however, these particular classes inherit from 
Class::PObject::Type.

=head2 HOW IT WORKS

So, how pobject will interpret our I<VARCHAR(32)> anyway? 

It assumes that there is a class called I<VARCHAR>, and creates a new object
of this class by calling its C<new()> - constructor with the value passed
to this column.

For example, if we were to do something like:

    $author = new Author();
    $author->name("Sherzod Ruzmetov");

When we called C<name()>, that's what happens behind the scenes:

    require VARCHAR;
    $type = new VARCHAR(id=>"Sherzod Ruzmetov", args=>32);

And when we save the object into database, it would call its C<id()> method
and uses its return value to store into disk.

When the column is loaded, C<pobject> will only load the strings as are, 
and will inflate the object only once needed.

So in other words, when we do:

    $author = Author->load(217);

C<pobject> first just loads the column values as are, and when we
try to access the value of the column by saying:

    $name = $author->name();

it will do something like:

    require VARCHAR;
    $type = VARCHAR->load("Sherzod Ruzmetov"); 
    return $type

So, in other words, above C<name()> method returns an object. However,
this object in string context, will always return the value of its I<id>
thanks to operator overloading.

=head1 HAS-A RELATIONSHIPS

Because type classes provide the same interface as any other pobject class,
we could define object relationships as easily as defining column types. Refer to Class::PObject's 
L<online manual|Class::PObject> for further details.

=head1 MEMBER FUNCTIONS

Since each column is an object, each column can have its own methods, which we'd like to call I<member functions>.
As of this release following C<member functions> are supported by B<all> column types:

=over 4

=item substr($offset, $length)

Returns a substring off the column's string value. Range of this sub-string is defined by C<$offset> and C<$length>.
Example:

    pobject Peprson => {
        columns => ['id', 'name']
    };

    $me = Person->new();
    $me->name("Sherzod Ruzmetov");

    $substr = $me->name()->substr(0, 5);

In the above example C<$substr> will hold first 6 letters of whatever C<< $me->name() >> could've returned.

=item lc()

Identical to Perl's built-in L<lc()|perlfunc/"lc"> function

=item uc()

Identical to Perl's buil-in L<uc()|perlfunc/"uc"> function

=item ucfirst()

Identical to Perl's built-in L<ucfirst()|perlfunc/"ucfirst"> function

=item lcfirst()

Identical to Perl's built-in L<lcfirst()|perlfunc/"lcfirst"> function

=back

=head1 SEE ALSO

L<Class::PObject::Type::INTEGER>,
L<Class::PObject::Type::VARCHAR>,
L<Class::PObject::Type::ENCRYPT>,
L<Class::PObject::Type::MD5>,
L<Class::PObject::Type::SHA1>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject/"COPYRIGHT AND LICENSE">.

=cut
