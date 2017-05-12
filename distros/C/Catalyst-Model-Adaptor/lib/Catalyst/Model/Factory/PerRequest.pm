package Catalyst::Model::Factory::PerRequest;
use strict;
use warnings;
use MRO::Compat;

use base 'Catalyst::Model::Factory';

our $VERSION = '0.10';

sub ACCEPT_CONTEXT {
    my ($self, $context, @args) = @_;
    my $id = '__'. ref $self;
    return $context->stash->{$id} ||= $self->next::method($context, @args);
}

1;
__END__

=head1 NAME

Catalyst::Model::Factory::PerRequest - use a plain class as a Catalyst model,
instantiating it once per Catalyst request

=head1 SYNOPSIS

This module works just like
L<Catalyst::Model::Factory|Catalyst::Model::Factory>, except that a
fresh instance of your adapted class is once per Catalyst request, not
every time you ask for the object via C<< $c->model >>.

=head1 CUSTOMIZING

You can customize your subclass just like
L<Catalyst::Model::Adaptor|Catalyst::Model::Adaptor>.  Instead of
C<$app>, though, you'll get C<$c>, the current request context.

=head1 METHODS

These methods are called by Catalyst, not by you:

=head2 COMPONENT

Load your class

=head2 ACCEPT_CONTEXT

Create an instance of your class and return it.

=head1 SEE ALSO

For all the critical documentation, see L<Catalyst::Model::Adaptor>.
