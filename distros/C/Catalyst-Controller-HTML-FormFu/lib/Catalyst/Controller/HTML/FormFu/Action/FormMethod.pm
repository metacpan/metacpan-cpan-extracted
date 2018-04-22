package Catalyst::Controller::HTML::FormFu::Action::FormMethod;

use strict;

our $VERSION = '2.04'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Carp qw( croak );
use namespace::autoclean;

extends 'Catalyst::Controller::HTML::FormFu::ActionBase::Form';

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    if ( $self->reverse =~ $self->_form_action_regex ) {

        # don't load form again
        return $self->next::method(@_);
    }

    my $config = $controller->_html_formfu_config;

    return $self->next::method(@_)
        unless exists $self->attributes->{ActionClass}
        && $self->attributes->{ActionClass}[0] eq $config->{method_action};

    my $form = $controller->_form;

    for ( @{ $self->{_attr_params} } ) {
        for my $method (split) {
            $c->log->debug($method) if $c->debug;

            my $args = $controller->$method($c) || {};

            $form->populate($args);
        }
    }

    $form->process;

    $c->stash->{ $config->{form_stash} } = $form;

    $self->next::method(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Controller::HTML::FormFu::Action::FormMethod

=head1 VERSION

version 2.04

=head1 AUTHORS

=over 4

=item *

Carl Franks <cpan@fireartist.com>

=item *

Nigel Metheringham <nigelm@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007-2018 by Carl Franks / Nigel Metheringham / Dean Hamstead.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
