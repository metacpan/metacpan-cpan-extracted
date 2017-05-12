package Beagle::Cmd::Command::rm;
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

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'delete even the id is ambiguous',
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/rm delete/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    $args = $self->resolve_ids( $args );

    die "beagle rm id [...]" unless @$args;

    my @deleted;
    my $relation;

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1 || $self->force;

        for my $ret (@ret) {
            my $id    = $ret->{id};
            my $bh    = $ret->{handle};
            my $entry = $ret->{entry};

            if ( $bh->delete_entry( $entry, message => $self->message ) ) {
                push @deleted, { handle => $bh, id => $entry->id };
            }
            else {
                die "failed to delete entry " . $entry->id;
            }
        }
    }

    if (@deleted) {
        my $msg = 'deleted ' . join( ', ', map { $_->{id} } @deleted );
        puts $msg . '.';
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::rm - delete entries

=head1 SYNOPSIS

    $ beagle rm id1 id2

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

