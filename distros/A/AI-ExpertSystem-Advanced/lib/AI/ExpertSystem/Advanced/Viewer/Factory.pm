#
# AI::ExpertSystem::Advanced::Viewer::Factory
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/29/2009 19:12:25 PST 19:12:25
package AI::ExpertSystem::Advanced::Viewer::Factory;

=head1 NAME

AI::ExpertSystem::Advanced::Viewer::Factory - Viewer factory

=head1 DESCRIPTION

Uses the factory pattern to create viewer instances. The viewer instances are
useful (and required) to show data to the user.

=cut
use strict;
use warnings;
use Class::Factory;
use base qw(Class::Factory);

our $VERSION = '0.01';

sub new {
    my ($pkg, $type, @params) = @_;
    my $class = $pkg->get_factory_class($type);
    return undef unless ($class);
    my $self = "$class"->new(@params);
    return $self;
}

__PACKAGE__->register_factory_type(terminal =>
        'AI::ExpertSystem::Advanced::Viewer::Terminal');

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

