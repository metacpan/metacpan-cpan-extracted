# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with person data in TagDBs

package Data::TagDB::Plugin::Person;

use v5.16;
use strict;
use warnings;

use Data::TagDB::Interface::Plugin;
use Data::TagDB::Relation;
use Data::TagDB::Metadata;
use Data::TagDB::Tag;
use Data::Identifier;
use Data::Identifier::Generate;
use List::Util qw(any);
use Carp;

use parent 'Data::Identifier::Interface::Known';

our $VERSION = v0.01.01;

my @_wk;

my %_normalised_sex_icons = (
    male            => "\N{MALE SIGN}",
    female          => "\N{FEMALE SIGN}",
    hermaphrodite   => "\N{MALE AND FEMALE SIGN}",
);

{
    my %sexes = (
            #  gender                               sex                                  gender-or-sex
        male    => [
            qw(3694d8ca-c969-5705-beca-01f17b1487e8 ae1072ef-0865-5104-b257-0d45441fa5e5 d642eff3-bee6-5d09-aea9-7c47b181dd83), # utag
            Data::Identifier->new(wd => 'Q6581097'),
            Data::Identifier->new(fc => 'Q18'),
        ],
        female  => [
            qw(25dfeb8e-ef9a-52a1-b5f1-073387734988 3c4b6cdf-f5a8-50d6-8a3a-b0c0975f7e69 db9b0db1-a451-59e8-aa3b-9994e683ded3), # utag
            Data::Identifier->new(wd => 'Q6581072'),
            Data::Identifier->new(fc => 'Q17'),
        ],
        gynomorph => [
            qw(bb3c1e47-b251-51c8-9014-d66aa6df6139 a804402b-9ce8-55e4-b05c-9fec29d602a5 bd13b902-1506-537e-b1dd-15ef5fba70b2), # utag
        ],
        andromorph => [
            qw(814f4fe5-74cd-57a7-9c28-4a912d639497 f334601b-0074-5e9c-8bad-3f4b9d2156a4 a41e15d5-a23c-5b2f-9268-294eb14d6573), # utag
        ],
        hermaphrodite => [
            qw(310f2b49-73a8-5f27-aeaf-5f34bc8e583f 036c0fe8-5189-5134-99ec-0b1b05c7bbf4 643a9df0-c635-57f5-84f6-68c160899829), # utag
        ],
    );
    foreach my $sex (keys %sexes) {
        foreach my $ise (@{$sexes{$sex}}) {
            my $tag = Data::Identifier->new(from => $ise)->register;
            push(@_wk, $tag);

            $tag->userdata(__PACKAGE__, sex => $sex);
        }
    }
}

{
    my @humans = map {$_->register} (
        Data::Identifier->new(uuid => 'dcf8f4f0-c15e-44bd-ad76-0d483079db16', tagname => 'human'),
        Data::Identifier->new(wd => 'Q5'),
        Data::Identifier->new(fc => 'Q7'),
    );
    push(@_wk, @humans);
    $_->userdata(__PACKAGE__, is_human => 1) foreach @humans;
}

{
    my $wd_Q5 = Data::Identifier->new(wd => 'Q5');
    my $fc_Q7 = Data::Identifier->new(fc => 'Q7');
    my %extra_is = (
        is_body         => [qw(5501e545-f39a-4d62-9f65-792af6b0ccba), $wd_Q5, $fc_Q7],
        is_character    => [qw(a331f2c5-20e5-4aa2-b277-8e63fd03438d), $wd_Q5, $fc_Q7],
        is_account      => [qw(b72508ba-7fb9-42ae-b4cf-b850b53a16c2)],
        is_legal_entity => [qw(f57f5e00-1d08-4731-b49b-c8316e23f06a)],
        is_person       => [qw(f6249973-59a9-47e2-8314-f7cf9a5f77bf), $wd_Q5, $fc_Q7],
    );
    my %ids;

    foreach my $is (keys %extra_is) {
        foreach my $ise (@{$extra_is{$is}}) {
            my $tag = Data::Identifier->new(from => $ise)->register;
            $ids{$tag->ise} = $tag;
            $tag->userdata(__PACKAGE__, $is => 1);
        }
    }

    push(@_wk, map {$_->register} values %ids);
}

my %_wk = (
    (map {$_->tagname =~ tr/-/_/r => $_} (
            Data::Identifier->new(uuid => '7f265548-81dc-4280-9550-1bd0aa4bf748', tagname => 'has-type'),
            Data::Identifier->new(uuid => 'd2750351-aed7-4ade-aa80-c32436cc6030', tagname => 'also-has-role'),
            Data::Identifier->new(uuid => 'a942ba41-20e6-475e-a2c1-ce891f4ac920', tagname => 'also-identifies-as'),
            Data::Identifier->new(uuid => 'ac14b422-e7eb-4e5b-bccd-ad5a65aeab96', tagname => 'also-is-identified-as'),
            Data::Identifier->new(uuid => 'e48cd5c6-83d7-411e-9640-cb370f3502fc', tagname => 'implies'),
            Data::Identifier->new(uuid => 'd926eb95-6984-415f-8892-233c13491931', tagname => 'tag-links'),
            Data::Identifier->new(uuid => '115c1bcf-02cd-4a57-bd02-1d9f1ea8dd01', tagname => 'any-taxon'),
            Data::Identifier->new(uuid => '69c01148-aab1-4c72-b857-6e53a301c96f', tagname => 'species'),
            Data::Identifier->new(uuid => '63644280-affc-44fd-9911-bf36048a69e9', tagname => 'bodytype'),
            Data::Identifier->new(uuid => 'bdf10f25-46ef-42fa-b588-dba84e6de9ef', tagname => 'anthro'),
            Data::Identifier->new(uuid => 'ab573786-73bc-4f5c-9b03-24ef8a70ae45', tagname => 'generator_request'),
            Data::Identifier->new(uuid => '806d6eec-ce92-464b-93f2-b83cfb73df03', tagname => 'relative-of'),
            Data::Identifier->new(uuid => '5ecb4562-dad7-431d-94a6-d301dcea8d37', tagname => 'parent'),
            Data::Identifier->new(uuid => '80034bca-2b6a-47b7-b7ec-a280103316bb', tagname => 'father'),
            Data::Identifier->new(uuid => '9828fdbb-6c15-4fe9-86bc-11df79f692ed', tagname => 'mother'),
            Data::Identifier->new(uuid => '1a9215b2-ad06-4f4f-a1e7-4cbb908f7c7c', tagname => 'child'),
            #Data::Identifier->new(uuid => '', tagname => ''),
        )),
    (map {'wd_'.$_ => Data::Identifier->new(wd => $_)}
        qw(Q729),
        qw(P21 P31 P22 P25 P40 P1038 P3373 P3448),
    ),
    (map {'fc_'.$_ => Data::Identifier->new(fc => $_)}
        qw(Q421315),
        qw(P141 P142 P150 P154),
    ),
);
push(@_wk, map {$_->register} values %_wk);

my %_relatives_relations = (
    relative  => [[qw(relative_of wd_P22 wd_P25 wd_P40 wd_P1038 wd_P3373 wd_P3448)]],
    father    => [[qw(father wd_P22 fc_P141)]],
    mother    => [[qw(mother wd_P25 fc_P142)]],
    parent    => [[qw(parent wd_P22 wd_P25 wd_P3448 fc_P141 fc_P142)]],
    child     => [[qw(child wd_P40 fc_P150)], [qw(parent)]],
);


# Person attributes from SimCat:
#   displaysex, displaysexicon, displayspecies, displaybodytype, relatives
# Also related:
#   subtags, supertags
# Not included:
#   dateing relevant for date of birth and date of death calculation

# Helpers to be considered:
#   is_male, is_female, is_human, is_animal

# Notes on gender matching:
#   FOAF:   male, female
#   vCard:  M stands for "male", F stands for "female", O stands for "other", N stands for "none or not applicable", U stands for "unknown".
#   GTE:    .0: male, .1: female, .2: gynomorph, .3: andromorph, .4: herm, .12: other, .13: genderless, .14: undefined, .15: invalid
#   SGTE:   MFHCSmfhcs

# Notes on body type:
#   SGTE:   FAfa

# ---- Private helpers ----

sub plugin_attach {
    my ($pkg, $db, $conf, %opts) = @_;

    return {
        tag_attributes => {
            displaysex => {
                get => sub {
                    my ($tag) = @_;
                    my $sub = __SUB__;
                    my $db = $tag->db;
                    my $v;

                    # New style:
                    $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(also_identifies_as also_is_identified_as wd_P21 fc_P154)}])->foreach(sub {
                            my Data::TagDB::Relation $link = $_[0];
                            my Data::TagDB::Tag $related = $link->related;
                            my Data::Identifier $di = $related->as('Data::Identifier');
                            $v = $related if defined $di->userdata(__PACKAGE__, 'sex');
                        });

                    unless (defined $v) {
                        # Old style, linked:
                        $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(implies tag_links)}])->foreach(sub {
                                my Data::TagDB::Relation $link = $_[0];
                                my Data::TagDB::Tag $related = $link->related;
                                my Data::Identifier $di = $related->as('Data::Identifier');
                                if ($di->userdata(__PACKAGE__, 'sex')) {
                                    $v = $related;
                                } elsif (!defined $v) {
                                    eval {$v = ($sub->($related))[0]->[0]};
                                }
                            });
                    }

                    unless (defined $v) {
                        foreach my $key (qw(body character)) {
                            my $subtag = $tag->get('Data::TagDB::Plugin::Person#'.$key, default => undef) // next;
                            $v = $subtag->get('Data::TagDB::Plugin::Person#displaysex', default => undef) // next;
                            last;
                        }
                    }

                    return [$v], no_value => !defined($v);
                },
            },
            displaysex_icon => {
                get => sub {
                    my ($tag) = @_;
                    my $displaysex = $tag->get('Data::TagDB::Plugin::Person#displaysex', default => undef);
                    my $v;

                    if (defined $displaysex) {
                        my $sex = $displaysex->as('Data::Identifier')->userdata(__PACKAGE__, 'sex') // '__UNKNOWN__';

                        if (defined($v = $_normalised_sex_icons{$sex})) {
                        } else {
                            $v = $displaysex->icontext(default => undef);
                        }
                    }

                    return [$v], no_value => !defined($v);
                },
            },
            displayspecies => {
                get => sub {
                    my ($tag) = @_;
                    return _displayspecies_like($tag, [@_wk{qw(any_taxon species wd_Q729 fc_Q421315)}], 'displayspecies');
                },
            },
            is_human => {
                get => sub {
                    my ($tag) = @_;
                    my $species = $tag->get('Data::TagDB::Plugin::Person#displayspecies', as => 'Data::Identifier', default => undef);

                    return [undef], no_value => 1 unless defined $species;

                    return [!!$species->userdata(__PACKAGE__, 'is_human')];
                },
            },
            displaybodytype => {
                get => sub {
                    my ($tag) = @_;
                    my ($v, %extra) = _displayspecies_like($tag, [@_wk{qw(bodytype)}], 'displaybodytype');

                    return $v, %extra unless $extra{no_value};

                    if ($tag->get('Data::TagDB::Plugin::Person#is_human', default => undef)) {
                        return [$tag->db->tag_by_id($_wk{anthro})];
                    }

                    return [undef], no_value => 1;
                },
            },
            entity => {
                get => sub {
                    my ($tag) = @_;

                    if ($tag->get('Data::TagDB::Plugin::Person#is_legal_entity') || $tag->get('Data::TagDB::Plugin::Person#is_person')) {
                        return [$tag];
                    } else {
                        my $db = $tag->db;
                        my $v;

                        $db->metadata(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(generator_request)}])->foreach(sub {
                                my Data::TagDB::Metadata $link = $_[0];
                                my $parent = eval {$db->tag_by_id(uuid => $link->data_raw) } // return;
                                $v = $parent if $parent->get('Data::TagDB::Plugin::Person#is_legal_entity') || $parent->get('Data::TagDB::Plugin::Person#is_person');
                            });

                        unless (defined $v) {
                            # Old style and links:
                            $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(implies tag_links)}])->foreach(sub {
                                    my Data::TagDB::Relation $link = $_[0];
                                    my Data::TagDB::Tag $related = $link->related;
                                    if (!defined $v) {
                                        eval {$v = $related->get('Data::TagDB::Plugin::Person#entity')};
                                    }
                                });
                        }

                        return [$v], no_value => !defined($v);
                    }
                },
            },
            body => {
                get => sub {
                    my ($tag) = @_;

                    if ($tag->get('Data::TagDB::Plugin::Person#is_body')) {
                        return [$tag];
                    } else {
                        my $v;

                        eval {
                            my $entity = $tag->get('Data::TagDB::Plugin::Person#entity');
                            my $di = Data::Identifier::Generate->generic(
                                request => $entity,
                                style => 'tag-based',
                                namespace => '02513f26-d6ff-4107-98a8-2c9cb492115b',
                                generator => 'd511f370-0e49-42d5-ad18-bf280dc97e08',
                            );
                            $v = $tag->db->tag_by_id($di);
                        };

                        return [$v] if defined $v;
                    }

                    return [undef], no_value => 1;
                },
            },
            character => {
                get => sub {
                    my ($tag) = @_;

                    if ($tag->get('Data::TagDB::Plugin::Person#is_character')) {
                        return [$tag];
                    } else {
                        my $v;
                        eval {
                            my $entity = $tag->get('Data::TagDB::Plugin::Person#entity');
                            my $di = Data::Identifier::Generate->generic(
                                request => $entity,
                                style => 'tag-based',
                                namespace => 'bd3136b7-56f2-48a3-b206-fd2bd96551d5',
                                generator => 'bd1a1966-2e71-43cc-a7ce-f7a4547df450',
                            );
                            $v = $tag->db->tag_by_id($di);
                        };

                        return [$v] if defined $v;
                    }

                    return [undef], no_value => 1;
                },
            },
            is_non_binary => {
                get => sub {
                    my ($tag) = @_;
                    my $displaysex = $tag->get('Data::TagDB::Plugin::Person#displaysex', default => undef);

                    if (defined $displaysex) {
                        my $sex = $displaysex->as('Data::Identifier')->userdata(__PACKAGE__, 'sex');
                        if (defined $sex) {
                            return [$sex ne 'male' && $sex ne 'female'];
                        }
                    }

                    return [undef], no_value => 1;
                },
            },
            (map {my $x = $_relatives_relations{$_}; $_ => {get => sub {
                            return _relatives($_[0], @{$x});
                        }}} keys %_relatives_relations),
            (map {my $x = $_; 'is_'.$_ => {get => sub {
                            my ($tag) = @_;
                            my $displaysex = $tag->get('Data::TagDB::Plugin::Person#displaysex', default => undef);

                            if (defined $displaysex) {
                                my $sex = $displaysex->as('Data::Identifier')->userdata(__PACKAGE__, 'sex');
                                if (defined $sex) {
                                    return [$sex eq $x];
                                }
                            }

                            return [undef], no_value => 1;
                        }}} qw(male female gynomorph andromorph hermaphrodite)),
            (map {my $x = $_; $_ => {get => sub {
                            my ($tag) = @_;
                            my $cl = $tag->cloudlet('roles');

                            foreach my $role ($cl->entries) {
                                return [1] if $role->as('Data::Identifier')->userdata(__PACKAGE__, $x);
                            }
                            return [0];
                        }}} qw(is_body is_character is_account is_legal_entity is_person)),
        },
    };
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return (\@_wk) if $class eq ':all';
    croak 'Unsupported class';
}

sub _displayspecies_like {
    my ($tag, $roles, $reqkey, $done) = @_;
    my $db = $tag->db;
    my $v;

    $done //= {};
    return [undef], no_value => 1 if $done->{$tag->dbid};
    $done->{$tag->dbid} = 1;

    $roles = [map {$_->as('Data::TagDB::Tag', db => $db)} @{$roles}];

    # New style:
    $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(also_identifies_as also_is_identified_as)}])->foreach(sub {
            my Data::TagDB::Relation $link = $_[0];
            my Data::TagDB::Tag $related = $link->related;
            if ($related->has_role(any => $roles)) {
                $v = $related;
            }
        });

    unless (defined $v) {
        # Old style, linked:
        $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(implies tag_links)}])->foreach(sub {
                my Data::TagDB::Relation $link = $_[0];
                my Data::TagDB::Tag $related = $link->related;
                if ($related->has_role(any => $roles)) {
                    $v = $related
                } elsif (!defined $v) {
                    eval {$v = (_displayspecies_like($related, $roles, $reqkey, $done))[0]->[0]};
                }
            });
    }

    unless (defined $v) {
        # Wikidata style:
        my $cl = $tag->cloudlet('roles');
        outer:
        foreach my $role ($cl->roots, $cl->entries) {
            foreach my $req (@{$roles}) {
                if (any {$req->dbid == $_->dbid} $role, $role->cloudlet('specialises')->entries) {
                    $v = $role;
                    last outer;
                }
            }
        }
    }

    if (!defined($v) && defined($reqkey)) {
        foreach my $key (qw(body character)) {
            my $subtag = $tag->get('Data::TagDB::Plugin::Person#'.$key, default => undef) // next;
            next if $subtag->dbid == $tag->dbid;
            $v = $subtag->get('Data::TagDB::Plugin::Person#'.$reqkey, default => undef) // next;
            last;
        }
    }

    return [$v], no_value => !defined($v);
}

sub _relatives {
    my ($tag, $wk, $extra_inverse) = @_;
    my $db = $tag->db;
    my $inverse_relation = $db->wk->inverse_relation;
    my @relations;
    my @relations_inverse;
    my %v;
    my %self;

    {
        my %relations;
        foreach my $toplevel_di (@_wk{@{$wk}}) {
            my $toplevel = $db->tag_by_id($toplevel_di);
            foreach my $subtag ($toplevel, $toplevel->cloudlet('generalises')->entries) {
                $relations{$subtag->dbid} = $subtag;
            }
        }
        @relations = values %relations;
    }

    {
        my %relations_inverse;

        foreach my $relation (@relations) {
            $relations_inverse{$_->dbid} = $_ foreach $db->relation(tag => $relation, relation => $inverse_relation)->collect('related');
        }

        if (defined $extra_inverse) {
            foreach my $toplevel_di (@_wk{@{$extra_inverse}}) {
                my $toplevel = $db->tag_by_id($toplevel_di);
                foreach my $subtag ($toplevel, $toplevel->cloudlet('generalises')->entries) {
                    $relations_inverse{$subtag->dbid} = $subtag;
                }
            }
        }

        @relations_inverse = values %relations_inverse;
    }

    foreach my $superbasetag ($tag, $db->relation(tag => $tag, relation => [map {$db->tag_by_id($_)} @_wk{qw(implies tag_links)}])->collect('tag')) {
        foreach my $basetag (
            $superbasetag,
            eval {$superbasetag->get('Data::TagDB::Plugin::Person#body', default => undef)},
            eval {$superbasetag->get('Data::TagDB::Plugin::Person#character', default => undef)},
        ) {
            next unless defined $basetag;
            next if $self{$basetag->dbid};
            $self{$basetag->dbid} = 1;
            $db->relation(tag => $basetag, relation => \@relations)->foreach(sub {
                    my Data::TagDB::Relation $link = $_[0];
                    my Data::TagDB::Tag $related = $link->related;
                    $v{$related->dbid} = $related;
                }) if scalar @relations;
            $db->relation(related => $basetag, relation => \@relations_inverse)->foreach(sub {
                    my Data::TagDB::Relation $link = $_[0];
                    my Data::TagDB::Tag $related = $link->tag;
                    $v{$related->dbid} = $related;
                }) if scalar @relations_inverse;
        }
    }

    return [values %v];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Plugin::Person - Work with person data in TagDBs

=head1 VERSION

version v0.01.01

=head1 SYNOPSIS

    use Data::TagDB;

    $db->load_plugin('Data::TagDB::Plugin::Person');

    $db->migration->include('Data::TagDB::Plugin::Person'); # must be after load_plugin() or use!

This is a plugin for L<Data::TagDB>. See there for details on plugins.

=head1 SETUP

This module exports a number of tags related to person data via L<Data::Identifier::Interface::Known>.

If used it is recommended to include this module in calls to L<Data::TagDB::Migration/include> on database setups and general upgrades.

Calls to this module may C<die> if the required tags are not found in the database.

=head1 ATTRIBUTES

This plugin currently only provides tag attrubutes.

B<Note:>
Most attributes are meant for display purpose only.
They should not be considered absolute truth.
It should be avoided to compare them to fixed lists.
There are some boolean attributes (C<is_*>) included to aid matching if needed.

B<Note:>
This module uses the term I<sex> as synonymous with I<gender>.
As such attributes are also variant over culture and time they might
return unexpected values (e.g. a non-binary sex),
a list where a single value might be expected (e.g. transgender over time),
or logically unexpected values (e.g. female father in cultures where the gender is defined by social role).

It is therefore best to accept lists (or handle exceptions for lists correctly),
and test using the attribute that is closest to the actual question
(e.g. I<do> test with C<is_male>, and I<don't> test with C<displaysex> and compare to male).

=head2 TAG ATTRIBUTES

=head3 displaysex

    my Data::TagDB::Tag $displaysex = $tag->get('Data::TagDB::Plugin::Person#displaysex');

(experimental since v0.01.01)

Gets the sex (or gender) of the tag.
This might also be supported on tags that do not represent persons.

The returned value is not normalised.

=head3 displaysex_icon

    my $displaysex_icon = $tag->get('Data::TagDB::Plugin::Person#displaysex_icon');

(experimental since v0.01.01)

Gets the sex (or gender) of the tag as a unicode character.
This is partly normalised.

B<Note:>
Do B<NOT> use this to try to match a sex!

=head3 displayspecies

    my Data::TagDB::Tag $displayspecies = $tag->get('Data::TagDB::Plugin::Person#displayspecies');

(experimental since v0.01.01)

Gets the species of the tag in question.
The value is not normalised.

=head3 displaybodytype

    my Data::TagDB::Tag $displaybodytype = $tag->get('Data::TagDB::Plugin::Person#displaybodytype');

(experimental since v0.01.01)

Gets the bodytype (e.g. andromorph or feral) of the tag in question.

B<Note:>
This will return a form of andromorph for any human.

=head3 is_human

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_human');

(experimental since v0.01.01)

Returns whether the tag represents a human. Will C<die> if unknown.

=head3 entity

    my Data::TagDB::Tag $entity = $tag->get('Data::TagDB::Plugin::Person#entity');

(experimental since v0.01.01)

Returns the (proto-)entity tag for this tag. Returns the tag itself if it is already the corresponding (proto-)entity. Will C<die> if unknown.

=head3 body

    my Data::TagDB::Tag $body = $tag->get('Data::TagDB::Plugin::Person#body');

(experimental since v0.01.01)

Returns the body tag for this tag. Returns the tag itself if it is already the corresponding body. Will C<die> if unknown.

A body tag is used to hold information about the physical body of a person only.
Fictional persons usually have no body tag.

=head3 character

    my Data::TagDB::Tag $character = $tag->get('Data::TagDB::Plugin::Person#character');

(experimental since v0.01.01)

Returns the character tag for this tag. Returns the tag itself if it is already the corresponding character. Will C<die> if unknown.

A character tag is used to hold information about the identity, culture, and self-image of a person only.

=head3 relative

    my @relatives = $tag->get('Data::TagDB::Plugin::Person#relative', list => 1);

(experimental since v0.01.01)

Returns an unorderd unranked list of relatives as tags.

=head3 father

    my @fathers = $tag->get('Data::TagDB::Plugin::Person#father', list => 1);

(experimental since v0.01.01)

Returns the list of fathers of a person. This list can contain more than one entry (e.g. adoptive father).

=head3 mother

    my @mothers = $tag->get('Data::TagDB::Plugin::Person#mother', list => 1);

(experimental since v0.01.01)

Returns the list of mothers of a person. This list can contain more than one entry (e.g. adoptive mother).

=head3 parent

    my @parents = $tag->get('Data::TagDB::Plugin::Person#parent', list => 1);

(experimental since v0.01.01)

Returns the list of parents of a person. This list can contain any number of entries.
It might contain more entries than the lists of fathers and mothers combined.

=head3 child

    my @child = $tag->get('Data::TagDB::Plugin::Person#cild', list => 1);

(experimental since v0.01.01)

Returns the list of children of a person.

=head3 is_male

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_male');

(experimental since v0.01.01)

Returns whether the tag represents a male. Will C<die> if unknown.
Note that both this and L</is_female> might be true or false at the same time.

=head3 is_female

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_female');

(experimental since v0.01.01)

Returns whether the tag represents a female. Will C<die> if unknown.
Note that both this and L</is_male> might be true or false at the same time.

=for comment is_gynomorph, is_andromorph, is_hermaphrodite

=head3 is_non_binary

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_female');

(experimental since v0.01.01)

Returns whether the tag represents not a male nor a female. Will C<die> if unknown.

B<Note:>
This is different from unknown, and inapplicable values.
It is defined as any known sex that is different from male and female.

=head3 is_body

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_body');

(experimental since v0.01.01)

Returns whether the tag represents a body tag. Will C<die> if unknown.

=head3 is_character

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_character');

(experimental since v0.01.01)

Returns whether the tag represents a character tag. Will C<die> if unknown.

=head3 is_account

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_account');

(experimental since v0.01.01)

Returns whether the tag represents an account tag. Will C<die> if unknown.
An account tag is different as it represents an account in some system (e.g. an online service).
It does not represent a person, even if the account is linked to a person.

B<Note:>
A simple test to tell accounts and persons apart: an account can be closed but not die, a person can die but not closed.

=head3 is_legal_entity

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_legal_entity');

(experimental since v0.01.01)

Returns whether the tag represents a legal entity tag. Will C<die> if unknown.
A legal entity is any entity that is not a person. Common cases are companies.

B<Note:>
A simple test to tell accounts and legal entities apart:
Persons work I<in> a legal entity, they I<use> an account to do so.

=head3 is_person

    my $bool = $tag->get('Data::TagDB::Plugin::Person#is_person');

(experimental since v0.01.01)

Returns whether the tag represents a person tag. Will C<die> if unknown.
A person represents a being, dead or alive, real or fictional.

B<Note:>
Humans are persons, but so are all animals.
Also (other notable) entities from other kingdoms of life are tagged as a person, such as a notable tree.
To check for humans specifically, use L</is_human>.

B<Note:>
Persons are also called natural entities in contrast to legal entities.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
