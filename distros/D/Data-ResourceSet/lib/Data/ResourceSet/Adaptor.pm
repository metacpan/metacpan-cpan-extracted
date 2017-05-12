# $Id: /mirror/coderepos/lang/perl/Data-ResourceSet/trunk/lib/Data/ResourceSet/Adaptor.pm 54068 2008-05-19T05:50:37.210926Z daisuke  $

package Data::ResourceSet::Adaptor;
use Moose;

has 'constructor' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'new'
);

has 'class' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'args' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    default  => sub { +{} }
);

sub ACCEPT_CONTEXT
{
    my $self = shift;
    return $self->_create_instance(@_);
}

sub _create_instance {
    my ($self, $c, @args) = @_;

    my $constructor = $self->constructor;
    my $args = $self->prepare_arguments($c, @args);
    my $adapted_class = $self->class;
    if (! Class::MOP::is_class_loaded( $adapted_class ) ) {
        $adapted_class->require or die;
    }

    return $adapted_class->$constructor($self->mangle_arguments($args));
}

sub prepare_arguments {
    my ($self, $app) = @_;
    return $self->args;
}

sub mangle_arguments {
    my ($self, $args) = @_;
    return $args;
}

1;

__END__

=head1 NAME

Data::ResourceSet::Adaptor - Adaptor Interface for ResourceSet

=head1 SYNOPSIS

  Data::ResourceSet::Adaptor->new(
    constructor => 'new', # optional. default "new"
    class => 'NameOfAdaptedClass',
    args  => \%arguments
  );

=head1 DESCRIPTION

This is a rip-off of Catalyst::Model::Adaptor

=head1 METHODS

=head2 ACCEPT_CONTEXT

=head2 prepare_arguments

=head2 mangle_arguments

=cut