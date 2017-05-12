#
# AI::ExpertSystem::Advanced
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/29/2009 18:28:30 CST 18:28:30
package AI::ExpertSystem::Advanced;

=head1 NAME

AI::ExpertSystem::Advanced - Expert System with backward, forward and mixed algorithms

=head1 DESCRIPTION

Inspired in L<AI::ExpertSystem::Simple> but with additional features:

=over 4

=item *

Uses backward, forward and mixed algorithms.

=item *

Offers different views, so user can interact with the expert system via a
terminal or with a friendly user interface.

=item *

The knowledge database can be stored in any format such as YAML, XML or
databases. You just need to choose what driver to use and you are done.

=item *

Uses certainty factors.

=back

=head1 SYNOPSIS

An example of the mixed algorithm:

    use AI::ExpertSystem::Advanced;
    use AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

    my $yaml_kdb = AI::ExpertSystem::Advanced::KnowledgeDB::Factory->new('yaml',
        {
            filename => 'examples/knowledge_db_one.yaml'
        });

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            initial_facts => ['I'],
            verbose => 1);
    $ai->mixed();
    $ai->summary();

=cut
use Moose;
use AI::ExpertSystem::Advanced::KnowledgeDB::Base;
use AI::ExpertSystem::Advanced::Viewer::Base;
use AI::ExpertSystem::Advanced::Viewer::Factory;
use AI::ExpertSystem::Advanced::Dictionary;
use Time::HiRes qw(gettimeofday);
use YAML::Syck qw(Dump);

our $VERSION = '0.03';

=head1 Attributes

=over 4

=item B<initial_facts>

A list/set of initial facts the algorithms start using.

During the forward algorithm the task is to find a list of goals caused
by these initial facts (the only data we have in that moment).

Lets imagine your knowledge database is about symptoms and diseases. You need
to find what diseases are caused by the symptoms of a patient, these first
symptons are the initial facts.

Initial facts as also asked and inference facts can be negative or positive. By
default the initial facts are positive.

Keep in mind that the data contained in this array can be the IDs or the name
of the fact.

This array will be converted to L<initial_facts_dict>. And all the data (ids or
or names) will be made of only IDs.

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            initial_facts => ['I', ['F', '-'], ['G', '+']);

As you can see if you want to provide the sign of a fact, just I<encapsulate>
it in an array, the first item should be the fact and the second one the
sign.

=cut
has 'initial_facts' => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
        default => sub { return []; });

=item B<initial_facts_dict>

This dictionary (see L<AI::ExpertSystem::Advanced::Dictionary> has the sasme
data of L<initial_facts> but with the additional feature(s) of proviing
iterators and a quick way to find elements.

=cut
has 'initial_facts_dict' => (
        is => 'ro',
        isa => 'AI::ExpertSystem::Advanced::Dictionary');

=item B<goals_to_check>

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            goals_to_check => ['J']);

When doing the L<backward()> algorithm it's required to have at least one goal
(aka hypothesis).

This could be pretty similar to L<initial_facts>, with the difference that the
initial facts are used more with the causes of the rules and this one with
the goals (usually one in a well defined knowledge database).

The same rule of L<initial_facts> apply here, you can provide the sign of the
facts and you can provide the id or the name of them.

From our example of symptoms and diseases lets imagine we have the hypothesis
that a patient has flu, we don't know the symptoms it has, we want the
expert system to keep asking us for them to make sure that our hypothesis
is correct (or incorrect in case there's not enough information).

=cut
has 'goals_to_check' => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
        default => sub { return []; });

=item B<goals_to_check_dict>

Very similar to L<goals_to_check> (and indeed of L<initial_facts_dict>). We
want to make the job easier.

It will be a dictionary made of the data of L<goals_to_check>.

=cut
has 'goals_to_check_dict' => (
        is => 'ro',
        isa => 'AI::ExpertSystem::Advanced::Dictionary');

=item B<inference_facts>

Inference facts are basically the core of an expert system. These are facts
that are found and copied when a set of facts (initial, inference or asked)
match with the causes of a goal.

L<inference_facts> is a L<AI::ExpertSystem::Advanced::Dictionary>, it will
store the name of the fact, the rule that caused these facts to be copied to
this dictionary, the sign and the algorithm that triggered it.

=cut
has 'inference_facts' => (
        is => 'ro',
        isa => 'AI::ExpertSystem::Advanced::Dictionary');
       
=item B<knowledge_db>

The object reference of the knowledge database L<AI::ExpertSystem::Advanced> is
using.

=cut
has 'knowledge_db' => (
        is => 'rw',
        isa => 'AI::ExpertSystem::Advanced::KnowledgeDB::Base',
        required => 1);

=item B<asked_facts>

During the L<backward()> algorithm there will be cases when there's no clarity
if a fact exists. In these cases the L<backward()> will be asking the user
(via automation or real questions) if a fact exists.

Going back to the L<initial_facts> example of symptoms and diseases. Imagine
the algorithm is checking a rule, some of the facts of the rule make a match
with the ones of L<initial_facts> or L<inference_facts> but some wont, for
these I<unsure> facts the L<backward()> will ask the user if a symptom (a fact)
exists. All these asked facts will be stored here.

=cut
has 'asked_facts' => (
        is => 'ro',
        isa => 'AI::ExpertSystem::Advanced::Dictionary');

=item B<visited_rules>

Keeps a record of all the rules the algorithms have visited and also the number
of causes each rule has.

=cut
has 'visited_rules' => (
        is => 'ro',
        isa => 'AI::ExpertSystem::Advanced::Dictionary');

=item B<verbose>

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            initial_facts => ['I'],
            verbose => 1);

By default this is turned off. If you want to know what happens behind the
scenes turn this on.

Everything that needs to be debugged will be passed to the L<debug()> method
of your L<viewer>.

=cut
has 'verbose' => (
        is => 'rw',
        isa => 'Bool',
        default => 0);

=item B<viewer>

Is the object L<AI::ExpertSystem::Advanced> will be using for printing what is
happening and for interacting with the user (such as asking the
L<asked_facts>).

This is practical if you want to use a viewer object that is not provided by
L<AI::ExpertSystem::Advanced::Viewer::Factory>.

=cut
has 'viewer' => (
        is => 'rw',
        isa => 'AI::ExpertSystem::Advanced::Viewer::Base');

=item B<viewer_class>

Is the the class name of the L<viewer>.

You can decide to use the viewers L<AI::ExpertSystem::Advanced::Viewer::Factory>
offers, in this case you can pass the object or only the name of your favorite
viewer.

=cut
has 'viewer_class' => (
        is => 'rw',
        isa => 'Str',
        default => 'terminal');

=item B<found_factor>

In your knowledge database you can give different I<weights> to the facts of
each rule (eg to define what facts have more I<priority>). During the
L<mixed()> algorithm it will be checking what causes are found in the
L<inference_facts> and in the L<asked_facts> dictionaries, then the total
number of matches (or total number of certainity factors of each rule) will
be compared versus the value of this factor, if it's higher or equal then the
rule will be triggered.

You can read the documentation of the L<mixed()> algorithm to know the two
ways this factor can be used.

=cut
has 'found_factor' => (
        is => 'rw',
        isa => 'Num',
        default => '0.5');

=item B<shot_rules>

All the rules that are shot are stored here. This is a hash, the key of each
item is the rule id while its value is the precision time when the rule was
shot.

The precision time is useful for knowing when a rule was shot and based on that
you can know what steps it followed so you can compare (or reproduce) them.

=back

=cut
has 'shot_rules' => (
        is => 'ro',
        isa => 'HashRef[Str]');

=head1 Constants

=over 4

=item * B<FACT_SIGN_NEGATIVE>

Used when a fact is negative, aka, a fact doesn't happen.

=cut
use constant FACT_SIGN_NEGATIVE => '-';

=item * B<FACT_SIGN_POSITIVE>

Used for those facts that happen.

=cut
use constant FACT_SIGN_POSITIVE => '+';

=item * B<FACT_SIGN_UNSURE>

Used when there's no straight answer of a fact, eg, we don't know if an answer
will change the result.

=back

=cut
use constant FACT_SIGN_UNSURE   => '~';

=head1 Methods

=head2 B<shoot($rule, $algorithm)>

Shoots the given rule. It will do the following verifications:

=over 4

=item *

Each of the facts (causes) will be compared against the L<initial_facts_dict>,
L<inference_facts> and L<asked_facts> (in this order).

=item *

If any initial, inference or asked fact matches with a cause but it's negative
then all of its goals (usually only one by rule) will be copied to the
L<inference_facts> with a negative sign, otherwise a positive sign will be
used.

=item *

Will add the rule to the L<shot_rules> hash.

=back

=cut
sub shoot {
    my ($self, $rule, $algorithm) = @_;

    $self->{'shot_rules'}->{$rule} = gettimeofday;

    my $rule_causes = $self->get_causes_by_rule($rule);
    my $rule_goals = $self->get_goals_by_rule($rule);
    my $any_negation = 0;
    $rule_causes->populate_iterable_array();
    while(my $caused_fact = $rule_causes->iterate) {
        # Now, from the current rule fact, any of the facts were marked
        # as *negative* from the initial facts, inference or asked facts?
        $any_negation = 0;
        foreach my $dict (qw(initial_facts_dict inference_facts asked_facts)) {
            # Also make sure we are going to read from position 0 in our dicts
            $self->{$dict}->populate_iterable_array();
            while(my $dict_fact = $self->{$dict}->iterate) {
                if ($dict_fact eq $caused_fact) {
                    if ($self->is_fact_negative(
                                $dict,
                                $dict_fact)) {
                        $any_negation = 1;
                        last;
                    }
                }
            }
        }
        # anything negative?
        if ($any_negation) {
            last;
        }
    }
    my $sign = ($any_negation) ? FACT_SIGN_NEGATIVE : FACT_SIGN_POSITIVE;
    # Copy the goal(s) of this rule to our "initial facts"
    $self->copy_to_inference_facts($rule_goals, $sign, $algorithm, $rule);
}

=head2 B<is_rule_shot($rule)>

Verifies if the given C<$rule> has been shot.

=cut
sub is_rule_shot {
    my ($self, $rule) = @_;

    return defined $self->{'shot_rules'}->{$rule};
}

=head2 B<get_goals_by_rule($rule)>

Will ask the L<knowledge_db> for the goals of the given C<$rule>.

A L<AI::ExpertSystem::Advanced::Dictionary> will be returned.

=cut
sub get_goals_by_rule {
    my ($self, $rule) = @_;
    return $self->{'knowledge_db'}->rule_goals($rule);
}

=head2 B<get_causes_by_rule($rule)>

Will ask the L<knowledge_db> for the causes of the given C<$rule>.

A L<AI::ExpertSystem::Advanced::Dictionary> will be returned.

=cut
sub get_causes_by_rule {
    my ($self, $rule) = @_;
    return $self->{'knowledge_db'}->rule_causes($rule);
}

=head2 B<is_fact_negative($dict_name, $fact)>

Will check if the given C<$fact> of the given dictionary (C<$dict_name>) is
negative.

=cut
sub is_fact_negative {
    my ($self, $dict_name, $fact) = @_;

    my $sign = $self->{$dict_name}->get_value($fact, 'sign');
    if (!defined $sign) {
        confess "This fact ($fact) does not exists!";
    }
    return $sign eq FACT_SIGN_NEGATIVE;
}

=head2 B<copy_to_inference_facts($facts, $sign, $algorithm, $rule)>

Copies the given C<$facts> (a dictionary, usually goal(s) of a rule) to the
L<inference_facts> dictionary. All the given goals will be copied with the
given C<$sign>.

Additionally it will add the given C<$algorithm> and C<$rule> to the inference
facts. So later we can know how we got to a certain inference fact.

=cut
sub copy_to_inference_facts {
    my ($self, $facts, $sign, $algorithm, $rule) = @_;

    while(my $fact = $facts->iterate) {
        $self->{'inference_facts'}->append(
                $fact,
                {
                    name => $fact,
                    sign => $sign,
                    factor => 0.0,
                    algorithm => $algorithm,
                    rule => $rule
                });
    }
}

=head2 B<compare_causes_with_facts($rule)>

Compares the causes of the given C<$rule> with:

=over 4

=item *

Initial facts

=item *

Inference facts

=item *

Asked facts

=back

It will be couting the matches of all of the above dictionaries, so for example
if we have four causes, two make match with initial facts, other with inference
and the remaining one with the asked facts, then it will evaluate to true since
we have a match of the four causes.

=cut
sub compare_causes_with_facts {
    my ($self, $rule) = @_;
    
    my $causes = $self->get_causes_by_rule($rule);
    my $match_counter = 0;
    my $causes_total = $causes->size();
    
    while (my $cause = $causes->iterate) {
        foreach my $dict (qw(initial_facts_dict inference_facts asked_facts)) {
            if ($self->{$dict}->find($cause)) {
                $match_counter++;
            }
        }
    }
    return $match_counter eq $causes_total;
}

=head2 B<get_causes_match_factor($rule)>

Similar to L<compare_causes_with_facts()> but with the difference that it will
count the L<match factor> of each matched cause and return the total of this
weight.

The match factor is used by the L<mixed()> algorithm and is useful to know if
a certain rule should be shoot or not even if not all of the causes exist
in our facts.

The I<match factor> is calculated in two ways:

=over 4

=item *

Will do a sum of the weight for each matched cause. Please note that if only
one cause of a rule has a specified weight then the remaining causes will 
default to the total weight minus 1 and then divided with the total number
of causes (matched or not) that don't have a weight.

=item *

If no weight is found with all the causes of the given rule, then the total
number of matches will be divided by the total number of causes.

=back

=cut
sub get_causes_match_factor {
    my ($self, $rule) = @_;

    my $causes = $self->get_causes_by_rule($rule);
    my $causes_total = $causes->size();

    my ($factor_counter, $missing_factor, $match_counter, $nonfactor_match) =
        (0, 0, 0, 0);
    
    while (my $cause = $causes->iterate) {
        my $factor = $causes->get_value($cause, 'factor');
        if (!defined $factor) {
            $missing_factor++;
        }
        foreach my $dict (qw(initial_facts_dict inference_facts asked_facts)) {
            if ($self->{$dict}->find($cause)) {
                $match_counter++;
                if (defined $factor) {
                    $factor_counter = $factor_counter + $factor;
                } else {
                    $nonfactor_match++;
                }
            }
        }
    }
    # No matches?
    if ($match_counter eq 0) {
        return 0;
    }
    # None of the causes (matched or not) have a factor
    if ($causes_total eq $missing_factor) {
        return $match_counter / $causes_total;
    } else { # Some factors found
       if ($missing_factor) { # Oh, but some causes don't have it
           return $factor_counter + ($nonfactor_match / $causes_total);
       } else {
           return $factor_counter;
       }
    }
}

=head2 B<is_goal_in_our_facts($goal)>

Checks if the given C<$goal> is in:

=over 4

=item 1

The initial facts

=item 2

The inference facts

=item 3

The asked facts

=back

=cut
sub is_goal_in_our_facts {
    my ($self, $goal) = @_;

    foreach my $dict (qw(initial_facts_dict inference_facts asked_facts)) {
        if ($self->{$dict}->find($goal)) {
            return 1;
        }
    }
    return undef;
}

=head2 B<remove_last_ivisited_rule()>

Removes the last visited rule and return its number.

=cut
sub remove_last_visited_rule {
    my ($self) = @_;

    my $last = $self->{'visited_rules'}->iterate;
    if (defined $last) {
        $self->{'visited_rules'}->remove($last);
        $self->{'visited_rules'}->populate_iterable_array();
    }
    return $last;
}

=head2 B<visit_rule($rule, $total_causes)>

Adds the given C<$rule> to the end of the L<visited_rules>.

=cut
sub visit_rule {
    my ($self, $rule, $total_causes) = @_;

    $self->{'visited_rules'}->prepend($rule,
            {
                causes_total => $total_causes,
                causes_pending => $total_causes
            });
    $self->{'visited_rules'}->populate_iterable_array();
}

=head2 B<copy_to_goals_to_check($rule, $facts)>

Copies a list of facts (usually a list of causes of a rule) to
L<goals_to_check_dict>.

The rule ID of the goals that are being copied is also stored in the hahs.

=cut
sub copy_to_goals_to_check {
    my ($self, $rule, $facts) = @_;

    while(my $fact = $facts->iterate_reverse) {
        $self->{'goals_to_check_dict'}->prepend(
                $fact,
                {
                    name => $fact,
                    sign => $facts->get_value($fact, 'sign'),
                    rule => $rule
                });
    }
}

=head2 B<ask_about($fact)>

Uses L<viewer> to ask the user for the existence of the given C<$fact>.

The valid answers are:

=over 4

=item B<+> or L<FACT_SIGN_POSITIVE>

In case user knows of it.

=item B<-> or L<FACT_SIGN_NEGATIVE>

In case user doesn't knows of it.

=item B<~> or L<FACT_SIGN_UNSURE>

In case user doesn't have any clue about the given fact.

=back

=cut
sub ask_about {
    my ($self, $fact) = @_;

    # The knowledge db has questions for this fact?
    my $question = $self->{'knowledge_db'}->get_question($fact);
    if (!defined $question) {
        $question = "Do you have $fact?";
    }
    my @options = qw(Y N U);
    my $answer = $self->{'viewer'}->ask($question, @options);
    return $answer;
}

=head2 B<get_rule_by_goal($goal)>

Looks in the L<knowledge_db> for the rule that has the given goal. If a rule
is found its number is returned, otherwise undef.

=cut
sub get_rule_by_goal {
    my ($self, $goal) = @_;

    return $self->{'knowledge_db'}->find_rule_by_goal($goal);
}

=head2 B<forward()>

    use AI::ExpertSystem::Advanced;
    use AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

    my $yaml_kdb = AI::ExpertSystem::Advanced::KnowledgeDB::Factory->new('yaml',
            {
                filename => 'examples/knowledge_db_one.yaml'
            });

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            initial_facts => ['F', 'J']);
    $ai->forward();
    $ai->summary();

The forward chaining algorithm is one of the main methods used in Expert
Systems. It starts with a set of variables (known as initial facts) and reads
the available rules.

It will be reading rule by rule and for each one it will compare its causes
with the initial, inference and asked facts. If all of these causes are in the
facts then the rule will be shoot and all of its goals will be copied/converted
to inference facts and will restart reading from the first rule.

=cut
sub forward {
    my ($self) = @_;

    confess "Can't do forward algorithm with no initial facts" unless
        $self->{'initial_facts_dict'};

    my ($more_rules, $current_rule) = (1, undef);
    while($more_rules) {
        $current_rule = $self->{'knowledge_db'}->get_next_rule($current_rule);

        # No more rules?
        if (!defined $current_rule) {
            $self->{'viewer'}->debug("We are done with all the rules, bye")
                if $self->{'verbose'};
            $more_rules = 0;
            last;
        }

        $self->{'viewer'}->debug("Checking rule: $current_rule") if
            $self->{'verbose'};
        
        if ($self->is_rule_shot($current_rule)) {
            $self->{'viewer'}->debug("We already shot rule: $current_rule")
                if $self->{'verbose'};
            next;
        }

        $self->{'viewer'}->debug("Reading rule $current_rule")
            if $self->{'verbose'};
        $self->{'viewer'}->debug("More rules to check, checking...")
            if $self->{'verbose'};

        my $rule_causes = $self->get_causes_by_rule($current_rule);
        # any of our rule facts match with our facts to check?
        if ($self->compare_causes_with_facts($current_rule)) {
            # shoot and start again
            $self->shoot($current_rule, 'forward');
            # Undef to start reading from the first rule.
            $current_rule = undef;
            next;
        }
    }
    return 1;
}

=head2 B<backward()>

    use AI::ExpertSystem::Advanced;
    use AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

    my $yaml_kdb = AI::ExpertSystem::Advanced::KnowledgeDB::Factory->new('yaml',
        {
            filename => 'examples/knowledge_db_one.yaml'
            });

    my $ai = AI::ExpertSystem::Advanced->new(
            viewer_class => 'terminal',
            knowledge_db => $yaml_kdb,
            goals_to_check => ['J']);
    $ai->backward();
    $ai->summary();

The backward algorithm starts with a set of I<assumed> goals (facts). It will
start reading goal by goal. For each goal it will check if it exists in the
initial, inference and asked facts (see L<is_goal_in_our_facts()>) for more
information).

=over 4

=item *

If the goal exist then it will be removed from the dictionary, it will also
verify if there are more visited rules to shoot.

If there are still more visited rules to shoot then it will check from what
rule the goal comes from, if it was copied from a rule then this data will
exist. With this information then it will see how many of the causes of this
given rule are still in the L<goals_to_check_dict>.

In case there are still causes of this rule in L<goals_to_check_dict> then the
amount of causes pending will be reduced by one. Otherwise (if the amount is
0) then the rule of this last removed goal will be shoot.

=item *

If the goal doesn't exist in the mentioned facts then the goal will be searched
in the goals of every rule.

In case it finds the rule that has the goal, this rule will be marked (added)
to the list of visited rules (L<visited_rules>) and also all of its causes
will be added to the top of the L<goals_to_check_dict> and it will start
reading again all the goals.

If there's the case where the goal doesn't exist as a goal in the rules then
it will ask the user (via L<ask_about()>) for the existence of it. If user is
not sure about it then the algorithm ends.

=back

=cut
sub backward {
    my ($self) = @_;

    my ($more_goals, $current_goal, $total_goals) = (
            1,
            0,
            scalar(@{$self->{'goals_to_check'}}));
    
    WAIT_FOR_MORE_GOALS: while($more_goals) {
        READ_GOAL: while(my $goal = $self->{'goals_to_check_dict'}->iterate) {
            if ($self->is_goal_in_our_facts($goal)) {
                $self->{'viewer'}->debug("The goal $goal is in our facts")
                    if $self->{'debug'};
                # Matches with any visiited rule?
                my $rule_no = $self->{'goals_to_check_dict'}->get_value(
                        $goal, 'rule');
                # Take out this goal so we don't end with an infinite loop
                $self->{'viwer'}->debug("Removing $goal from goals to check")
                    if $self->{'debug'};
                $self->{'goals_to_check_dict'}->remove($goal);
                # Update the iterator
                $self->{'goals_to_check_dict'}->populate_iterable_array();
                # no more goals, what about rules?  
                if ($self->{'visited_rules'}->size() eq 0) {
                    $self->{'viewer'}->debug("No more goals to read")
                        if $self->{'verbose'};
                    $more_goals = 0;
                    next WAIT_FOR_MORE_GOALS;
                }
                if (defined $rule_no) {
                    my $causes_total = $self->{'visited_rules'}->get_value(
                            $rule_no, 'causes_total');
                    my $causes_pending = $self->{'visited_rules'}->get_value(
                            $rule_no, 'causes_pending');
                    if (defined $causes_total and defined $causes_pending) {
                        # No more pending causes for this rule, lets shoot it
                        if ($causes_pending-1 le 0) {
                            my $last_rule = $self->remove_last_visited_rule();
                            if ($last_rule eq $rule_no) {
                                $self->{'viewer'}->debug("Going to shoot $last_rule")
                                    if $self->{'debug'};
                                $self->shoot($last_rule, 'backward');
                            } else {
                                $self->{'viewer'}->print_error(
                                        "Seems the rule ($rule_no) of goal " .
                                        "$goal is not the same as the last " .
                                        "visited rule ($last_rule)");
                                $more_goals = 0;
                                next WAIT_FOR_MORE_GOALS;
                            }
                        } else {
                            $self->{'visited_rules'}->update($rule_no,
                                    {
                                        causes_pending => $causes_pending-1
                                    });
                        }
                    }
                }
                # How many objetives we have? if we are zero then we are done
                if ($self->{'goals_to_check_dict'}->size() lt 0) {
                    $more_goals = 0;
                } else {
                    $more_goals = 1;
                }
                # Re verify if there are more goals to check
                next WAIT_FOR_MORE_GOALS;
            } else {
                # Ugh, the fact is not in our inference facts or asked facts,
                # well, lets find the rule where this fact belongs
                my $rule_of_goal =  $self->get_rule_by_goal($goal);
                if (defined $rule_of_goal) {
                    $self->{'viewer'}->debug("Found a rule with $goal as a goal")
                        if $self->{'debug'};
                    # Causes of this rule
                    my $rule_causes = $self->get_causes_by_rule($rule_of_goal);
                    # Copy the causes of this rule to our goals to check
                    $self->copy_to_goals_to_check($rule_of_goal, $rule_causes);
                    # We just *visited* this rule, lets check it
                    $self->visit_rule($rule_of_goal, $rule_causes->size());
                    # and yes.. we have more goals to check!
                    $self->{'goals_to_check_dict'}->populate_iterable_array();
                    $more_goals = 1;
                    next WAIT_FOR_MORE_GOALS;
                } else {
                    # Ooops, lets ask about this
                    # We usually get to this case when any of the copied causes
                    # does not exists as a goal in any of the rules
                    my $answer = $self->ask_about($goal);
                    if (
                            $answer eq FACT_SIGN_POSITIVE or
                            $answer eq FACT_SIGN_NEGATIVE) {
                        $self->{'asked_facts'}->append($goal,
                                {
                                    name => $goal,
                                    sign => $answer,
                                    algorithm => 'backward'
                                });
                    } else {
                        $self->{'viewer'}->debug(
                                "Don't know of $goal, nothing else to check"
                                );
                        return 0;
                    }
                    $self->{'goals_to_check_dict'}->populate_iterable_array();
                    $more_goals = 1;
                    next WAIT_FOR_MORE_GOALS;
                }
            }
        }
    }
    return 1;
}

=head2 B<mixed()>

As its name says, it's a mix of L<forward()> and L<backward()> algorithms, it
requires to have at least one initial fact.

The first thing it does is to run the L<forward()> algorithm (hence the need of
at least one initial fact). If the algorithm fails then the mixed algorithm
also ends unsuccessfully.

Once the first I<run> of L<forward()> algorithm happens it starts looking for
any positive inference fact, if only one is found then this ends the algorithm
with the assumption it knows what's happening.

In case no positive inference fact is found then it will start reading the
rules and creating a list of intuitive facts.

For each rule it will get a I<certainty factor> of its causes versus the
initial, inference and asked facts. In case the certainity factor is greater or
equal than L<found_factor> then all of its goals will be copied to the
intuitive facts (eg, read it as: it assumes the goals have something to do with
our first initial facts).

Once all the rules are read then it verifies if there are intuitive facts, if
no facts are found then it ends with the intuition, otherwise it will run the
L<backward()> algorithm for each one of these facts (eg, each fact will be
converted to a goal). After each I<run> of the L<backward()> algorithm it will
verify for any positive inference fact, if just one is found then the algorithm
ends.

At the end (if there are still no positive inference facts) it will run the
L<forward()> algorithm and restart (by looking again for any positive inference
fact).

A good example to understand how this algorithm is useful is: imagine you are
a doctor and know some of the symptoms of a patient. Probably with the first
symptoms you have you can get to a positive conclusion (eg that a patient has
I<X> disease). However in case there's still no clue, then a set of questions
(done by the call of L<backward()>) of symptons related to the initial symptoms
will be asked to the user. For example, we know that that the patient has a
headache but that doesn't give us any positive answer, what if the patient has
flu or another disease? Then a set of these I<related> symptons will be asked
to the user.

=cut
sub mixed {
    my ($self) = @_;

    if (!$self->forward()) {
        $self->{'viewer'}->print_error("The first execution of forward failed");
        return 0;
    }

    use Data::Dumper;

    while(1) {
        # We are satisfied if only one inference fact is positive (eg, means we
        # got to our result)
        while(my $fact = $self->{'inference_facts'}->iterate) {
            my $sign = $self->{'inference_facts'}->get_value($fact, 'sign');
            if ($sign eq FACT_SIGN_POSITIVE) {
                $self->{'viewer'}->debug(
                        "We are done, a positive fact was found"
                        );
                return 1;
            }
        }

        my $intuitive_facts = AI::ExpertSystem::Advanced::Dictionary->new(
                stack => []);

        my ($more_rules, $current_rule) = (1, undef);
        while($more_rules) {
            $current_rule = $self->{'knowledge_db'}->get_next_rule($current_rule);

            # No more rules?
            if (!defined $current_rule) {
                $self->{'viewer'}->debug("We are done with all the rules, bye")
                    if $self->{'verbose'};
                $more_rules = 0;
                last;
            }

            # Wait, we already shot this rule?
            if ($self->is_rule_shot($current_rule)) {
                $self->{'viewer'}->debug("We already shot rule: $current_rule")
                    if $self->{'verbose'};
                next;
            }

            my $factor = $self->get_causes_match_factor($current_rule);
            if ($factor ge $self->{'found_factor'} && $factor lt 1.0) {
                # Copy all of the goals (usually only one) of the current rule to
                # the intuitive facts
                my $goals = $self->get_goals_by_rule($current_rule);
                while(my $goal = $goals->iterate_reverse) {
                   $intuitive_facts->append($goal,
                           {
                               name => $goal,
                               sign => $goals->get_value($goal, 'sign')
                           });
               }
            }
        }
        if ($intuitive_facts->size() eq 0) {
            $self->{'viewer'}->debug("Done with intuition") if
                $self->{'verbose'};
            return 1;
        }
        
        $intuitive_facts->populate_iterable_array();

        # now each intuitive fact will be a goal
        while(my $fact = $intuitive_facts->iterate) {
            $self->{'goals_to_check_dict'}->append(
                    $fact,
                    {
                        name => $fact,
                        sign => $intuitive_facts->get_value($fact, 'sign')
                    });
            $self->{'goals_to_check_dict'}->populate_iterable_array();
            print "Running backward for $fact\n";
            if (!$self->backward()) {
                $self->{'viewer'}->debug("Backward exited");
                return 1;
            }
            # Now we have inference facts, anything positive?
            $self->{'inference_facts'}->populate_iterable_array();
            while(my $inference_fact = $self->{'inference_facts'}->iterate) {
                my $sign = $self->{'inference_facts'}->get_value(
                        $inference_fact, 'sign');
                if ($sign eq FACT_SIGN_POSITIVE) {
                    $self->{'viewer'}->print(
                            "Done, a positive inference fact found"
                            );
                    return 1;
                }
            }
        }
        $self->forward();
    }
}

=head2 B<summary($return)>

The main purpose of any expert system is the ability to explain: what is
happening, how it got to a result, what assumption(s) it required to make,
the fatcs that were excluded and the ones that were used.

This method will use the L<viewer> (or return the result) in YAML format of all
the rules that were shot. It will explain how it got to each one of the causes
so a better explanation can be done by the L<viewer>.

If C<$return> is defined (eg, it got any parameter) then the result wont be
passed to the L<viewer>, instead it will be returned as a string.

=cut
sub summary {
    my ($self, $return) = @_;

    # any facts we found via inference?
    if (scalar @{$self->{'inference_facts'}->{'stack'}} eq 0) {
        $self->{'viewer'}->print_error("No inference was possible");
    } else {
        my $summary = {};
        # How the rules started being shot?
        my $order = 1;
        # So, what rules we shot?
        foreach my $shot_rule (sort(keys %{$self->{'shot_rules'}})) {
            $summary->{'rules'}->{$shot_rule} = {
                order => $order,
            };
            $order++;
            # Get the causes and goals of this rule
            my $causes = $self->get_causes_by_rule($shot_rule);
            $causes->populate_iterable_array();
            while(my $cause = $causes->iterate) {
                # How we got to this cause? Is it an initial fact,
                # an inference fact? or by forward algorithm?
                my ($method, $sign, $algorithm);
                if ($self->{'asked_facts'}->find($cause)) {
                    $method = 'Question';
                    $sign = $self->{'asked_facts'}->get_value($cause, 'sign');
                    $algorithm = $self->{'asked_facts'}->get_value($cause, 'algorithm');
                } elsif ($self->{'inference_facts'}->find($cause)) {
                    $method = 'Inference';
                    $sign = $self->{'inference_facts'}->get_value($cause, 'sign');
                    $algorithm = $self->{'inference_facts'}->get_value($cause, 'algorithm');
                } elsif ($self->{'initial_facts_dict'}->find($cause)) {
                    $method = 'Initial';
                    $sign = $self->{'initial_facts_dict'}->get_value($cause, 'sign');
                } else {
                    $method = 'Forward';
                    $sign = $causes->get_value($cause, 'sign');
                }
                $summary->{'rules'}->{$shot_rule}->{'causes'}->{$cause} = {
                    method => $method,
                    sign => $sign,
                    algorithm => $algorithm,
                };
            }

            my $goals = $self->get_goals_by_rule($shot_rule);
            $goals->populate_iterable_array();
            while(my $goal = $goals->iterate) {
                # We got to this goal by asking the user of it? or by
                # "natural" backward algorithm?
                my ($method, $sign, $algorithm);
                if ($self->{'asked_facts'}->find($goal)) {
                    $method = 'Question';
                    $sign = $self->{'asked_facts'}->get_value($goal, 'sign');
                } elsif ($self->{'inference_facts'}->find($goal)) {
                    $method = 'Inference';
                    $sign = $self->{'inference_facts'}->get_value($goal, 'sign');
                    $algorithm = $self->{'inference_facts'}->get_value($goal, 'algorithm');
                } else {
                    $method = 'Backward';
                    $sign = $goals->get_value($goal, 'sign');
                }
                $summary->{'rules'}->{$shot_rule}->{'goals'}->{$goal} = {
                    method => $method,
                    sign => $sign,
                    algorithm => $algorithm,
                }
            }
        }
        my $yaml_summary = Dump($summary);
        if (defined $return) {
            return $yaml_summary;
        } else {
            $self->{'viewer'}->explain($yaml_summary);
        }
    }
}

# No need to document this, this is an *internal* Moose method, used when an
# instance of the class has been created and all the verifications (of valid
# parameters) have been done.
sub BUILD {
    my ($self) = @_;

    if (!defined $self->{'viewer'}) {
        if (defined $self->{'viewer_class'}) { 
            $self->{'viewer'} = AI::ExpertSystem::Advanced::Viewer::Factory->new(
                    $self->{'viewer_class'});
        } else {
            confess "Sorry, provide a viewer or a viewer_class";
        }
    }
    $self->{'initial_facts_dict'} = AI::ExpertSystem::Advanced::Dictionary->new(
            stack => $self->{'initial_facts'});
    $self->{'inference_facts'} = AI::ExpertSystem::Advanced::Dictionary->new;
    $self->{'asked_facts'} = AI::ExpertSystem::Advanced::Dictionary->new;
    $self->{'goals_to_check_dict'} = AI::ExpertSystem::Advanced::Dictionary->new(
            stack => $self->{'goals_to_check'});
    $self->{'visited_rules'} = AI::ExpertSystem::Advanced::Dictionary->new(
            stack => []);
}

=head1 SEE ALSO

Take a look L<AI::ExpertSystem::Simple> too.

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

