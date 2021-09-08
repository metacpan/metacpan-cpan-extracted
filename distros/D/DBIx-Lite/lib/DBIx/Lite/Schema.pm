package DBIx::Lite::Schema;
$DBIx::Lite::Schema::VERSION = '0.33';
use strict;
use warnings;

use Carp qw(croak);
use DBIx::Lite::Schema::Table;
$Carp::Internal{$_}++ for __PACKAGE__;

sub new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        tables => {},
    };
    
    if (my $tables = delete $params{tables}) {
        foreach my $table_name (keys %$tables) {
            $tables->{$table_name}{name} = $table_name;
            $self->{tables}{$table_name} = DBIx::Lite::Schema::Table->new($tables->{$table_name});
        }
    }
    
    !%params
        or croak "Unknown options: " . join(', ', keys %params);
    
    bless $self, $class;
    $self;
}

sub table {
    my $self = shift;
    my $table_name = shift;
    $self->{tables}{$table_name} ||= DBIx::Lite::Schema::Table->new(name => $table_name);
    return $self->{tables}{$table_name};
}

sub one_to_many {
    my $self = shift;
    my ($from, $to, $accessors) = @_;
    
    $from && $from =~ /^(.+)\.(.+)$/
        or croak "Relationship keys must be defined in table.column format";
    my $from_table = $self->table($1);
    my $from_key = $2;
    
    $to && $to =~ /^(.+)\.(.+)$/
        or croak "Relationship keys must be defined in table.column format";
    my $to_table = $self->table($1);
    my $to_key = $2;
    
    my $from_table_accessor = $to_table->{name};
    my $to_table_accessor;
    if ($accessors) {
        if (ref $accessors eq 'ARRAY') {
            ($from_table_accessor, $to_table_accessor) = @$accessors;
        } else {
            $to_table_accessor = $accessors;
        }
    }
    
    $from_table->{has_many}{ $from_table_accessor } = [ $to_table->{name}, { $from_key => $to_key } ];
    $to_table->{has_one}{ $to_table_accessor } = [ $from_table->{name}, { $to_key => $from_key } ]
        if $to_table_accessor;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Lite::Schema

=head1 VERSION

version 0.33

=head1 OVERVIEW

This class holds the very loose schema definitions that enable some advanced
features of L<DBIx::Lite>. Note that you can do all main operations, including
searches and manipulations, with no need to define any schema.

An empty DBIx::Lite::Schema is created every time you create a L<DBIx::Lite>
object. Then you can access it to customize it. Otherwise, you can prepare a 
Schema object and reutilize it across multiple connections:

    my $schema = DBIx::Lite::Schema->new;
    my $conn1 = DBIx::Lite->new(schema => $schema)->connect(...);
    my $conn2 = DBIx::Lite->new(schema => $schema)->connect(...);

=head2 new

The constructor takes no arguments.

=head2 table

This method accepts a table name and returs the L<DBIx::Lite::Schema::Table>
object corresponding to the requested table. You can then call methods on it.

    $schema->table('books')->autopk('id');

=head2 one_to_many

This methods sets up a 1-to-N relationship between two tables. Just pass two
table names to it, appending the relation key column name:

    $schema->one_to_many('authors.id' => 'books.author_id');

This will have the following effects:

=over 4

=item provide a C<books> accessor method in the authors Result objects

=item provide a C<books> accessor method in the authors ResultSet objects

=item allow to call C<<$author->insert_related('books', {...})>>

=back

If you supply a third argument, it will be used to set up the reverse accessor
method. For example this will install a C<author> accessor method in the I<books>
Result objects:

    $schema->one_to_many('authors.id' => 'books.author_id', 'author');

If you also want to customize the accessor for the first table, you can supply 
an arrayref with both accessor names. This can be needed when the second table
has two fields referencing the same table:

    $schema->one_to_many('authors.id' => 'books.author_id', [ 'books_as_author', 'author' ]);
    $schema->one_to_many('authors.id' => 'books.curator_id', [ 'books_as_curator', 'curator' ]);

Note that relationships can be chained:

    $dbix->schema->one_to_many('authors.id' => 'books.author_id');
    $dbix->schema->one_to_many('books.id' => 'chapters.books_id');
    my @chapters = $dbix
        ->table('authors')
        ->search({ country => 'IT' })
        ->books
        ->chapters
        ->search({ page_count => { '>' => 20 } })
        ->all;

You can use the same approach to traverse many-to-many relationships.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
