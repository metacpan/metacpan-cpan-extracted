package CatalystX::Resource::TraitFor::Controller::Resource::Show;
$CatalystX::Resource::TraitFor::Controller::Resource::Show::VERSION = '0.02';
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

# ABSTRACT: a show action for your resource


sub show : Method('GET') Chained('base_with_id') PathPart('show') Args(0) {
    my ( $self, $c ) = @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Resource::TraitFor::Controller::Resource::Show - a show action for your resource

=head1 VERSION

version 0.02

=head1 ACTIONS

=head2 show

display the resource specified by its id, accessible as $c->stash->{resource}

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
