package Bookmarks::XML;
use base 'Bookmarks::Parser';
use strict;
use warnings;
use XML::Simple;

sub new {
    my ($class, %opts) = @_;

    #    %opts = check_options(%opts);

    my $self = bless({%opts}, ref($class) || $class);
    return $self;
}

sub parse_file {
    my ($sel, $filename) = @_;

    return if (!$filename || !-e $filename);

    my $bookmarks = XMLin($filename, ForceArray => ['folder']);

}

sub get_header_as_string {
    my ($self) = @_;

    my $now    = scalar localtime;
    my $title  = $self->{_title} || 'Bookmarks';
    my $header = << "XML";
<?xml version="1.0" encoding="UTF-8"?>
<!--
Bookmarks::XML internal format
Created on: $now

-->
<bookmarks title="$title">
XML

    return $header;
}

sub get_item_as_string {
    my ($self, $item) = @_;

    if (!defined $item->{id} || !$self->{_items}{ $item->{id} }) {
        warn "No such item in get_item_as_string";
        return;
    }

    my $string = '';
    my ($id, $url, $name, $visited, $created, $modified, $icon, $desc,
        $expand, $trash, $order) = (
        $item->{id}          || 0,
        $item->{url}         || '',
        $item->{name}        || '',
        $item->{visited}     || 0,
        $item->{created}     || time(),
        $item->{modified}    || 0,
        $item->{icon}        || '',
        $item->{description} || '',
        $item->{expanded}    || '',
        $item->{trash}       || '',
        $item->{order}       || ''
        );

    if ($item->{type} eq 'folder') {
        $string .= << "XML";
  <folder id="$id" name="$name" created="$created" visited="$visited" icon="$icon" description="$desc" expanded="$expand" trash="$trash">
XML

        $string .= $self->get_item_as_string($self->{_items}{$_})
            foreach (@{ $item->{children} });
        $string .= "  </folder>\n";
    }
    elsif ($item->{type} eq 'url') {
        $string .= << "XML";
    <bookmark id="$id" url="$url" name="$name" created="$created" visited="$visited" modified="$modified" icon="$icon" description="$desc" order="$order" />
XML

    }

    return $string;
}

sub get_footer_as_string {
    my ($self) = @_;

    my $footer = << "XML";
</bookmarks>
XML

    return $footer;
}

1;

=head1 NAME

Bookmarks::Parser::XML - Backend for XML format

=head1 DESCRIPTION

This backend is completely untested, and probably does not work yet. use at own risk.
It will probably be replaced with an XBEL based backend in a future release.

=head1 METHODS

=head2 get_footer_as_string

=head2 get_header_as_string

=head2 get_item_as_string

=head2 new

=head2 parse_file

For these methods, consult L<Bookmarks::Parser> documentation.
They are overridden because of the XML behaviour here.
Interface remains the same.

=cut
