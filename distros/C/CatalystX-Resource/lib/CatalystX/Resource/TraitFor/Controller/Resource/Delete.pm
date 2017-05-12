package CatalystX::Resource::TraitFor::Controller::Resource::Delete;
$CatalystX::Resource::TraitFor::Controller::Resource::Delete::VERSION = '0.02';
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

# ABSTRACT: a delete action for your resource

requires qw/
    resource_key
    _msg
    _redirect
/;


sub delete : Method('POST') Chained('base_with_id') PathPart('delete') Args(0) {
    my ( $self, $c ) = @_;
    my $resource = $c->stash->{ $self->resource_key };
    my $msg = $self->_msg( $c, 'delete' );
    $resource->delete;
    $c->flash( msg => $msg );
    $self->_redirect($c);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Resource::TraitFor::Controller::Resource::Delete - a delete action for your resource

=head1 VERSION

version 0.02

=head1 ACTIONS

=head2 delete

delete a specific resource with a POST request

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
