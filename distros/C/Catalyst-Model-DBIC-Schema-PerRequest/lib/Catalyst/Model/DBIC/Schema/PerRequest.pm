package Catalyst::Model::DBIC::Schema::PerRequest;

# ABSTRACT: Per request clone of a DBIC model with additional parameters

use Moose;
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

use Carp qw(croak confess);
use Module::Runtime qw(use_module);

our $VERSION = '0.002002';



has target_model => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has schema_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#--------------------------------------------------------------------------#
# model_name
#--------------------------------------------------------------------------#

has model_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_model_name',
);

sub _build_model_name {
    my $self = shift;

    my $class = ref($self);
    (my $model_name = $class) =~ s/^[\w:]+::(?:Model|M):://;

    return $model_name;
}


#--------------------------------------------------------------------------#
# BUILD
#--------------------------------------------------------------------------#

our %subnamespaces;
sub BUILD {
    my ($self) = @_;

    unless ($subnamespaces{ ref($self) }) {
        $self->setup_subnamespaces;
        $subnamespaces{ ref($self) } = 1;
    }
}

#--------------------------------------------------------------------------#
# setup_subnamespaces
#--------------------------------------------------------------------------#

sub setup_subnamespaces {
    my ($self) = @_;

    my $model_name = $self->model_name;
    foreach my $source_name (use_module($self->schema_class)->sources) {
        no strict 'refs';
        *{ ref($self) . '::' . $source_name . '::ACCEPT_CONTEXT' } = sub {
            $_[1]->model($model_name)->schema->resultset($source_name);
        };
    }
}

#--------------------------------------------------------------------------#
# build_per_context_instance
#--------------------------------------------------------------------------#

sub build_per_context_instance {
    my ($self, $ctx) = @_;

    croak ref($self)
        . ' is a per-request only model, calling it on the app makes no sense.'
        unless blessed($ctx);

    my $target = $ctx->model($self->target_model);

    my $new = bless({%$target}, ref($target));

    $new->schema($self->per_request_schema($ctx, $new));

    return $new;
}


# Thanks to Matt Trout (mst) for this idea
sub per_request_schema {
    my ($self, $c, $original_model) = @_;

    return $original_model->schema->clone(
        $self->per_request_schema_attributes($c, $original_model));
}


sub per_request_schema_attributes {
    my ($self, $c, $original_model) = @_;

    confess
        "Either per_request_schema_attributes needs to be created, or per_request_schema needs to be overridden!";
}


1;    ## eof

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Model::DBIC::Schema::PerRequest - Per request clone of a DBIC model with additional parameters

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

 package MyApp::Model::RestrictedDB;

 use Moose;
 extends 'Catalyst::Model::DBIC::Schema::PerRequest';

 __PACKAGE__->config(target_model => 'DB');

 sub per_request_schema_attributes {
     my ($self, $c) = @_;
     return (restricting_object => $c->user->obj);
 }

In your controller:

 $c->model('RestrictedDB')->resultset('...');

=head1 DESCRIPTION

Allows you to get a clone of an existing L<Catalyst::Model::DBIC::Schema>
model with additional parameters passed to the L<DBIx::Class::Schema> clone.

=head1 ATTRIBUTES

=head2 target_model

The name of the original model class.

or

 has '+target_model' => (
     default      => 'DB',
     schema_class => 'MyApp::Schema',
 );

=head2 schema_class

The name of your L<DBIx::Class> schema.

=head1 METHODS

=head2 per_request_schema($c, $original_model)

This method is called automatically and will clone your schema with attributes
coming from L<per_request_schema_attributes>. You can override this method
directly to return a schema you want, but it's probably better to override
C<per_request_schema_attributes>.

=head2 per_request_schema_attributes($c, $original_model)

Override this method in your child class and return whatever parameters you
need for new schema instance.

 sub per_request_schema_attributes {
     my ($self, $c, $original_model) = @_;
     return (restricting_object => $c->user->obj);
 }

=head1 ACKNOWLEDGMENTS

Thanks to mst (Matt S. Trout) for the idea and mentorship during the development.

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
