package DBICx::Modeler::Model::Relationship;

use Moose;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

has modeler => qw/is ro required 1 weak_ref 1/;
has name => qw/is ro required 1/;
has schema_relationship => qw/is ro required 1/;
has result_class => qw/is ro lazy_build 1/;
sub _build_result_class {
    my $self = shift;
    return $self->schema_relationship->{class};
}
has default_model_class => qw/is ro lazy_build 1/;
sub _build_default_model_class {
    my $self = shift;
    return $self->modeler->model_class_by_result_class( $self->result_class );
}
has model_class => qw/is rw lazy_build 1/;
sub _build_model_class {
    my $self = shift;
    return $self->default_model_class;
}

sub is_many {
    my $self = shift;
    return $self->schema_relationship->{attrs}->{accessor} eq "multi";
}

sub belongs_to {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub might_have {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub has_one {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub has_many {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub clone {
    my $self = shift;
    my %override = @_;
    return (blessed $self)->new(
        ( map { $_ => $self->$_ } qw/modeler name schema_relationship model_class/ ),
        %override,
    );
}


1;
