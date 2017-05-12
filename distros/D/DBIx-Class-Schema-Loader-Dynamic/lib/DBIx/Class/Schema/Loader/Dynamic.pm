package DBIx::Class::Schema::Loader::Dynamic;

use strict;
use warnings;

use base qw/DBIx::Class::Schema::Loader::DBI/;
use mro 'c3';
use Data::Dumper;

our $VERSION = '1.05';

sub new {
    my ($self, %args) = @_;
    my $class = ref $self || $self;

    $args{dump_directory}    ||= '/die/if/I/get/used';
    $args{left_base_classes} ||= ['DBIx::Class::Core'];

    my $new = $self->next::method(%args);

    # The loader 'factory' returns a more engine-specific subclass, e.g. DBIC:S:L::DBI::Pg.  So,
    # I'll have what she's having..
    {
        my $isa = $class . "::ISA";
        no strict 'refs'; @$isa = (ref $new);
    }

    eval("require $_") || die for @{$new->left_base_classes};
    bless $new, $class;
}

sub _load_tables {
    my ($self, @tables) = @_;

    # Save the new tables to the tables list and compute monikers
    foreach (@tables) {
        $self->_tables->{$_->sql_name}  = $_;
        $self->monikers->{$_->sql_name} = $self->_table2moniker($_);
    }

    # "check for moniker clashes": NEED TO FACTOR OUT THIS ALGORITHM FROM ::Base.  leave it out for now.

    $self->_make_src_class($_) for @tables;
    $self->_setup_src_meta($_) for @tables;

    # Here's the "Rinse-and-Repeat" Catch-22 that causes so much dbics::loader agony:
    # - 'register_class' freezes what we know about the class so far.  
    # - relationships cannot be dynamically added until classes are registered.
    # Solution: register all classes while still unrelated, then build relationships, then wipe-and-reregister.

    for my $table (@tables) {
        my $moniker = $self->monikers->{$table->sql_name};
        my $class = $self->classes->{$table->sql_name};
        $self->schema->register_class($moniker=>$class);
    }

    $self->_load_relationships(\@tables);

    # load user-defined customisations as 'mix-ins' if present.
    for my $class (sort values %{$self->classes}) {
        if (eval "require $class") {
            printf STDERR "$class customisations loaded\n" if $self->debug;
            next
        }
        my $err = $@;
        next if $err =~ /Can't locate/; # It's not a sin..
        printf STDERR "WARNING errors loading customisations for $class.. %s\n", $err;
    }

    # rinse and repeat..
    $self->schema->source_registrations({});
    for my $table (@tables) {
        my $moniker = $self->monikers->{$table->sql_name};
        my $class = $self->classes->{$table->sql_name};
        $self->schema->register_class($moniker=>$class);
    }

    # all table meta-data including relationships are now has fully 'registered'.
    return \@tables;
}

# Override existing Loader::Base actions to actually run code rather than generate it..

sub _dbic_stmt {
    my ($self, $class, $method, @args) = @_;
    printf STDERR "DBIC_STMT %s ( %s )\n", "$class->$method(@args);", Dumper(\@args) if $self->debug;
    $class->$method(@args);
}

sub _inject {
    my ($self, $class, @parents) = @_;
    return unless @parents;
    my $isa = "$class\::ISA";
    no strict 'refs';
    unshift @$isa, @parents;
}

sub _base_class_pod {}
sub _make_pod {}
sub _make_pod_heading {}
sub _pod {}
sub _pod_class_list {}
sub _pod_cut {}
sub _use {}

1;

__END__

=head1 NAME

DBIx::Class::Schema::Loader::Dynamic -- Really Dynamic Schema Generation for DBIx::Class

=head1 SYNOPSIS

    # MySchema.pm
    package MySchema;

    use strict;
    use warnings;

    use base 'DBIx::Class::Schema';
    use       DBIx::Class::Schema::Loader::Dynamic;

    sub connect_info { [ 'dbi:Pg:dbname="my_db, 'uid', 'pwd' ] }

    sub setup {
        my $class = shift;
        my $schema = $class->connection(@{$class->connect_info});

        DBIx::Class::Schema::Loader::Dynamic->new(
            left_base_classes => 'MySchemaDB::Row',
            naming            => 'v8',
            use_namespaces    => 0,
            schema            => $schema,
        )->load;
        return $schema;
    }
    1;


    # MySchema/Row.pm
    package MySchema::Row;
    use strict;
    use warnings;
    use base 'DBIx::Class::Core';
    __PACKAGE__->load_components('InflateColumn::DateTime');
    sub hello { 'everybody gets me' }
    1;


    # Now, assuming the usual 'Music' sample database..

    # MySchema/Artist.pm
    package MySchema::Artist;
    use strict;
    use warnings;
    sub hello { 'nobody gets me but me' }
    1;

    # finally, somewhere in my application
    use MySchema;
    my $schema = MySchema->setup;

    # All table classes are now active.  They are based on MySchema::Row.

    my $artist = $schema->resultset('Artist')->first;
    my $cd     = $artist->cds()->first;
    printf "%s but %s\n", $cd->hello, $artist->hello

=head1 DESCRIPTION

L<DBIx::Class::Schema::Loader::Dynamic> is a faster and simpler driver for the
dynamic schema generation feature of L<DBIx::Class::Schema::Loader>.   

It will make Perl classes for each table spring into existence and it runs the declarative
statements (such as add_columns, has_many, ..) immediately at catalog discovery time,
rather than code-generating Perl modules and then 'use'-ing those modules multiple times.

Manual customisation of table definition code is still achieved by B<optionally> writing user-defined classes,
which act as 'mix-ins' as expected by L<load_classes in DBIx::Class::Schema|DBIx::Class::Schema/load_classes>
(except that you don't actually have to call load_classes).

If you want to generate static database definition code from your database, this module is not for you.

=head1 REASON

=head2 Design Goal

I consider dynamic schema discovery to have advantages over code-generation, especially as applied to agile techniques,
software release management, database schema version management, and continuous delivery.

A useful design goal for application development in a continuous-integration environment is to insist that adding/removing
tables, columns, or relationships, can be done B<without requiring any change to the code> (except for removing references to
dropped objects of course).  If this goal is maintained then most of the pain and bureaucracy of schema version control goes away.

This module allows you to achieve that goal and still use the excellent L<DBIx::Class> ORM.

=head2 Implementation

L<DBIx::Class::Schema::Loader> already does outstanding work in catalog-discovery for many database products and in
mapping names to the object model.  We want to inherit this (literally), so we do.  However to activate the results,
even in 'dynamic' mode, the standard ::Loader uses a complex code-generation approach which generates Perl code
to a temporary directory and then requires (pun intended) abstract Perl class manipulation to enable this code.
Multiple passes are done in order to support relationship-discovery.  It's fragile and cumbersome, and 
introduces a lot of Dark Code to the start of every production program, hence 'not recommended'.

This module enables a direct 'live' approach, as distinct from hidden-code-generation. 
It's faster, it removes a lot of Dark Code from production, and it's more familiar
to users of Class::DBI::Loader and some other language ORMs.

=head1 LIMITATIONS

=head2 Loader Options

We expect most of the loader_options for DBIx::Class::Schema::Loader to be valid, but not all variations
can be tested.  In particular, all tests to date have been with C<< use_namespaces=>0 >> and C<< naming=>'v8' >>.

=head2 Base 'Row' Class

As shown in the Synopsis code under 'C<MySchema::Row>' you B<really do> want to manually create a base row class 
and nominate it in L<left_base_classes|DBIx::Class::Schema::Loader::Base/left_base_classes> in the loader options.

This gives you one place to declare things like the ubiquitous C<load_components('InflateColumn::DateTime')>
and to add/override other methods you wish to be inherited by all table classes in your object model.
Make sure your base row class inherits from L<DBIx::Class::Core>.  

You can leave out C<left_base_classes>, in which case it will be defaulted automatically to L<DBIx::Class::Core>.

=head2 Moniker Clash Logic removed

Vanilla L<DBIx::Class::Loader> includes logic that checks for duplicates in the classnames generated for table names.
That logic is removed in this release.  Workaround: don't run this on a connect string that yields duplicate table names.

=head2 Private methods overriden

This module overrides some private methods (i.e. whose names =~ /^_\w+/) of L<DBIx::Class::Schema::Loader::Base>.
Ideally that module could be refactored to make these overrides more future-proof.  I'll ask.

=head1 METHODS

You don't need to keep the C<$loader> object after running C<< load >>.

But if you do, then after 'setup' (for a Postgres database), 

B<DBIx::Class::Schema::Loader::Dynamic> inherits all methods from

L<DBIx::Class::Schema::Loader::DBI::Pg> (*) which inherits all methods from

L<DBIx::Class::Schema::Loader::DBI::Component::QuotedDefault> which inherits all methods from

L<DBIx::Class::Schema::Loader::DBI> which inherits all methods from

L<DBIx::Class::Schema::Loader::DBI::Base> which inherits all methods from

L<Class::Accessor::Grouped> and L<Class::C3::Componentised>.

(*or your engine-specific DBIx::Class::Schema::Loader::DBI::<subclass>)

.. but implements no new ones.  Note that L<DBIx::Class::Schema> itself is kept out of the inheritance chain, at all times.

=head1 CONNECTION HANDLING

In the Synopsis, the handling of the connect string and the introduction of a 'setup' method is just a suggestion.  TMTOWTDI.  
Our suggestion allows a schema 'MySchema' itself to be sub-classed if required, with the opportunity to override the 
connect-string or the loader options.

Being standard L<DBIx::Class:Schema> functionality, note the $schema handle will be just the literal class name
(returned when you call C<connection>) or a true schema instance object ref (returned when you call C<connect>).
See L<connect in DBIX::Schema::Class|DBIx::Class::Schema/connect>.

=head1 DEBUGGING

To trace the declarative DBIx::Class statements that are being run, set C<< debug=>1 >> among the loader options.

=head1 REPOSITORY

Open-Sourced at Github: L<https://github.com/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic>.  Please post issues there.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Frank Carnovale <frankc@cpan.org>

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<DBIx::Class::Schema>, L<DBIx::Class::Schema::Loader>

=cut
