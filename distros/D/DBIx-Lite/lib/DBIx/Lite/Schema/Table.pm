package DBIx::Lite::Schema::Table;
$DBIx::Lite::Schema::Table::VERSION = '0.35';
use strict;
use warnings;

use Carp qw(croak);
$Carp::Internal{$_}++ for __PACKAGE__;

sub new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        class           => undef,
        resultset_class => undef,
        pk              => delete $params{pk} || [],
        has_many        => {},
        has_one         => {},
    };
    
    for (qw(name)) {
        $self->{$_} = delete $params{$_} or croak "$_ argument needed";
    }
    
    if ($self->{autopk} = delete $params{autopk}) {
        !ref $self->{autopk} or croak "autopk only accepts a single column";
        $self->{pk} = [$self->{autopk}];
    }
    
    !%params
        or croak "Unknown options: " . join(', ', keys %params);
    
    bless $self, $class;
    $self;
}

sub pk {
    my $self = shift;
    my @cols = @_;
    
    if (@cols) {
        $self->{pk} = [
            grep defined $_,
                map { (ref $_ eq 'ARRAY') ? @$_ : $_ } @cols
        ];
        return $self;
    }
    return @{$self->{pk}};
}

sub autopk {
    my $self = shift;
    my $val = shift;
    
    if ($val) {
        $self->{autopk} = $val;
        $self->{pk} = [$val];
        return $self;
    }
    return $self->{autopk};
}

sub class {
    my ($self, $class, $constructor, $storage) = @_;
    
    $self->{class} = $class;
    $self->{class_constructor} = $constructor;
    $self->{class_storage} = $storage;
    
    return undef if !$class;
    
    # make the custom class inherit from our base
    if (!$class->isa('DBIx::Lite::Row')) {
        no strict 'refs';
        push @{"${class}::ISA"}, 'DBIx::Lite::Row';
    }
    
    # install the storage provider
    if ($storage) {
        no strict 'refs';
        no warnings 'redefine';
        *{ "${class}::__dbix_lite_row_storage" } = sub {
            my ($row) = @_;
            
            croak "$class does not provide a $storage method"
                if !$row->can($storage);
            
            return $row->$storage;
        };
    }
    
    return $class;
}

sub resultset_class {
    my $self = shift;
    my $class = shift;
    
    if ($class) {
        $self->{resultset_class} = $class;
        return $self;
    }

    $class =  $self->{resultset_class};
    return undef if !$class;
    
    # make the custom class inherit from our base
    if (!$class->isa('DBIx::Lite::ResultSet')) {
        no strict 'refs';
        push @{"${class}::ISA"}, 'DBIx::Lite::ResultSet';
    }
    
    return $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Lite::Schema::Table

=head1 VERSION

version 0.35

=head1 OVERVIEW

This class holds the very loose table definitions that enable some advanced
features of L<DBIx::Lite>. Note that you can do all main operations, including
searches and manipulations, with no need to define any schema.

This class is not supposed to be instantiated manually. You usually get your 
Table objects by calling the C<table()> method on a L<DBIx::Lite::Schema> object:

    my $table = $dbix->schema->table('books');

=head2 pk

This method accepts one or more fields to be used as the table primary key. Setting
a primary key enables C<update()> and C<delete()> methods on L<DBIx::Lite::Row>
objects.

    $dbix->schema->table('books')->pk('id');
    $dbix->schema->table('books')->pk('foo', 'bar');

=head2 autopk

This method can be used as an alternative to L<pk> but it will only accept a 
single column name, which will be marked as an 
autoincrementing key. This will trigger the retrieval of the autoincremented
id upon creation of new records with the C<insert()> method.

    $dbix->schema->table('books')->autopk('id');

You probably want to use C<autopk()> for most tables, and only use L<pk> for those
many-to-many relationship tables not having an autoincrementing id:

    $dbix->schema->one_to_many('users.id' => 'users_tasks.user_id');
    $dbix->schema->one_to_many('tasks.id' => 'users_tasks.task_id');
    $dbix->schema->table('users')->autopk('id');
    $dbix->schema->table('tasks')->autopk('id');
    $dbix->schema->table('users_tasks')->pk('user_id', 'task_id');

=head2 class

This method accepts a package name that DBIx::Lite will use for this table's 
Result objects. You don't need to declare such package name anywhere else, as
DBIx::Lite will create that class for you.

    $dbix->schema->table('books')->class('My::Book');
    my $book = $dbix->table('books')->find({ id => 2 });
    # $book is a My::Book

The class will subclass L<DBIx::Lite::Row>. You can declare your additional methods
inline:

    $dbix->schema->table('books')->class('My::Book');
    
    sub My::Book::get_page_count {
        my $self = shift;
        return $self->page_count;
    }

If you want to use an existing class you might need to provide DBIx::Lite with some glue 
for correctly inflating objects without messing with your class storage. The C<class()> 
method accepts three more optional arguments:

    $dbix->schema->table('books')->class('My::Book', $constructor, $storage, $inflator);

=over

=item C<$constructor> is the class method to be called as constructor. By default DBIx::Lite will 
call the C<new> constructor if it exists, otherwise it will create a hashref and bless it
into the supplied class. The specified constructor is called without arguments.

    $dbix->schema->table('books')->class('My::Book', 'new');  # default behavior
    $dbix->schema->table('books')->class('My::Book', 'new_from_db');

If your constructor needs values from the database row, you can supply a coderef which 
instantiates the object. It will be supplied a hashref containing the row data.

    $dbix->schema->table('books')->class('My::Book', sub {
        my $row_data = shift;
        return My::Book->new(title => $row_data->{book_title});
    });

=item C<$storage> is an object method which returns a hashref where DBIx::Lite can store
its data. This might be useful because by default DBIx::Lite will assume your object is a 
blessed hashref and it will store its data inside it, but if you're concerned about possible 
conflicts with your object data you can define a method which returns the storage location.

    package My::Book;
    use Moo;
    
    # create a member for DBIx::Lite data
    has '_row' => (is => 'ro', default => sub { {} });
    
    package main;
    $dbix->schema->table('books')->class('My::Book', 'new', '_row');

=item C<$inflator> is an object method to be called after the object was created and 
DBIx::Lite has stored its data. You might need to define such a method if you want to 

=back

=head2 resultset_class

This method accepts a package name that DBIx::Lite will use for this table's 
ResultSet objects. You don't need to declare such package name anywhere else, as
DBIx::Lite will create that class for you.

    $dbix->schema->table('books')->resultset_class('My::Book::ResultSet');
    my $books_rs = $dbix->table('books')->search({ year => 2012 });
    # $books_rs is a My::Book::ResultSet

The class will subclass L<DBIx::Lite::ResultSet>. You can also supply an existing 
package name or declare your methods inline:

    $dbix->schema->table('books')->resultset_class('My::Book::ResultSet');
    
    sub My::Book::ResultSet::get_multilanguage {
        my $self = shift;
        return $self->search({ multilanguage => 1 });
    }

=for Pod::Coverage new

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
