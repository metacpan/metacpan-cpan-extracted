package App::RoboBot::Plugin::Social::Skills;
$App::RoboBot::Plugin::Social::Skills::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Text::Wrap qw( wrap );
use Try::Tiny;

extends 'App::RoboBot::Plugin';

=head1 social.skills

Provides functions for managing skillsets and user proficiency levels. These
proficiencies can then be queried by other users on the same network to find
help or advice.

=cut

has '+name' => (
    default => 'Social::Skills',
);

has '+description' => (
    default => 'Provides functions for managing skillsets and user proficiency levels.',
);

=head2 iknow

Assigns or displays skill proficiency levels for the current user.

=head3 Description

Assigns a proficiency level to yourself for the named skill. If no skill is
named, shows a list of all skills you possess (grouped by proficiency levels).

Skills which do not already exist will be automatically created. As such, it is
recommended that users attempt to follow local naming conventions whenever
possible.

=head3 Usage

[<skill name> [<proficiency level>]]

=head3 Examples

    (iknow Perl novice)

=head2 theyknow

Displays all of the registered skills of the named person. You cannot modify
another user's skills or proficiencies.

=head3 Usage

<nick>

=head3 Examples

    (theyknow Beauford)

=head2 idontknow

=head3 Description

Unregisters your proficiency in the named skill.

=head3 Usage

<skill name>

=head3 Examples

    (idontknow Perl)

=head2 whoknows

=head3 Description

For the named skill, displays all the users who have registered a proficiency.
Users are grouped together by proficiency level and displayed in order. If the
skill has a description or any related skills, those are listed as well.

If multiple skills are provided as arguments, then the intersection of users
having registered proficiencies in them will be displayed.

=head3 Usage

<skill name> [<skill name> ...]

=head3 Examples

    (whoknows Perl)
    (whoknows Perl Apache PostgreSQL)

=head2 skills

=head3 Description

Displays the list of all skills currently registered by at least one person on
the current network, if called with no arguments. Each skill in the list will
also be shown with the number of people who claim to have some proficiency.

If called with a string argument, that value will be used to display only those
skills which contain the value as a substring. Searching is case-insensitive.

=head3 Usage

[<search string>]

=head3 Examples

    (skills)
    (skills sql)

=head2 skill-add

=head3 Description

Adds a new entry to the skills database, without registering any proficiency
level on your behalf. If the skill already exists, nothing is done.

Note that only skills with at least one registered user on the current network
will be displayed when someone searches or displays the skill list.

=head3 Usage

<skill name>

=head3 Examples

    (skill-add Perl)

=head2 skill-levels

=head3 Description

Displays the list of proficiency levels available for use when registering your
knowledge of a given skill. The proficiency levels are displayed in increasing
order with brief descriptions of each one.

=head3 Examples

    (skill-levels)

=head2 describe-skill

=head3 Description

Permits the addition of a description to a skill. Descriptions are free-form
strings, limited only by the current network's message length limits and
formatting options. Because these descriptions are displayed every single time
someone looks up the skill, it's recommended to keep them brief and to the
point.

=head3 Usage

<skill name> <description>

=head3 Examples

    (describe-skill PostgreSQL "An object-relational database management system.")

=head2 relate-skills

=head3 Description

Relating two skills causes the related skill to be shown whenever the other is
displayed. Related skills are not displayed with their registered users, but
simply referenced as potentially interesting additional skills for the querier
to investigate.

Multiple related skills may be listed and they will all, in turn, be connected
to the original skill.

=head3 Usage

<skill name> <related skill name> [<related skill name> ...]

=head3 Examples

    (relate-skills PostgreSQL SQL)
    (relate-skills Puppet CM Python)

=head2 clear-skills

=head3 Description

Clears the skills list for the given user. It would be wise for most instances
of this software to restrict access to this function via (auth-deny).

=head3 Usage

<nick>

=cut

has '+commands' => (
    default => sub {{
        'iknow' => { method      => 'skill_know',
                     description => 'Assigns a proficiency level to yourself for the named skill. If no skill is named, shows a list of all skills you possess.',
                     usage       => '[<skill name> [<proficiency name or number>]]' },

        'theyknow' => { method      => 'skill_theyknow',
                        description => 'Displays all of the registered skills of the named person. You cannot modify another user\'s skills or proficiencies.',
                        usage       => '<nick>' },

        'idontknow' => { method      => 'skill_dontknow',
                         description => 'Removes you from the list of people with any proficiency in the named skill.',
                         usage       => '<skill name>' },

        'whoknows' => { method      => 'skill_whoknows',
                        description => 'Shows a list of all the people who claim any proficiency in the named skill. Listing multiple skills will perform an intersection and display only those people who have registered knowledge in all of the named skills (along with their average proficiency).',
                        usage       => '<skill name>' },

        'skills' => { method      => 'skill_list',
                      description => 'Returns a list of all skills. You may optionally provide a regular expression so that only matching skills are returned.',
                      usage       => '[<pattern>]', },

        'skill-add' => { method      => 'skill_add',
                         description => 'Adds a new skill to the collection.',
                         usage       => '<skill name>', },

        'skill-levels' => { method      => 'skill_levels',
                            description => 'Displays and manages the enumeration of skill proficiencies.' },

        'describe-skill' => { method      => 'describe_skill',
                              description => 'Allows for the addition of descriptive text to a skill, to be shown whenever the skill is queried via (whoknows).',
                              usage       => '<skill name> "<description>"',
                              example     => 'SQL "Structured Query Language; the most common interface language used for interacting with relational databases."' },

        'relate-skills' => { method      => 'relate_skills',
                             description => 'Creates a relationship between multiple skills. Related skills will show up in the output of (whoknows). Note that this function creates one-way relationships, since they are more often relevant than assuming a two-way relationship. In other words, (relate-skills Oracle SQL) to indicate SQL is related to Oracle is more relevant than (relate-skills SQL Oracle) implying that the product Oracle is relevant to general questions about SQL.',
                             usage       => '<parent skill name> <related skill name>',
                             example     => 'NodeJS Javascript' },

        'clear-skills' => { method      => 'clear_skills',
                            description => 'Clears the skills list for the given user.',
                            usage       => '<nick>' },
    }},
);

sub clear_skills {
    my ($self, $message, $command, $rpl, $nick) = @_;

    unless (defined $nick && $nick =~ m{\w+}o) {
        $message->response->raise('Must provide a nick whose skills you wish to remove.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        delete from skills_nicks
        where nick_id = (select id from nicks where lower(name) = lower(?))
    }, $nick);

    unless ($res) {
        $self->log->error(sprintf('Failed to delete nick skills: %s', $res->error));
        $message->response->raise('Could not remove skills for nick %s.', $nick);
        return;
    }

    $message->response->push(sprintf('Removed %d skills for nick %s.', $res->count(), $nick));
}

sub relate_skills {
    my ($self, $message, $command, $rpl, $skill, @skills) = @_;

    unless (defined $skill && $skill =~ m{\w+}) {
        $message->response->raise('You must provide a parent skill name.');
        return;
    }

    unless (@skills && scalar(@skills) > 0) {
        $message->response->raise('You must provide at least one related skill name.');
        return;
    }

    $skill = $self->bot->config->db->do(q{
        select *
        from skills_skills
        where lower(name) = lower(?)
    }, $skill);

    unless ($skill && $skill->next) {
        $message->response->raise('No matching skill. Please try again.');
        return;
    }

    my @related;

    foreach my $name (@skills) {
        # Lookup the related skill first to get the properly-capitalized version
        # of the name, and to ensure it's a real skill.
        my $rel = $self->bot->config->db->do(q{
            select skill_id, name
            from skills_skills
            where lower(name) = lower(?)
        }, $name);

        unless ($rel && $rel->next) {
            $message->response->raise('There is currently no skill for %s. Please check the name and try again.', $name);
            next;
        }

        # Blindly ignore any duplicate errors.
        my $res = $self->bot->config->db->do(q{
            insert into skills_related (skill_id, related_id) values
            ( ?, ? )
        }, $skill->{'skill_id'}, $rel->{'skill_id'});

        push(@related, $rel->{'name'});
    }

    if (@related > 0) {
        $message->response->push(sprintf('%s has been given the related skill(s): %s', $skill->{'name'}, join(', ', @related)));
    }

    return;
}

sub describe_skill {
    my ($self, $message, $command, $rpl, $skill, @args) = @_;

    unless (defined $skill && $skill =~ m{\w}) {
        $message->response->raise('You must provide a skill name.');
        return;
    }

    my $desc = join(' ', grep { defined $_ && $_ =~ m{\w+} } @args);

    unless (defined $desc && length($desc) > 0) {
        $message->response->raise('You must provide a description of the skill.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        update skills_skills
        set description = ?
        where lower(?) = lower(name)
        returning *
    }, $desc, $skill);

    unless ($res && $res->next) {
        $message->response->raise('Could not add a description to the skill "%s". Please make sure the skill exists and try again.', $skill);
        return;
    }

    $message->response->push(sprintf('Description for %s has been updated.', $skill));
    return;
}

sub skill_dontknow {
    my ($self, $message, $command, $rpl, @skills) = @_;

    unless (@skills) {
        $message->response->push('Must supply skill name(s) to remove.');
        return;
    }

    foreach my $skill (@skills) {
        next unless defined $skill && $skill =~ m{\w+};

        my $res = $self->bot->config->db->do(q{
            delete from skills_nicks
            where nick_id = ?
                and skill_id = ( select skill_id
                                 from skills_skills
                                 where lower(?) = lower(name) )
        }, $message->sender->id, $skill);

        unless ($res && $res->count > 0) {
            $message->response->push(sprintf("You didn't know %s before.", $skill));
            next;
        }

        $message->response->push(sprintf("You have now forgotten %s.", $skill));
    }

    return;
}

sub skill_know {
    my ($self, $message, $command, $rpl, $skill_name, $skill_level) = @_;

    unless (defined $skill_name && $skill_name =~ m{\w+}) {
        my @skills = $self->show_user_skills($message, $message->sender->id);

        if (@skills < 1) {
            $message->response->push('You have no registered skills.');
            return;
        } else {
            $message->response->push('You have the following skills registered:', @skills);
            return;
        }
    }

    my ($res, $level_id, $level_name);

    # We have a skill name (and unknown skills will be added automatically), but we need
    # to figure out what skill level they want to register at. Provided, but invalid,
    # skill levels are an error, unprovided levels default to the lowest by sort_order.
    if (defined $skill_level && $skill_level =~ m{.+}) {
        no warnings 'numeric';

        $res = $self->bot->config->db->do(q{
            select level_id, name
            from skills_levels
            where level_id = ? or lower(name) = lower(?)
            order by sort_order desc
            limit 1
        }, int($skill_level), $skill_level);

        if ($res && $res->next) {
            ($level_id, $level_name) = ($res->{'level_id'}, $res->{'name'});
        } else {
            $message->response->raise('The proficiency level "%s" does not appear to be valid. Check (skill-levels) for the known list.', $skill_level);
            return;
        }
    } else {
        $res = $self->bot->config->db->do(q{
            select level_id, name
            from skills_levels
            order by sort_order asc
            limit 1
        });

        unless ($res && $res->next) {
            $message->response->raise('Could not determine the default proficiency level.');
            return;
        }

        ($level_id, $level_name) = ($res->{'level_id'}, $res->{'name'});
    }

    $res = $self->bot->config->db->do(q{
        select skill_id, name
        from skills_skills
        where lower(name) = lower(?)
    }, $skill_name);

    my ($skill_id);

    if ($res && $res->next) {
        $skill_id = $res->{'skill_id'};
    } else {
        $res = $self->bot->config->db->do(q{
            insert into skills_skills ??? returning skill_id
        }, { name => $skill_name, created_by => $message->sender->id });

        unless ($res && $res->next) {
            $message->response->raise('Could not create the new skill. Please try again.');
            return;
        }

        $message->response->push(sprintf('The skill "%s" was newly added to the collection.', $skill_name));
        $skill_id = $res->{'skill_id'};
    }

    $res = $self->bot->config->db->do(q{
        select *
        from skills_nicks
        where skill_id = ? and nick_id = ?
    }, $skill_id, $message->sender->id);

    if ($res && $res->next) {
        $res = $self->bot->config->db->do(q{
            update skills_nicks
            set skill_level_id = ?
            where skill_id = ? and nick_id = ?
        }, $level_id, $skill_id, $message->sender->id);

        if ($res) {
            $message->response->push(sprintf('Your proficiency in "%s" has been changed to %s.', $skill_name, $level_name));
            return;
        } else {
            $message->response->raise('Could not update your proficiency in "%s". Please try again.', $skill_name);
            return;
        }
    } else {
        $res = $self->bot->config->db->do(q{
            insert into skills_nicks ???
        }, { skill_id => $skill_id, skill_level_id => $level_id, nick_id => $message->sender->id });

        if ($res) {
            $message->response->push(sprintf('Your proficiency in "%s" has been registered as %s.', $skill_name, $level_name));
            return;
        } else {
            $message->response->raise('Could not register your proficiency in "%s". Please try again.', $skill_name);
            return;
        }
    }

    return;
}

sub skill_theyknow {
    my ($self, $message, $command, $rpl, $targetname) = @_;

    my $res = $self->bot->config->db->do(q{
        select id, name
        from nicks
        where lower(name) = lower(?)
    }, $targetname);

    unless ($res && $res->next) {
        $message->response->raise('%s is not known to me.', $targetname);
        return;
    }

    my ($nick_id, $nick_name) = ($res->{'id'}, $res->{'name'});

    my @skills = $self->show_user_skills($message, $nick_id);

    if (@skills < 1) {
        $message->response->push(sprintf('%s does not have any skills registered. Pester them to add a few!', $nick_name));
    } else {
        $message->response->push(sprintf('%s has registered the following skills:', $nick_name), @skills);
    }

    return;
}

sub show_user_skills {
    my ($self, $message, $nick_id) = @_;

    my $res = $self->bot->config->db->do(q{
        select l.name, array_agg(s.name) as skills
        from skills_nicks n
            join skills_levels l on (l.level_id = n.skill_level_id)
            join skills_skills s on (s.skill_id = n.skill_id)
        where n.nick_id = ?
        group by l.name, l.sort_order
        order by l.sort_order asc
    }, $nick_id);

    unless ($res) {
        $message->response->raise('Could not retrieve skill list. Please try again.');
        return;
    }

    my @l;

    while ($res->next) {
        push(@l, sprintf('*%s:* %s', $res->{'name'}, join(', ', sort { lc($a) cmp lc($b) } @{$res->{'skills'}})));
    }

    return @l;
}

sub skill_whoknows {
    my ($self, $message, $command, $rpl, @skill_names) = @_;

    unless (@skill_names && @skill_names > 0) {
        $message->response->raise('You must supply at least one skill name.');
        return;
    }

    if (@skill_names > 1) {
        return $self->skill_whoknows_intersect($message, $command, $rpl, @skill_names);
    }

    my $skill_name = shift @skill_names;

    my $skill = $self->bot->config->db->do(q{
        select skill_id, name, description
        from skills_skills
        where lower(name) = lower(?)
    }, $skill_name);

    unless ($skill && $skill->next) {
        $message->response->push(sprintf('Nobody has yet claimed to know about %s.', $skill_name));
        return;
    }

    $message->response->push(sprintf('*%s*', $skill->{'name'}));
    $message->response->push(sprintf('%s', $skill->{'description'})) if $skill->{'description'};

    my $res = $self->bot->config->db->do(q{
        select s.name
        from skills_skills s
            join skills_related r on (s.skill_id = r.related_id)
        where r.skill_id = ?
        order by lower(s.name) asc
    }, $skill->{'skill_id'});

    if ($res) {
        my @related;

        while ($res->next) {
            push(@related, $res->{'name'});
        }

        if (@related > 0) {
            $message->response->push(sprintf('_Related skills:_ %s', join(', ', @related)));
        }
    }

    $res = $self->bot->config->db->do(q{
        select l.name, array_agg(n.name) as nicks
        from skills_nicks sn
            join skills_levels l on (l.level_id = sn.skill_level_id)
            join skills_skills s on (s.skill_id = sn.skill_id)
            join nicks n on (n.id = sn.nick_id)
        where lower(s.name) = lower(?)
        group by l.name, l.sort_order
        order by l.sort_order asc
    }, $skill_name);

    if ($res->count < 1) {
        $message->response->push(sprintf('Nobody has yet claimed to know about %s.', $skill_name));
        return;
    }

    while ($res->next) {
        $message->response->push(sprintf('*%s:* %s', $res->{'name'}, join(', ', sort { $a cmp $b } @{$res->{'nicks'}})));
    }

    return;
}

sub skill_whoknows_intersect {
    my ($self, $message, $command, $rpl, @skill_names) = @_;

    unless (@skill_names && @skill_names > 1) {
        $message->response->raise('Skill intersections require at least two skill names.');
        return;
    }

    my $num_skills = scalar @skill_names;

    my $res = $self->bot->config->db->do(q{
        select skill_id, name
        from skills_skills
        where lower(name) in ???
    }, [map { lc($_) } @skill_names]);

    unless ($res) {
        $message->response->raise('Could not retrieve skill data. Please try again.');
        return;
    }

    my %skills;
    while ($res->next) {
        $skills{$res->{'skill_id'}} = $res->{'name'};
    }

    unless (scalar(keys(%skills)) > 0) {
        $message->response->raise('No matching skills could be located.');
        return;
    }

    unless (scalar(keys(%skills)) == $num_skills) {
        $message->response->raise('Some of the skills you listed could not be found. Only the following were valid: %s',
            join(', ', sort { lc($a) cmp lc($b) } values %skills));
        return;
    }

    $res = $self->bot->config->db->do(q{
        with sk as (select array_agg(skill_id) as skillset from skills_skills where skill_id in ??? and true)
        select n.id, n.name, sk.skillset
        from skills_skills s
            join skills_nicks sn on (sn.skill_id = s.skill_id)
            join nicks n on (n.id = sn.nick_id),
            sk
        where s.skill_id in ???
        group by n.id, n.name, sk.skillset
        having sk.skillset <@ array_agg(s.skill_id)
    }, [keys %skills], [keys %skills]);

    unless ($res) {
        $message->response->raise('Could not locate skill intersection. Please try again.');
        return;
    }

    my @knowers;

    KNOWER:
    while ($res->next) {
        my $detail = $self->bot->config->db->do(q{
            select s.skill_id, s.name, sl.name as level, sl.sort_order
            from skills_nicks sn
                join skills_skills s on (s.skill_id = sn.skill_id)
                join skills_levels sl on (sl.level_id = sn.skill_level_id)
            where sn.nick_id = ? and s.skill_id in ???
            order by lower(s.name) asc
        }, $res->{'id'}, [keys %skills]);

        next unless $detail;

        push(@knowers, {
            nick_id => $res->{'id'},
            name    => $res->{'name'},
            average => 0,
            skills  => [],
        });

        while ($detail->next) {
            push(@{$knowers[-1]{'skills'}}, {
                name  => $detail->{'name'},
                level => $detail->{'level'},
            });
            $knowers[-1]{'average'} += $detail->{'sort_order'};
        }

        try {
            $knowers[-1]{'average'} = $knowers[-1]{'average'} / $num_skills;
        } catch {
            pop @knowers;
            next KNOWER;
        };

        $detail = $self->bot->config->db->do(q{
            select *
            from (  select name, sort_order
                    from skills_levels
                    where sort_order <= ?
                    order by sort_order desc
                    limit 1
                ) d1
            union
            select *
            from (  select name, sort_order
                    from skills_levels
                    order by sort_order asc
                    limit 1
                ) d2
            order by sort_order desc
            limit 1
        }, int($knowers[-1]{'average'}));

        if ($detail && $detail->next) {
            $knowers[-1]{'average_name'} = $detail->{'name'};
        } else {
            $knowers[-1]{'average_name'} = 'unknown';
        }
    }

    if (@knowers < 1) {
        $message->response->push('There is nobody who has registered knowing that set of skills. You might try again with fewer skills.');
        return;
    }

    $message->response->push(sprintf('The following people have registered knowledge in all of the following skills: %s',
        join(', ', sort { lc($a) cmp lc($b) } values %skills)));

    foreach my $user (sort { $b->{'average'} <=> $a->{'average'} || lc($a->{'name'}) cmp lc($b->{'name'}) } @knowers) {
        $message->response->push(sprintf('%s: *%s* (%s)', $user->{'name'}, $user->{'average_name'},
            join(', ', map { sprintf('%s _%s_', $_->{'name'}, lc($_->{'level'})) } @{$user->{'skills'}})));
    }

    return;
}

sub skill_add {
    my ($self, $message, $command, $rpl, @skills) = @_;

    my @existing;
    my @new;

    foreach my $skill (@skills) {
        my $res = $self->bot->config->db->do(q{
            select skill_id, name
            from skills_skills
            where lower(name) = lower(?)
        }, $skill);

        if ($res && $res->next) {
            push(@existing, $skill);
        } else {
            $res = $self->bot->config->db->do(q{
                insert into skills_skills ???
            }, { name => $skill, created_by => $message->sender->id });

            push(@new, $skill);
        }
    }

    if (@existing > 0) {
        $message->response->push(sprintf('The following skills were already known: %s', join(', ', sort { $a cmp $b } @existing)));
    }

    if (@new > 0) {
        $message->response->push(sprintf('The following skills were added to the collection: %s', join(', ', sort { $a cmp $b } @new)));
    }

    return;
}

sub skill_list {
    my ($self, $message, $command, $rpl, $pattern) = @_;

    my ($res);

    if (defined $pattern && $pattern =~ m{\w+}) {
        $res = $self->bot->config->db->do(q{
            select s.name, count(n.nick_id) as knowers
            from skills_skills s
                join skills_nicks n using (skill_id)
            where s.name ~* ?
            group by s.name
            order by s.name asc
        }, $pattern);
    } else {
        $res = $self->bot->config->db->do(q{
            select s.name, count(n.nick_id) as knowers
            from skills_skills s
                join skills_nicks n using (skill_id)
            group by s.name
            order by s.name asc
        });
    }

    unless ($res) {
        $message->response->raise('Could not retrieve list of skills. Please try again.');
        return;
    }

    my @skills;

    while ($res->next) {
        push(@skills, sprintf('%s (%d)', $res->{'name'}, $res->{'knowers'}));
    }

    if (@skills < 1) {
        $message->response->push('No matching skills could be located.');
        return;
    }

    $message->response->push(sprintf('%d%s skills have been registered:', scalar(@skills), (defined $pattern ? ' matching' : '')));

    local $Text::Wrap::columns = 120;
    @skills = split(/\n/o, wrap('','',join(', ', @skills)));
    $message->response->push($_) for @skills;

    $message->response->collapsible(1);

    return;
}

sub skill_levels {
    my ($self, $message, $command, $rpl) = @_;

    my $res = $self->bot->config->db->do(q{
        select name, description
        from skills_levels
        order by sort_order
    });

    $message->response->push('The following levels are available for use when registering your proficiency with a skill:');

    if ($res) {
        while ($res->next) {
            if ($res->{'description'}) {
                $message->response->push(sprintf('*%s*: %s', $res->{'name'}, $res->{'description'}));
            } else {
                $message->response->push($res->{'name'});
            }
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
