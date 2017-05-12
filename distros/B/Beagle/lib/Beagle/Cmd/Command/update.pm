package Beagle::Cmd::Command::update;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;
has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force to update even no changes in editor',
    traits        => ['Getopt'],
);

has 'set' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => 'm',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/update edit/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    $args = $self->resolve_ids( $args );

    die "beagle update id [...]" unless @$args;

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handle};
        my $entry = $ret[0]->{entry};

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $key, $value ) = split /=/, $item, 2;
                if ( $entry->can($key) ) {
                    $entry->$key( $entry->parse_field( $key, $value ) );
                }
                else {
                    warn "unknown key: $key";
                }
            }
        }

        if ( $self->edit || !$self->set ) {
            my $template = $entry->serialize(
                $self->verbose
                ? (
                    type      => 1,
                    path      => 1,
                    created   => 1,
                    updated   => 1,
                    id        => 1,
                    parent_id => 1,
                  )
                : (
                    type      => 1,
                    path      => undef,
                    created   => undef,
                    updated   => undef,
                    id        => undef,
                    parent_id => undef,
                )
            );

            my $message = '';
            if ( $self->message ) {
                $message = $self->message;
                $message =~ s!^!# !mg;
                $message .= newline();
            }

            $template = encode_utf8( $message . $template );
            my $updated = edit_text( $template );

            if ( !$self->force && $template eq $updated ) {
                puts "aborted.";
                return;
            }
            my $updated_entry =
              $entry->new_from_string( decode_utf8($updated),
                $self->verbose ? () : ( id => $entry->id ) );
            $updated_entry->original_path( $entry->original_path );

            unless ( $self->verbose ) {
                if ( $entry->can('parent_id') ) {
                    $updated_entry->parent_id( $entry->parent_id );
                }

                $updated_entry->created( $entry->created );
                $updated_entry->updated(time);
            }

            $updated_entry->timezone( $bh->info->timezone )
              if $bh->info->timezone;
            $entry = $updated_entry;
        }

        $entry->commit_message( $self->message )
          if $self->message && !$entry->commit_message;

        if ( $bh->update_entry( $entry ) ) {
            puts 'updated ', $entry->id, ".";
        }
        else {
            die "failed to update " . $entry->id . '.';
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::update - update entries

=head1 SYNOPSIS

    $ beagle update id1 id2 --set 'author=lisa@thesimpsons'
    $ beagle update id1 id2 --edit

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

