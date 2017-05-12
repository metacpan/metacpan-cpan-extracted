#
# AI::ExpertSystem::KnowledgeDB::Factory
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/29/2009 19:12:25 PST 19:12:25
package AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

=head1 NAME

AI::ExpertSystem::Advanced::KnowledgeDB::Factory - Knowledge DB driver factory

=head1 DESCRIPTION

Uses the factory pattern to create instances of knowledge database drivers.

=head1 SYNOPSIS

    use AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

    my $yaml_kdb = AI::ExpertSystem::Advanced::KnowledgeDB::Factory->new('yaml',
        {
            filename => 'examples/knowledge_db_one.yaml'
        });

=cut
use strict;
use warnings;
use Class::Factory;
use base qw(Class::Factory);

our $VERSION = '0.02';

sub new {
    my ($pkg, $type, @params) = @_;
    my $class = $pkg->get_factory_class($type);
    return undef unless ($class);
    my $self = "$class"->new(@params);
    return $self;
}

__PACKAGE__->register_factory_type(yaml =>
        'AI::ExpertSystem::Advanced::KnowledgeDB::YAML');

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
