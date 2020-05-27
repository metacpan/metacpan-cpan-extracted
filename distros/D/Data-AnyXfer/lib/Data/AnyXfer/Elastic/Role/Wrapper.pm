package Data::AnyXfer::Elastic::Role::Wrapper;

use v5.16.3;

use Moose::Role;

use Carp;
use Class::MOP::Method;
use List::MoreUtils qw/ uniq /;
use Clone qw/ clone /;

use aliased 'Data::AnyXfer::Elastic::Utils';

=head1 NAME

 Data::AnyXfer::Elastic::Role::Wrapper - Role for wrapping module methods

=head1 DESCRIPTION

 A Moo Role that wraps module methods provided as arguements around $self.

=cut


=head2 C<wrapped_object_instance>

The L<Search::Elasticsearch> object being wrapped.

=cut

has wrapped_object_instance => (
    is  => 'rw',
    isa => 'Object',
);


# $self->_wrap_methods( Search::Elasticsearch->new(), [ qw/search index get/ ]);
#
# Wraps object methods around C<$self>. Requires a blessed object and a arrayref
# of methods to wrap. A method that is not provided by C<$object> will not be
# wrapped.

sub _wrap_methods {
    my ( $self, $orig, $methods ) = @_;

    # store the original wrapped instance
    $self->wrapped_object_instance($orig);

    # filter methods array to only contain methods that can be
    # performed by the wrapped object instance
    $methods = [ grep { $orig->can($_) } @{$methods} ];

    # XXX : Make sure the search elasticsearch instance cannot be closed
    # on lower down in the installed methods, or risk a million bugs

    my $orig_class = ref $orig; # just record what it was
    undef $orig;

    # Install a new method on self for each method in the list

    foreach my $method ( uniq @{$methods} ) {

        $self->meta->add_method(
            $method => sub {

                my $self = shift;

                # validate they are using the proper interface
                # we limit the call signatures to one type
                # key-value lists directly instead of references
                # (even though S::ES supports both)
                croak 'You supplied a single reference as an argument.'
                    . 'Data::AnyXfer::Elastic only accepts key-value lists.'
                    if ( @_ == 1 && ref( $_[0] ) );

                # process arguments
                my %args = @_;
                $self->_compose( $method, \%args );

                # redispatch to the real search elasticsearch method
                $self->wrapped_object_instance->$method(%args);
            }
        );
    }

    return 1;
}

# The method `_componse` configures the arguments before execution.
# An arguement field named index will be prepended with test information
# if on a test environment. For automatic index name and type injection the
# is_inject_index_and_type flag must be set.

sub _compose {
    my ( $self, $method, $args ) = @_;

    if ( ref($args) eq 'HASH' || !$args ) {
        if ( $self->is_inject_index_and_type ) {
            $self->_inject_index_and_type_arguments($args);
        }
    } else {
        croak "Arguements required in hash context";
    }

    # remove injected arguements if the method is blacklisted
    if ( $self->can('_blacklist')
        && $self->_blacklist->{$method} ) {

        my $remove_type  = $self->_blacklist->{$method}->{type}  || 0;
        my $remove_index = $self->_blacklist->{$method}->{index} || 0;

        if ( $remove_type == 1 ) {
            delete $args->{type};
        }
        if ( $remove_index == 1 ) {
            delete $args->{index};
        }
    }
    return $args;

}

# For Data::AnyXfer::Elastic::Index the arguments, index and type are
# automatically injected into the method. See Data::AnyXfer::Elastic::Index
# for details.

sub _inject_index_and_type_arguments {
    my ( $self, $args ) = @_;

    if ( $self->can('index_name') ) {
        $args->{index} ||= $self->index_name;
    }
    if ( $self->can('index_type') ) {
        $args->{type} ||= $self->index_type;
    }
    return $args;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

