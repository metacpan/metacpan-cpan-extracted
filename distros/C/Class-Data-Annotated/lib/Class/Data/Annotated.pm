package Class::Data::Annotated;
use Data::Annotated;
use Data::Path;
use Carp;
use strict;
use warnings;

=head1 NAME

    Class::Data::Annotated - Data::Annotated wrapped objects

=head1 SYNOPSIS

    use Class::Data::Annotated;
    
    my $$obj = Class::Data::Annotated->new();
    
=cut

our $VERSION = '0.2';
my $callbacks = {
                key_does_not_exist => sub {},
                index_does_not_exist => sub {},
                retrieve_index_from_non_array => sub {},
                retrieve_key_from_non_hash => sub {},
                };


=head1 METHODS

=head2 new()

instantiate an Annotated Data Structure

=cut

sub new {
    my ($class, $struct) = @_;
    croak('I just gotta have data') unless $struct;
    return bless {Annotations => Data::Annotated->new(), Data => Data::Path->new($struct, $callbacks)}, $class;
}

=head2 annotate($path, \%annotation)

annotate a peice of the data. if that piece does not exist it will return undef. Otherwise it returns the data annotated.

=cut

sub annotate {
    my ($self, $path, $annotation) = @_;
    $self->_validate_path($path);
    if ($self->data()->get($path)) {
        $self->{Annotations}->annotate($path, $annotation);
        return $self->data()->get($path);
    } else { return }
}

=head2 annotations

Returns a L<Data::Annotated> object holding the dictionary of annotations for this object

=cut

sub annotations {
    return shift->{Annotations};
}

=head2 get($path)

retrieves the data for this path in the object. returns undef if data location does not exist

=cut

sub get {
    my ($self, $path) = @_;
    $self->_validate_path($path);
    return $self->data()->get($path);
}

=head2 get_annotation($path)

returns the annotations for the location in the data specified by the path.

=cut

sub get_annotation {
    my ($self, $path) = @_;
    $self->_validate_path($path);
    return $self->annotations->{$path};
}

=head2 data

Returns a L<Data::Path> object holding the data in this object

=cut

sub data {
    return shift->{Data};
}

=head1 INTERNAL METHODS

=head2 _validate_path($path)

validates a L<Data::Path> path.

=cut

sub _validate_path {
    my ($self, $path) = @_;
    croak('Invalid Path: '.$path) unless $self->annotations()->_validate_path($path);
}

1;
