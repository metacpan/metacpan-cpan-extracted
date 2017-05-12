package CatalystX::Resource::TraitFor::Controller::Resource::Edit;
$CatalystX::Resource::TraitFor::Controller::Resource::Edit::VERSION = '0.02';
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

# ABSTRACT: a edit action for your resource

requires qw/
    form
/;



has 'activate_fields_edit' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);


sub edit : Method('GET') Method('POST') Chained('base_with_id') PathPart('edit') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( set_update_msg => 1 );
    $self->form( $c, $self->activate_fields_edit );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Resource::TraitFor::Controller::Resource::Edit - a edit action for your resource

=head1 VERSION

version 0.02

=head1 ATTRIBUTES

=head2 activate_fields_edit

arrayref of form fields to activate in the edit form

Can be overriden with $c->stash->{activate_form_fields}

(default = []).

=head1 ACTIONS

=head2 edit

edit a specific resource

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
