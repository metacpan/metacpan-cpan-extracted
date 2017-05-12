package DBICx::Modeler;

use warnings;
use strict;

=head1 NAME

DBICx::Modeler - A Moose-based model layer over DBIx::Class

=head1 VERSION

Version 0.005

=cut

our $VERSION = '0.005';

=head1 SYNOPSIS

    # Given the following schema:

    My::Schema::Artist
    My::Schema::Cd
    My::Schema::Track

    # ... and the following model:

    My::Model::Artist

    use DBICx::Modeler::Model

    My::Model::Cd ...
    My::Model::Track ...

    ...

    my $modeler = DBICx::Modeler->new( schema => ..., namespace => My::Model );

    my $artist = $modeler->create( Artist => { ... } ) # $artist is My::Model::Artist

    my $cd = $artist->create_related( cds => { ... } ) # $cd is My::Model::Cd

    ...

    my $search = $artist->cds( { title => ... } ) # Start a search ...
    $search->search( { ... } ) # Refine the search ...
    my @cds = $search->slice( 0, 9 ) # Get the first 10     
                                     # Each is of type My::Model::Cd

=head1 DESCRIPTION

DBICx::Modeler is tool for making a thin, Moose-based model layer over a DBIx::Class schema

=head1 CAVEAT EMPTOR

=head2 Many-to-many is not handled

Many-to-many relationships are ignored, for now. You'll have to access C<_model__storage> (which is the DBIx::Class::Row) if you want
to play with them

=head2 The same storage object can be present in different model objects

    # With the following example:
    $artist->cds( ... )->slice( 0 )->artist # $artist and ->artist are different objects

This shouldn't be too difficult to fix.

=head2 The modeler will probably barf when trying to modify  immutable Model:: classes

This shouldn't be too difficult to fix, either.

=head2 Use C<DBIC_MODELER> to trace modeler setup

Set C<DBIC_MODELER> to 1 if you want to trace what is going on in the modeler internally

    $ENV{DBIC_MODELER} = 1

=head1 METHODS

DBICx::Modeler->new( ... )

    schema          The connected DBIx::Class schema to use/inspect

    namespace       The package containing the Moose classes that will mimic the class structure of <schema>

$modeler->model( <moniker> )

    Return the model source for <moniker>

$modeler->create( <moniker> => ... )

    Create a new row for <moniker> and return the modeled object

$modeler->search( <moniker> => ... )

    Make a search of <moniker> that will inflate into modeled objects

=cut

use Moose;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

use Class::Inspector();
use Scalar::Util qw/weaken/;

use DBICx::Modeler::Model::Source;

#########
# Class #
#########

sub ensure_class_loaded {
    shift;
    my $class = shift;
    return $class if Class::Inspector->loaded( $class );
    eval "require $class;";
    die "Couldn't load class $class: $@" if $@;
    return $class;
}

sub _expand_relative_name {
    my ($self, $name) = @_;
    my $class = ref $self || $self;

    return unless $name;

    my $parent_class = $class;

    if ($name =~ s/^\+//) {
        # Hammatime: Don't touch this!
    }
    else {
        if ($name =~ s/^\-//) {
            # User wants the parent (wants to be a sibling)
            my @class = split m/::/, $parent_class;
            pop @class;
            $parent_class = join '::', @class;
        }
        $name = $parent_class . '::' . $name;
    }
    return $name;
}

###########
# Object ##
###########

has schema => qw/is ro required 1/;
has schema_class => qw/is ro lazy_build 1/;

has [qw/
    namespace
    skip_moniker
/] => qw/is rw/;

has [qw/
    create_refresh
    sibling_namespace
/] => qw/is rw default 1/;

has skip_schema_modeler_accessor => qw/is rw default 0/;
has [qw/ _model_source_list /] => qw/is ro required 1 lazy 1 isa ArrayRef/, default => sub { [] };
has [qw/ _namespace_list /] => qw/is ro lazy_build 1 isa ArrayRef/;
sub _build__namespace_list {
    my $self = shift;
    my $class = ref $self || $self;

    my $default_namespace = do {
        my @default = split m/::/, $class;
        if ( my $name = $self->sibling_namespace ) {
            $name = "Model" if $name eq 1;
            pop @default; # Use Example::${name} instead of Example::Modeler::${name} (e.g. Example::Model)
            push @default, $name;
        }
        "+" . join "::", @default;
    };

    my $namespace = $self->namespace;
    $namespace = [] unless defined $namespace;
    $namespace = [ $namespace ] unless ref $namespace eq "ARRAY";
    unless (@$namespace) {
        croak "You didn't specify a namespace" if $class eq __PACKAGE__;
        @$namespace = ("?"); # Use the default namespace if none specified
    }
    @$namespace = map { $_ eq "?" ? $default_namespace : $_ } @$namespace;

    $_ = $self->_expand_relative_name( $_ ) for @$namespace;

    return [ @$namespace ];
}
has [qw/
    _model_source_lookup_map
    _model_class_by_moniker_map
    _moniker_by_model_class_map
/] => qw/is ro required 1 lazy 1 isa HashRef/, default => sub { {} };

sub _build_schema_class {
    my $self = shift;
    return ref $self->schema;
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->skip_moniker( $given->{skip} ) if ! exists $given->{skip_moniker} && $given->{skip};

    my $schema = $self->schema;
    my $schema_class = $self->schema_class;

    $self->_setup_schema_modeler_accessor unless $self->skip_schema_modeler_accessor;
    $self->_setup_base_model_sources;
    {
        $self->schema->modeler( $self );
        weaken $self->schema->{modeler};
    }

    return 1;
}

sub _setup_schema_modeler_accessor {
    my $self = shift;
    return if $self->schema_class->can( qw/modeler/ );
    $self->schema_class->mk_group_accessors( simple => qw/modeler/ );
}

sub _setup_base_model_sources {
    my $self = shift;
    my %option = @_;

    for my $moniker ($self->schema->sources) {
        my $model_class = $self->model_class_by_moniker( $moniker ); # Initialize base model classes & moniker_by_model_class/model_class_by_moniker
        my $model_source = DBICx::Modeler::Model::Source->new(
            moniker => $moniker,
            modeler => $self,
            schema => $self->schema,
            model_class => $model_class,
        );
        $model_class->_model__meta->initialize_base_model_class( $model_source );
        $self->_register_model_source( $model_source );
    }
}

sub namespaces {
    my $self = shift;
    return @{ $self->_namespace_list }
}

sub moniker_by_model_class {
    my $self = shift;
    my $model_class = shift;

    return $self->model_source_by_model_class( $model_class )->moniker;
#    croak "Couldn't find moniker for (model class) $model_class" unless $moniker;
}

sub find_model_class {
    my $self = shift;
    my $query = shift;

    if ($query =~ s/^\+//) {
        return $self->ensure_class_loaded( $query );
    }

    # A relative class... 'moniker'
    return $self->model_class_by_moniker( $query );
}

sub model_class_by_moniker {
    my $self = shift;
    my $moniker = shift;

    # Has to be done this way, because the model source might not be loaded yet

    my $model_class = $self->_model_class_by_moniker_map->{$moniker};
    return $model_class if $model_class;

    for my $namespace ( $self->namespaces ) {
        my $potential_model_class = "${namespace}::${moniker}";

        if (Class::Inspector->loaded( $potential_model_class )) {
        }
        else {
            eval "require $potential_model_class;";
            if ($@) {
                my $file = join '/', split '::', $potential_model_class;
                if ($@ =~ m/^Can't locate $file/) {
                    TRACE->( "[$self] Unable to load file ($file) for $potential_model_class" );
                    next;
                }
                else {
                    die "Couldn't load class $potential_model_class for $moniker: $@" if $@;
                }
            }
        }
        $model_class = $potential_model_class;
        last; # We found something!
    }

    croak "Couldn't find model class for (moniker) $moniker" unless $model_class;

    $self->_moniker_by_model_class_map->{$model_class} = $moniker;
    return $self->_model_class_by_moniker_map->{$moniker} = $model_class;
}

sub model_class_by_result_class {
    my $self = shift;
    my $result_class = shift;
    my $moniker = $self->schema_class->source( $result_class )->source_name;
    return $self->model_class_by_moniker( $moniker );
}

sub model_sources {
    my $self = shift;
    return @{ $self->_model_source_list };
}

sub _model_source {
    my $self = shift;
    my $model_source = shift;

    $model_source = $self->_model_source_lookup_map->{$model_source} while defined $model_source && ! ref $model_source;

    return $model_source;
}

sub model_source {
    my $self = shift;
    my $model_source = shift;
    return $self->_model_source( $model_source ) or croak "Couldn't find model source with key $model_source";
}

sub model {
    my $self = shift;
    return $self->model_source( @_ );
}

sub model_source_by_moniker {
    my $self = shift;
    my $moniker = shift;
    my $model_source = $self->_model_source( "::${moniker}" ) or
        croak "Couldn't find model source for (moniker) $moniker";
    return $model_source;
}

sub model_source_by_model_class {
    my $self = shift;
    my $model_class = shift;

    my $model_source = $self->_model_source( "+${model_class}" );

    return $model_source if $model_source;
    
    TRACE->( "[$self] Building model source for $model_class" );
    # The model class might not have been loaded yet
    $self->ensure_class_loaded( $model_class );

    die "Can't get model source for $model_class since it doesn't have a model meta" unless $model_class->can( '_model__meta' );

    my $parent_model_meta = $model_class->_model__meta->parent;

    die "Strange, model source for $model_class doesn't exist, but it doesn't have a parent" unless $parent_model_meta;

    my $parent_model_class = $parent_model_meta->model_class;
    my $parent_model_source = $self->model_source_by_model_class( $parent_model_class );

    $model_source = $parent_model_source->clone( model_class => $model_class );
    
    $self->_register_model_source( $model_source );

    return $model_source;
}

sub _register_model_source {
    my $self = shift;
    my $model_source = shift;
    push @{ $self->_model_source_list }, $model_source;

    my $moniker = $model_source->moniker;
    my $moniker_key = "::${moniker}";
    my $model_class = $model_source->model_class;
    my $model_class_key = "+${model_class}";

    $self->_model_source_lookup_map->{$model_class_key} = $model_source;

    $self->_model_source_lookup_map->{$model_class} = $model_class_key;
    $self->_model_source_lookup_map->{$moniker} = $model_class_key;
    $self->_model_source_lookup_map->{$moniker_key} = $model_class_key;
    # TODO Add more aliasing
}

sub create {
    my $self = shift;
    my $key = shift;
    return $self->model_source( $key )->create( @_ );
}

sub inflate {
    my $self = shift;
    my $key = shift;
    return $self->model_source( $key )->inflate( @_ );
}

sub search {
    my $self = shift;
    my $key = shift;
    return $self->model_source( $key )->search( @_ );
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbicx-modeler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBICx-Modeler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBICx::Modeler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBICx-Modeler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBICx-Modeler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBICx-Modeler>

=item * Search CPAN

L<http://search.cpan.org/dist/DBICx-Modeler/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBICx::Modeler
