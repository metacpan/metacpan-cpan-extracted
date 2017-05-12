package Beagle::Cmd::Command::mv;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => 'm',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $name = pop @$args;
    die "beagle mv id [...] name" unless defined $name;

    $args = $self->resolve_ids( $args );
    die "beagle mv id [...] name" unless @$args;

    my @created;
    my $relation;

    my $to_root = name_root($name) or die "no such beagle with name: $name";
    require Beagle::Handle;
    my $to = Beagle::Handle->new( root => $to_root );

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handle};
        my $entry = $ret[0]->{entry};
        if ( $bh->name eq $to->name ) {
            warn "$id is already in $name";
            next;
        }

        if ( $to->create_entry( $entry, commit => 0 ) ) {
            my $atts = $bh->attachments_map->{ $entry->id };
            if ($atts) {
                for my $att ( values %$atts ) {
                    $to->create_entry( $att, commit => 0 )
                      or die "failed to create attachment: " . $att->name;
                }
            }
            my $comments = $bh->comments_map->{ $entry->id };
            if ($comments) {
                for my $comment ( values %$comments ) {
                    $to->create_entry( $comment, commit => 0 )
                      or die "failed to create comment: " . $comment->id;
                }
            }
            if ( !$bh->delete_entry( $entry, commit => 0 ) ) {
                die "failed to delete entry " . $entry->id;
            }
            push @created, { id => $entry->id, from => $bh };
        }
        else {
            die "failed to create entry " . $entry->id;
        }
    }

    if (@created) {
        my $msg = join ' ', 'moved', join( ', ', map { $_->{id} } @created ),
          'to', $to->name;
        $to->backend->commit( message => $self->message || $msg );

        my @handles = uniq map { $_->{from} } @created;
        for my $bh (@handles) {
            $bh->backend->commit( message => $self->message || $msg );
        }

        puts $msg . '.';
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::mv - move entries to another beagle

=head1 SYNOPSIS

    $ beagle mv id1 id2 foo

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

