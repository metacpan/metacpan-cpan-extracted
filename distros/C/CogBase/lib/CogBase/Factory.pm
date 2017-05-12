package CogBase::Factory;
use strict;
use warnings;
use CogBase::Base -base;

field 'connection';

sub new_node {
    my ($self, $type) = @_;
    die "'$type' is invalid type"
        unless $type =~ /^
            (
                Schema
            |
                [[:lower:]]
                [_[:word:]]+
            )
        $/xo;
    $self->require_node_class($type);
    my $class = "CogBase::$type";
    return $class->New(Type => $type);
}

sub require_node_class {
    my ($self, $type) = @_;
    my $class = "CogBase::$type";
    return if $class->can('New');
    eval "require $class";
    return if $class->can('New');
    $self->generate_class($type);
    return if $class->can('New');
    die "Can't create node of unknown type '$type'";
}

sub generate_class {
    require YAML::Syck;
    my ($self, $type) = @_;
    my $schema_node = $self->connection->fetchSchemaNode($type);

    my $hash = eval { YAML::Syck::Load($schema_node->value) };
    die "Schema has invalid YAML: $@" if $@;

    eval <<"...";
# $schema_node->{Id}
package CogBase::$hash->{'+'};
use strict;
use CogBase::$hash->{'<'} -base;
${ \ $self->format_fields($hash) }
1;
...
}

sub format_fields {
    my ($self, $hash) = @_;
    my $output = '';
    for my $field (keys %$hash) {
        next unless $field =~ /^\w/;
        $output .= "field '$field';\n";
    }
    return $output;
}

1;
