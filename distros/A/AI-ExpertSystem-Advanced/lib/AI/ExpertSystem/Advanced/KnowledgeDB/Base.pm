#
# AI::ExpertSystem::Advanced::KnowledgeDB::Base
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/29/2009 19:14:28 PST 19:14:28
package AI::ExpertSystem::Advanced::KnowledgeDB::Base;

=head1 NAME

AI::ExpertSystem::Advanced::KnowledgeDB::Base - Base class for knowledge DBs.

=head1 DESCRIPTION

All knowledge databases that L<AI::ExpertSystem::Advanced> uses should extend
from this class.

This base class implements the basic methods required for extracting the rules,
causes, goals and questions from the a plain text knowledge database, eg, all
the records remain in the application memory instead of a database engine such
as MySQL or SQLite.

=cut
use Moose;
use AI::ExpertSystem::Advanced::Dictionary;

our $VERSION = '0.03';

=head1 Attributes

=over 4

=item B<rules>

This hash has the rules contained in the knowledge database. It's populated
when an instance of L<AI::ExpertSystem::Advanced::KnowledgeDB::Base> is
created.

B<TIP>: There's no sense in filling this hash if you are going to be using a
database engine such as MySQL, SQLite or others. The hash is useful if your
knowledge database will remain in application memory.

=cut
has 'rules' => (
        is => 'ro',
        isa => 'HashRef');

=item B<questions>

Similar and same concept of C<rules>, but this will have a list (if available)
of what questions should be done to certain facts.

=back

=cut
has 'questions' => (
        is => 'ro',
        isa => 'HashRef',
        default => sub { return {}; });

=head1 Methods

=head2 B<read()>

This method reads the knowledge database. This is the only method you need to
define even if you are going to load the database in memory or if you are
going to query it.

=cut
sub read {
    confess "You can't call KnowedgeDB::Base! (abstract method)";
}

=head2 B<rule_goals($rule)>

Returns all the goals (usually only one) of the given C<$rule>.

The goals B<should> be returned as a L<AI::ExpertSystem::Advanced::Dictionary>.

B<NOTE>: Rewrite this method if you are not going to use the C<rules> hash (eg,
you will use a database engine).

=cut
sub rule_goals {
    my ($self, $rule) = @_;

    if (!defined $self->{'rules'}->[$rule]) {
        confess "Rule $rule does not exist";
    }
    my @facts;
    # Get all the facts of this goal (usually only one)
    foreach (@{$self->{'rules'}->[$rule]->{'goals'}}) {
        my $id;
        # it has an ID?
        if (defined $_->{'id'}) {
            $id = $_->{'id'};
        } elsif (defined $_->{'name'}) { # or a name?
            $id = $_->{'name'};
        }
        if (defined $id) {
            push(@facts, $id);
        } else {
            confess "Seems rule $rule does not have an id or name key";
        }
    }
    my $goals_dict = AI::ExpertSystem::Advanced::Dictionary->new(
            stack => \@facts);
    return $goals_dict;
}

=head2 B<rule_causes($rule)>

Returns all the causes of the given C<$rule>.

Same as C<rule_goals()>, the causes should be returned as a
L<AI::ExpertSystem::Advanced::Dictionary>.

B<NOTE>: Rewrite this method if you are not going to use the C<rules> hash (eg,
you will use a database engine).

=cut
sub rule_causes {
    my ($self, $rule) = @_;

    if (!defined $self->{'rules'}->[$rule]) {
        confess "Rule $rule does not exist";
    }
    my @facts;
    # Get all the facts of this cause
    foreach (@{$self->{'rules'}->[$rule]->{'causes'}}) {
        my $id;
        # it has an ID?
        if (defined $_->{'id'}) {
            $id = $_->{'id'};
        } elsif (defined $_->{'name'}) { # or a name?
            $id = $_->{'name'};
        }
        if (defined $id) {
            push(@facts, $id);
        } else {
            confess "Seems rule $rule does not have an id or name key";
        }
    }
    my $causes_dict = AI::ExpertSystem::Advanced::Dictionary->new(
            stack => \@facts);
    return $causes_dict;
}

=head2 B<find_rule_by_goal($goal)>

Looks for the first rule that has the given C<goal> in its goals.

If a rule is found then its number is returned, otherwise C<undef> is
returned.

B<NOTE>: Rewrite this method if you are not going to use the C<rules> hash (eg,
you will use a database engine).

=cut
sub find_rule_by_goal {
    my ($self, $goal) = @_;

    my $rule_counter = 0;
    foreach my $rule (@{$self->{'rules'}}) {
        foreach my $rule_goal (@{$rule->{'goals'}}) {
            # Look in id and name for the match
            foreach my $look_in (qw(id name)) {
                if (defined $rule_goal->{$look_in}) {
                    if ($rule_goal->{$look_in} eq $goal) {
                        return $rule_counter;
                    }
                }
            }
        }
        $rule_counter++;
    }
    return undef;
}

=head2 B<get_question($fact)>

Looks for a question about the given C<$fact>. If a question exists then this is
returned, otherwise C<undef> is returned.

B<NOTE>: Rewrite this method if you are not going to use the C<rules> hash (eg,
you will use a database engine).

=cut
sub get_question {
    my ($self, $fact) = @_;

    if (defined $self->{'questions'}->{$fact}) {
        return  $self->{'questions'}->{$fact};
    }
    return undef;
}

=head2 B<get_next_rule($current_rule)>

Returns the ID of the next rule. When there are no more rules to work then
C<undef> should be returned.

When it starts looking for the first rule, C<$current_rule> value will
be C<undef>.

B<NOTE>: Rewrite this method if you are not going to use the C<rules> hash (eg,
you will use a database engine).

=cut
sub get_next_rule {
    my ($self, $current_rule) = @_;

    my $next_rule;
    if (defined $current_rule) {
        $next_rule = $current_rule+1;
    } else {
        $next_rule = 0;
    } 

    if (defined $self->{'rules'}->[$next_rule]) {
        return $next_rule;
    } else {
        return undef;
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

