package Bookmarks::A9;
use base 'Bookmarks::Parser';
use WWW::A9Toolbar;
use warnings;

my %bookmark_fields = (
    'created'     => 'timestamp',
    'modified'    => undef,
    'visited'     => undef,                ## history ??
    'charset'     => undef,
    'url'         => 'url',
    'name'        => 'title',
    'id'          => 'guid',
    'description' => 'shortannotation',    ## diary?
    'expanded'    => undef,
    'trash'       => undef,
    'order'       => 'ordinal',
);

sub _parse_bookmarks {
    my ($self, $user, $passwd) = @_;

    $self->{a9} = WWW::A9Toolbar->new(
        {   email    => $user,
            password => $passwd,
            connect  => 1
        }
    );

    my @bookmarks = $self->{a9}->get_bookmarks();

    my $tree;

    foreach my $bm (@bookmarks) {
        push @{ $tree->{ $bm->{parentguid} } }, $bm;
    }

    my @children = @{ $tree->{0} };

    $self->_parse_children($tree, 'root', \@children);

}

sub _parse_children {
    my ($self, $tree, $parent, $children) = @_;

    foreach my $child (@$children) {
        next if ($child->{deleted} eq 'true');

        if ($child->{bmtype} eq 'folder') {
            _parse_children($child->{guid}, $tree->{ $child->{guid} });
            next;
        }

        my $item = {};
        $item->{name}        = $child->{title};
        $item->{url}         = $child->{url};
        $item->{created}     = $child->{timestamp} / 1000;
        $item->{description} = $child->{shortannotation};
        $item->{order}       = $child->{ordinal};
        $item->{id}          = $child->{guid};

        $self->add_bookmark($item, $parent);
    }
}

1;

=head1 NAME 

Bookmarks::A9 - style bookmarks.

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a subclass of L<Bookmarks::Parser> for handling A9 bookmarks.

=head1 METHODS

No public methods

=head1 AUTHOR

Jess Robinson <castaway@desert-island.demon.co.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
