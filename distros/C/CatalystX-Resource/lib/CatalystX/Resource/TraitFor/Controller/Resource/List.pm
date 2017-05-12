package CatalystX::Resource::TraitFor::Controller::Resource::List;
$CatalystX::Resource::TraitFor::Controller::Resource::List::VERSION = '0.02';
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

# ABSTRACT: a list action for your resource


sub list : Method('GET') Chained('base') PathPart('list') Args(0) {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Resource::TraitFor::Controller::Resource::List - a list action for your resource

=head1 VERSION

version 0.02

=head1 ACTIONS

=head2 list

display list (index) of all resources

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
