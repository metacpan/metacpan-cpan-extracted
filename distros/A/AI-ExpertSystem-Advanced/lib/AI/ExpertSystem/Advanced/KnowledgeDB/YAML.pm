#
# AI::ExpertSystem::Advanced::KnowledgeDB::YAML
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 12/13/2009 16:12:43 PST 16:12:43
package AI::ExpertSystem::Advanced::KnowledgeDB::YAML;

=head1 NAME

AI::ExpertSystem::Advanced::KnowledgeDB::YAML - YAML Knowledge DB driver

=head1 DESCRIPTION

A YAML knowledge database driver.

It reads a given YAML file and looks for the I<rules> hash key. All of the
elements of C<rules> (causes and goals) are copied to the C<rules> hash
key of L<AI::ExpertSystem::Advanced::KnowledgeDB::Base>.

If no rules are found then it ends unsuccessfully.

It also looks for any available questions under the I<questions> hash key,
however if no questions are found then they are not copied :-)

=cut
use Moose;
use YAML::Syck;

extends 'AI::ExpertSystem::Advanced::KnowledgeDB::Base';

our $VERSION = '0.01';

=head1 Attributes

=over 4

=item B<filename>

YAML file path to read

=back

=cut
has 'filename' => (
        is => 'rw',
        isa => 'Str',
        required => 1);

# Called when the object gets created
sub BUILD {
    my ($self) = @_;

    my $data = LoadFile($self->{'filename'});
    if (defined $data->{'rules'}) {
        $self->{'rules'} = $data->{'rules'}
    } else {
        confess "Couldn't find any rules in $self->{'filename'}";
    }

    if (defined $data->{'questions'}) {
        $self->{'questions'} = $data->{'questions'};
    }
}

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

