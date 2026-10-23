# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Gamebook data in TagDBs

package Data::TagDB::Plugin::Gamebook;

use v5.10;
use strict;
use warnings;

use Data::TagDB::Interface::Plugin;
use Data::TagDB::Relation;
use Data::TagDB::Metadata;
use Data::TagDB::Cloudlet;
use Data::TagDB::Tag;
use Data::Identifier;
use Carp;

use parent 'Data::Identifier::Interface::Known';

use Data::TagDB::Plugin::Gamebook::Exit;

our $VERSION = v0.01;

my %_wk = map {$_->tagname =~ tr/-/_/r =~ s/^gamebook_/gb_/r => $_->register} (
    Data::Identifier->new(uuid => '7f265548-81dc-4280-9550-1bd0aa4bf748', tagname => 'has-type'),
    Data::Identifier->new(uuid => 'd2750351-aed7-4ade-aa80-c32436cc6030', tagname => 'also-has-role'),
    Data::Identifier->new(uuid => '923b43ae-a50e-4db3-8655-ed931d0dd6d4', tagname => 'specialises'),
    Data::Identifier->new(uuid => '10a65258-237f-45f5-9d84-7287d62dcbb5', tagname => 'gamebook-application-context'),
    Data::Identifier->new(uuid => 'bad2f56f-5ea7-4725-bcd0-60be71cf3768', tagname => 'gamebook-valuefile-format'),
    Data::Identifier->new(uuid => '3c9f48a4-5c35-49d0-8908-1c9e1853fa1e', tagname => 'gamebook-type'),
    Data::Identifier->new(uuid => '4cb471e3-c921-44a6-9fba-3d19f45aab35', tagname => 'gamebook-vocabulary'),
    Data::Identifier->new(uuid => '330436f2-91f1-4422-8f0a-4b804a37f101', tagname => 'gamebook-vocabulary-base'),
    Data::Identifier->new(uuid => 'ef7b2199-7cca-4efb-96bb-d18795546973', tagname => 'gamebook-role-marker'),
    Data::Identifier->new(uuid => '1357f4c9-0419-4493-8d2c-97c6a40a9bc9', tagname => 'gamebook-has-title'),
    Data::Identifier->new(uuid => 'def9538d-b193-4144-9389-008f3fb23633', tagname => 'gamebook-has-text'),
    Data::Identifier->new(uuid => '2b3b7539-4dc2-43d1-afb9-974cda48ae82', tagname => 'gamebook-has-content'),
    Data::Identifier->new(uuid => '564e3dc6-aef7-4103-863a-aa88dd04204c', tagname => 'gamebook-index-listed'),
    Data::Identifier->new(uuid => 'c333b55a-77e6-4cda-bf36-73f6e99a20bc', tagname => 'gamebook-pagelike'),
    Data::Identifier->new(uuid => '82b47919-bc0c-47e0-953e-81f6c5833860', tagname => 'gamebook-eventlike'),
    Data::Identifier->new(uuid => 'c9eec21d-a9b0-4818-99fe-fa4d24c43352', tagname => 'gamebook-book'),
    Data::Identifier->new(uuid => '316850a0-abf1-4b07-abeb-1386c2f19a0f', tagname => 'gamebook-story'),
    Data::Identifier->new(uuid => '39a3b6ae-0388-4ae5-97a6-1938b7a41db7', tagname => 'gamebook-scene'),
    Data::Identifier->new(uuid => '148c356a-ce5e-4a72-9e1e-7f30d3d38e21', tagname => 'gamebook-exit'),
    Data::Identifier->new(uuid => 'f66e0cd2-852e-4a01-8c52-881430f4d8b3', tagname => 'gamebook-object-group'),
    Data::Identifier->new(uuid => '1acdb1f1-1b0f-42ba-9de7-a8f4e0f4d6c1', tagname => 'gamebook-relation'),
    Data::Identifier->new(uuid => '8b919a2a-1dee-458d-b2fe-f646573ad4e6', tagname => 'gamebook-title'),
    Data::Identifier->new(uuid => '0678cfe2-1386-43db-86a9-6c491b2df64c', tagname => 'gamebook-text'),
    Data::Identifier->new(uuid => 'ee451ce6-fa8e-4879-ad02-18e480ee3da7', tagname => 'gamebook-role'),
    Data::Identifier->new(uuid => '26541fcc-3248-48c8-a157-efb263b5d719', tagname => 'gamebook-contains'),
    Data::Identifier->new(uuid => '9bfe73f4-c3ca-464c-8e46-548931aa1571', tagname => 'gamebook-target'),
    Data::Identifier->new(uuid => '64df20b4-3a22-4054-881c-e750cdabf850', tagname => 'gamebook-direction'),
    Data::Identifier->new(uuid => '103769a6-efdc-4088-a128-fc655da2d2ae', tagname => 'gamebook-available-context'),
    Data::Identifier->new(uuid => 'd8273dea-3cb2-48f1-8f50-559bbb12bf69', tagname => 'gamebook-scroll-thru'),
    Data::Identifier->new(uuid => '53b7716b-65b1-4268-88e5-81f4c997f0ea', tagname => 'gamebook-direct-speech'),
    Data::Identifier->new(uuid => 'd4fad62f-7e02-49ac-b9c6-4417aca0c45e', tagname => 'gamebook-direction-marker'),
    Data::Identifier->new(uuid => '95fc948e-b9a3-46b8-a120-68858df1c96e', tagname => 'gamebook-uses-vocabulary'),
    Data::Identifier->new(uuid => 'f6c29c2e-d667-44fb-b1fb-4b18e1a5ef7d', tagname => 'gamebook-uses-cache-vocabulary'),
);


# ---- Private helpers ----

sub plugin_attach {
    my ($pkg, $db, $conf, %opts) = @_;

    return {
        tag_attributes => {
            title => {
                get => sub {
                    my ($tag) = @_;
                    my Data::TagDB $db = $tag->db;
                    my $v;

                    foreach my $wk (map {$_wk{$_}} qw(gb_title)) {
                        $db->metadata(tag => $tag, relation => $db->tag_by_id($wk))->foreach(sub {
                                my Data::TagDB::Metadata $link = $_[0];
                                $v //= $link->data;
                            });
                        last if defined $v;
                    }

                    unless (defined $v) {
                        $db->relation(tag => $tag, relation => $db->tag_by_id($_wk{gb_target}))->foreach(sub {
                                my Data::TagDB::Relation $link = $_[0];
                                $v //= $link->related->get('Data::TagDB::Plugin::Gamebook#title', default => undef);
                            });
                    }

                    return [$v], no_value => !defined($v);
                },
            },
            text => {
                get => sub {
                    my ($tag) = @_;
                    my Data::TagDB $db = $tag->db;
                    my @v;

                    $db->metadata(tag => $tag, relation => $db->tag_by_id($_wk{gb_text}))->foreach(sub {
                            my Data::TagDB::Metadata $link = $_[0];
                            push(@v, $link->data);
                        });

                    return \@v;
                },
            },
            exit => {
                get => sub {
                    my ($tag) = @_;
                    my Data::TagDB $db = $tag->db;
                    my Data::TagDB::Tag $exit = $db->tag_by_id($_wk{gb_exit});
                    my @v;

                    $db->relation(tag => $tag, relation => $db->tag_by_id($_wk{gb_contains}))->foreach(sub {
                            my Data::TagDB::Relation $link = $_[0];
                            my Data::TagDB::Tag $related = $link->related;
                            my Data::TagDB::Cloudlet $roles = $related->cloudlet('roles');
                            push(@v, Data::TagDB::Plugin::Gamebook::Exit->_new($related)) if $roles->is_entry($exit);
                        });

                    return \@v;
                },
            },
        },
    };
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return ([values %_wk]) if $class eq ':all';
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Plugin::Gamebook - Work with Gamebook data in TagDBs

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::TagDB;

    $db->load_plugin('Data::TagDB::Plugin::Gamebook');

    $db->migration->include('Data::TagDB::Plugin::Gamebook'); # must be after load_plugin() or use!

This is a plugin for L<Data::TagDB>. See there for details on plugins.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
