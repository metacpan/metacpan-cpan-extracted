#! perl

# Author          : Johan Vromans
# Created On      : Wed Aug 22 22:33:31 2007
# Last Modified By: Johan Vromans
# Last Modified On: Sat Mar 29 22:25:40 2014
# Update Count    : 7
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Note;

use strict;
use warnings;

our $VERSION = "1.005";

use Carp;
use App::Music::PlayTab::NoteMap qw(note_to_key key_to_note);

my $debug;

sub new {
    my $pkg = shift;
    $pkg = ref($pkg) || $pkg;
    bless {}, $pkg;
}

sub parse {
    my ($self, $note) = @_;

    # Parse note name and return internal code.
    $self = $self->new unless ref($self);

    # Trim.
    $note =~ s/\s+$//;
    $self->{unparsed} = $note;

    # Get out if relative scale specifier.
    return '*' if $note eq '*';	# TODO: Why?

    my $res;

    # Try sharp notes, e.g. Ais, C#.
    if ( $note =~ /^([a-g])(is|\#)$/i ) {
	$res = (note_to_key($1) + 1) % 12;
    }
    # Try flat notes, e.g. Es, Bes, Db.
    elsif ( $note =~ /^([a-g])(e?s|b)$/i ) {
	$res = (note_to_key($1) - 1) % 12;
	$self->{useflat} = 1;
    }
    # Try plain note, e.g. A, C.
    elsif ( $note =~ /^([a-g])$/i ) {
	$res = note_to_key($1);
    }

    # No more tries.
    unless ( defined $res ) {
	croak("Unrecognized note name \"$note\"");
    }

    # Return.
    $self->{key} = $res;
    $self;
}

sub transpose {
    my ($self, $xp) = @_;
    return $self unless $xp;
    $self->{key} = ($self->{key} + $xp) % 12;
    $self->{useflat} = $xp < 0;
    $self;
}

sub key {
    my $self = shift;
    $self->{key};
}

sub name {
    my $self = shift;
    App::Music::PlayTab::NoteMap::key_to_note($self->{key}, $self->{useflat});
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Note - Parse note names.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
