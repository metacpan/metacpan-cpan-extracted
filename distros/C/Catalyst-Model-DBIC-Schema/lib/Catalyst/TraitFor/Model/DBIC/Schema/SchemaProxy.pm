package Catalyst::TraitFor::Model::DBIC::Schema::SchemaProxy;

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use Catalyst::Model::DBIC::Schema::Types 'Schema';

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::SchemaProxy - Proxy Schema Methods and
Options from Model

=head1 DESCRIPTION

Allows you to call your L<DBIx::Class::Schema> methods directly on the Model
instance, and passes config options to your L<DBIx::Class::Schema> and
L<DBIx::Class::ResultSet> attributes at C<BUILD> time.

Methods and attributes local to your C<Model> take precedence over
L<DBIx::Class::Schema> or L<DBIx::Class::ResultSet> methods and attributes.

=head1 CREATING SCHEMA CONFIG ATTRIBUTES

To create attributes in your C<Schema.pm>, use either Moose or
L<Class::Accessor::Grouped>, which is inherited from by all L<DBIx::Class>
classes automatically. E.g.:

    __PACKAGE__->mk_group_accessors(simple => qw/
        config_key1
        config_key2
        ...
    /);

Or with L<Moose>:

    use Moose;
    has config_key1 => (is => 'rw', default => 'default_value');

This code can be added after the md5sum on L<DBIx::Class::Schema::Loader>
generated schemas.

At app startup, any non-local options will be passed to these accessors, and can
be accessed as usual via C<< $schema->config_key1 >>.

These config values go into your C<Model::DB> block, along with normal config
values.

=head1 CREATING RESULTSET CONFIG ATTRIBUTES

You can create classdata on L<DBIx::Class::ResultSet> classes to hold values
from L<Catalyst> config.

The code for this looks something like this:

    package MySchema::ResultSet::Foo;

    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->mk_group_accessors(inherited => qw/
        rs_config_key1
        rs_config_key2
        ...
    /);
    __PACKAGE__->rs_config_key1('default_value');

Or, if you prefer L<Moose>:

    package MySchema::ResultSet::Foo;

    use Moose;
    use MooseX::NonMoose;
    use MooseX::ClassAttribute;
    extends 'DBIx::Class::ResultSet';

    sub BUILDARGS { $_[2] } # important

    class_has rs_config_key1 => (is => 'rw', default => 'default_value');

    ...

    __PACKAGE__->meta->make_immutable;

    1;

In your catalyst config, use the generated Model name as the config key, e.g.:

    <Model::DB::Users>
        strict_passwords 1
    </Model::DB::Users>

=cut

after setup => sub {
    my ($self, $args) = @_;

    my $schema = $self->schema;

    my $was_mutable = $self->meta->is_mutable;

    $self->meta->make_mutable;
    $self->meta->add_attribute('schema',
        is => 'rw',
        isa => Schema,
        handles => $self->_delegates # this removes the attribute too
    );
    $self->meta->make_immutable unless $was_mutable;

    $self->schema($schema) if $schema;
};

after BUILD => sub {
    my ($self, $args) = @_;

    $self->_pass_options_to_schema($args);

    for my $source ($self->schema->sources) {
        my $config_key = 'Model::' . $self->model_name . '::' . $source;
        my $config = $self->app_class->config->{$config_key};
        next unless $config;
        $self->_pass_options_to_resultset($source, $config);
    }
};

sub _delegates {
    my $self = shift;

    my $schema_meta = Class::MOP::Class->initialize($self->schema_class);
    my @schema_methods = $schema_meta->get_all_method_names;

# combine with any already added by other schemas
    my @handles = eval {
        @{ $self->meta->find_attribute_by_name('schema')->handles }
    };

# now kill the attribute, otherwise add_attribute in BUILD will not do the right
# thing (it clears the handles for some reason.) May be a Moose bug.
    eval { $self->meta->remove_attribute('schema') };

    my %schema_methods;
    @schema_methods{ @schema_methods, @handles } = ();
    @schema_methods = keys %schema_methods;

    my @my_methods = $self->meta->get_all_method_names;
    my %my_methods;
    @my_methods{@my_methods} = ();

    my @delegates;
    for my $method (@schema_methods) {
        push @delegates, $method unless exists $my_methods{$method};
    }

    return \@delegates;
}

sub _pass_options_to_schema {
    my ($self, $args) = @_;

    my @attributes = map {
        $_->init_arg || ()
    } $self->meta->get_all_attributes;

    my %attributes;
    @attributes{@attributes} = ();

    for my $opt (keys %$args) {
        if (not exists $attributes{$opt}) {
            next unless $self->schema->can($opt);
            $self->schema->$opt($args->{$opt});
        }
    }
}

sub _pass_options_to_resultset {
    my ($self, $source, $args) = @_;

    for my $opt (keys %$args) {
        my $rs_class = $self->schema->source($source)->resultset_class;
        next unless $rs_class->can($opt);
        $rs_class->$opt($args->{$opt});
    }
}

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<DBIx::Class::Schema>

=head1 AUTHOR

See L<Catalyst::Model::DBIC::Schema/AUTHOR> and
L<Catalyst::Model::DBIC::Schema/CONTRIBUTORS>.

=head1 COPYRIGHT

See L<Catalyst::Model::DBIC::Schema/COPYRIGHT>.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
