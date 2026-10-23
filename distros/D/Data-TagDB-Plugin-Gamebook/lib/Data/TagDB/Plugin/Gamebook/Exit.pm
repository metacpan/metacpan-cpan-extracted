# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Gamebook data in TagDBs, container for exits

package Data::TagDB::Plugin::Gamebook::Exit;

use v5.10;
use strict;
use warnings;

use Carp;

use parent 'Data::Identifier::Interface::Simple';

our $VERSION = v0.01;



#@returns Data::TagDB::Tag
sub tag {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{tag};
}


#@returns Data::TagDB
sub db {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{db} //= $self->{tag}->db;
}


sub label {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{label} //= $self->{tag}->get('Data::TagDB::Plugin::Gamebook#title') // croak 'No label found';
}


#@returns Data::TagDB::Tag
sub direction {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{direction} if defined $self->{direction};

    {
        my Data::TagDB $db = $self->db;
        my Data::TagDB::Relation $link = $db->relation(tag => $self->{tag}, relation => $db->tag_by_id(uuid => '64df20b4-3a22-4054-881c-e750cdabf850'))->one;
        return $self->{direction} //= $link->related;
    }
}


#@returns Data::TagDB::Tag
sub target_tag {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{target_tag} if defined $self->{target_tag};

    {
        my Data::TagDB $db = $self->db;
        my Data::TagDB::Relation $link = $db->relation(tag => $self->{tag}, relation => $db->tag_by_id(uuid => '9bfe73f4-c3ca-464c-8e46-548931aa1571'))->one;
        return $self->{target_tag} //= $link->related;
    }
}

# ---- Private helpers ----

sub _new {
    my ($pkg, $tag, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return bless {tag => $tag}, $pkg;
}

# Data::TagDB::Tag claims to be a Data::Identifier::Interface::Simple, so we just forward most things:

sub ise {
    my ($self, @args) = @_;
    return $self->{tag}->ise(@args);
}
sub as {
    my ($self, @args) = @_;
    return $self->{tag}->as(@args);
}
sub displayname {
    my ($self, @args) = @_;
    return $self->label unless scalar @args;
    return $self->{tag}->displayname(@args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Plugin::Gamebook::Exit - Work with Gamebook data in TagDBs, container for exits

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::TagDB;

    $db->load_plugin('Data::TagDB::Plugin::Gamebook');

    my @exits = $tag->get('Data::TagDB::Plugin::Gamebook#exit', list => 1);

(since v0.01)

This package represents an exit within a gamebook page-like object.

This package inherits from L<Data::Identifier::Interface::Simple> (since v0.01).

=head1 METHODS

=head2 tag

    my Data::TagDB::Tag $tag = $exit->tag;

(since v0.01)

Returns the tag representing this exit.

=head2 db

    my Data::TagDB $db = $exit->db;

(since v0.01)

Returns the database object for this exit.

=head2 label

    my $label = $exit->label;

(since v0.01)

The label that should be used with the exit.
This will die if no label can be found.

Later versions for this module might implement multi-language support or a variant that avoids dieing.

=head2 direction

    my Data::TagDB::Tag $direction = $exit->direction;

(experimental since v0.01)

Returns the direction of the exit.

The exact semantics of this call are subject to change.

=head2 target_tag

    my Data::TagDB::Tag $target_tag = $exit->target_tag;

(since v0.01)

Returns the target tag of the exit if any or die if none.

Later versions of this module might provide a variant without dieing.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
