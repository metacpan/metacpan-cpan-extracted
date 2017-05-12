package Catalyst::Controller::DBIC::API::Validator;
$Catalyst::Controller::DBIC::API::Validator::VERSION = '2.006002';
#ABSTRACT: Provides validation services for inbound requests against whitelisted parameters
use Moose;
use Catalyst::Controller::DBIC::API::Validator::Visitor;
use namespace::autoclean;

BEGIN { extends 'Data::DPath::Validator'; }

has '+visitor' => ( 'builder' => '_build_custom_visitor' );

sub _build_custom_visitor {
    return Catalyst::Controller::DBIC::API::Validator::Visitor->new();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::Validator - Provides validation services for inbound requests against whitelisted parameters

=head1 VERSION

version 2.006002

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
