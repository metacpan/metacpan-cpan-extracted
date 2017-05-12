package Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema;

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

with 'Catalyst::Component::InstancePerContext';

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema - Clone the schema
with attributes for each requests

=head1 SYNOPSIS

    __PACKAGE__->config({
        traits => ['PerRequestSchema'],
    });

    sub per_request_schema_attributes {
        my ($self, $c) = @_;
        return (restricting_object => $c->user->obj);
    }
    ### OR ###
    sub per_request_schema {
        my ($self, $c) = @_;
        return $self->schema->schema_method($c->user->obj)
    }
    

=head1 DESCRIPTION

Clones the schema for each new request with the attributes retrieved from your
C<per_request_schema_attributes> method, which you must implement. This method
is passed the context.

Alternatively, you could also override the C<per_request_schema> method if you
need access to the schema clone and/or need to separate out the Model/Schema
methods.  (See examples above and the defaults in the code.)

=cut

sub build_per_context_instance {
    my ( $self, $ctx ) = @_;
    return $self unless blessed($ctx);

    my $new = bless {%$self}, ref $self;

    $new->schema($new->per_request_schema($ctx));

    return $new;
}

# Thanks to Matt Trout for this idea
sub per_request_schema {
    my ($self, $c) = @_;
    return $self->schema->clone($self->per_request_schema_attributes($c));
}

### TODO: This should probably be more elegant ###
sub per_request_schema_attributes {
   confess "Either per_request_schema_attributes needs to be created, or per_request_schema needs to be overridden!";
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
