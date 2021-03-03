package Dancer2::Plugin::DBIx::Class 1.01;
use strict;
use warnings;
use Dancer2::Plugin;
use Carp;
use Class::C3::Componentised;
use Try::Tiny;

has schema_class => (
    is          => 'ro',
    from_config => 1,
);

has connect_info => (
    is      => 'rw',
    trigger => 'clear_schema',
    builder => sub {
        my ($self) = @_;
        my $config = $self->config;
        return [
            $config->{connect_info}
            ? @{ $config->{connect_info} }
            : @{$config}{qw(dsn user password options)}
        ];
    },
);

has schema => (
    is      => 'lazy',
    clearer => 1,
    builder => sub {
        my ($self) = @_;
        $self->_ensure_schema_class_loaded->connect(
            @{ $self->connect_info } );
    },
);

has export_prefix => (
    is        => 'ro',
    predicate => 1,
    builder   => sub {
        my ($self) = @_;
        my $config = $self->config;
        return $config->{export_prefix};
    },
);

sub _maybe_prefix_method {
    my ( $self, $method ) = @_;
    return $method unless $self->export_prefix;
    return join( '_', $self->export_prefix, $method );
}

has _export_schema_methods => (
    is      => 'ro',
    default => sub { [] },
);

sub _rs_name_methods {
    my ($self) = @_;
    my $class = $self->_ensure_schema_class_loaded;
    return () unless $class->can('resultset_name_methods');
    sort keys %{ $class->resultset_name_methods };
}

sub _ensure_schema_class_loaded {
    croak 'No schema class defined' if !$_[0]->schema_class;
    eval {
        Class::C3::Componentised->ensure_class_loaded( $_[0]->schema_class );
        1;
    }
        or croak 'Schema class ' . $_[0]->schema_class . ' unable to load';
    return $_[0]->schema_class;
}

sub rs {
    my ( $self, $rs ) = @_;
    my $schema = $self->schema;
    return $schema->resultset($rs);
}

sub BUILD {
    my ($self) = @_;
    $self->_ensure_schema_class_loaded;
    my $call_rs = sub { shift->schema->resultset(@_) };
    my %kw;
    $kw{'rs'}        = $call_rs;
    $kw{'rset'}      = $call_rs;
    $kw{'resultset'} = $call_rs;
    $kw{'schema'}    = sub { shift->schema(@_) };
    my @export_methods
        = ( $self->_rs_name_methods, @{ $self->_export_schema_methods } );

    foreach my $exported_method (@export_methods) {
        $kw{ $self->_maybe_prefix_method($exported_method) } = sub {
            shift->schema->$exported_method(@_);
        };
    }
    @{ $self->keywords }{ keys %kw } = values %kw;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::DBIx::Class - syntactic sugar for DBIx::Class in Dancer2, optionally with DBIx::Class::Schema::ResultSetNames

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    # In your Dancer2 app, without DBIx::Class::Schema::ResultSetNames
    # (but why would you?)
       my $results = resultset('Human')->search( { . . .} );
    #
    # or, with DBIx::Class::Schema::ResultSetNames
       my $results = humans->search( { . . . } );
       my $single_person = human($human_id);

=head1 DESCRIPTION

Dancer2::Plugin::DBIx::Class adds convenience keywords to the DSL for L<Dancer2>, in order to make
database calls more semantically-friendly.

=head1 CONFIGURATION

The configuration for this plugin can go in your config.yml, or in your environment:

    plugins:
      DBIC:
        dsn: dbi:SQLite:dbname=my.db    # Just about any DBI-compatible DSN goes here
        schema_class: MyApp::Schema
        export_prefix: 'db_'            # Optional, unless a table name (singular or plural)
                                        # is also a DSL keyword.

=head1 YOU HAVE BEEN WARNED

The "optional" C<export_prefix> configuration adds the given prefix to the ResultSet names, if you
are using L<DBIx::Class::Schema::ResultSetNames>. It is wise to do this, if you have table names
that collide with other L<Dancer2::Core::DSL> keywords, or those added by other plugins.  It is
likely that horrible, horrible things will happen to your app if you don't take care of this.
(C<session> is a good example--ask me know I know!)

=head1 FUNCTIONS

=head2 schema

This keyword returns the related L<DBIx::Class::Schema> object, ready for use.

=head2 resultset, rset, rs

These three keywords are syntactically identical, and, given a name of a L<DBIx::Class::ResultSet>
object, will return the resultset, ready for searching, or any other method you can use on a ResultSet:

    my $cars = rs('Car')->search({ . . .});

=head1 NAMED RESULT SETS

L<DBIx::Class::Schema::ResultSetNames> adds both singular and plural method accessors for all resultsets.

So, instead of this:

    my $result_set = resultset('Author')->search({...});

you may choose to this:

    my $result_set = authors->search({...});

And instead of this:

    my $result = resultset('Author')->find($id);

you may choose to this:

    my $result = author($id)

The usual caveats apply to C<find()> returning multiple records; that behavior is deprecated, so if you
try to do something like:

    my $result = author( { first_name => 'John'} );

...odds are things will blow up in your face a lot.  Using a unique key in C<find()> is important.

=head1 BUT THAT'S NOT ALL!

If you combine this module, L<DBIx::Class::Schema::ResultSetNames>, and L<DBIx::Class::Helper::ResultSet::Shortcut>,
you can do some really fabulous, easy-to-read things in a L<Dancer2> route, like:

   # find all the books for an author, give me an array of
   #    their books as Row objects, with the editions prefetched.
   #
   my @books = author($id)->books->prefetch('edition')->all 
   
   # send a JSON-encoded list of hashrefs of authors with first names
   #    that start with 'John' and their works to your front-end framework
   #    (Some, like DevExtreme, do not cope well with the objects.)
   #
   send_as JSON => [ authors->like( 'first_name', 'John%')->prefetch('books')->hri->all ];

There are many really snazzy things to be found in L<DBIx::Class::Helpers>. Many of them can make
your code much more readable. Definitely worth a look-see.

Remember: your code has two developers: you, and you six months from now.

Remember also: You should write your code like the next developer to work on it is
a psychopath who knows where you live. 

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::ResultSet>

=item *

L<DBIx::Class::Schema::ResultSetNames>

=item *

L<DBIx::Class::Schema>

=back

=head1 CREDIT WHERE CREDIT IS DUE

Practically all of this code is the work of L<Matt S Trout (mst)|https://metacpan.org/author/MSTROUT>.
I just tidied things up and wrote documentation.

=head1 SOURCE

L<https://gitlab.com/geekruthie/Dancer2-Plugin-DBIx-Class>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dancer2-Plugin-DBIx-Classs>

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: syntactic sugar for DBIx::Class in Dancer2, optionally with DBIx::Class::Schema::ResultSetNames


