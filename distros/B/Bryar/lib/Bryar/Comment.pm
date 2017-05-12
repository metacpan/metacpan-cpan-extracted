package Bryar::Comment;
use base 'Bryar::Document'; # It sort-of is.
use Time::Piece;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.1';

=head1 NAME

Bryar::Comment - Represents a comment on a blog post

=head1 SYNOPSIS

	$self->new(...);

	$self->content();     # Get (clean version of) content
	$self->epoch();       # Get epoch
    $self->timepiece();   # Get the date as a Time::Piece object
	$self->author();      # Get author
	$self->url();         # Get author URL
    $self->id             # ID of blog document this is attached to

=head1 DESCRIPTION

This encapsulates a comment on a particular blog posting. Inherits
from L<Bryar::Document> for convenience.

=head1 METHODS

=head2 new

    $self->new(%params)

Creates a new Bryar::Comment instance. 

=cut


sub new {
    my $class = shift;
    my %args;
    { no warnings; %args = @_; } # turn off mumbling about uninitialised list
    my $self = bless {
        epoch =>  $args{epoch} ,
        content =>  $args{content} ,
        author =>  $args{author} ,
        url =>  $args{url} ,
        id => $args{id},
    }, $class;
    return $self;
}


=head2 content

	$self->content();    # Get content

Gets the value of the comment's content

=cut

sub content {
    my $self = shift;
    # Tidy content here!
    return $self->{content};
}

=head2 url

	$self->url();    # Get url

Gets a URL provided by the author.

=cut

sub url {
    my $self = shift;
    return $self->{url};
}

1;

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.


=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

some parts Copyright 2007 David Cantrell C<david@cantrell.org.uk>


=head1 SEE ALSO

L<Bryar::Document>
