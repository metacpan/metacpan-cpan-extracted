package Beagle::Cmd::Command::cat;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'raw' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'raw content(with proper encoding)',
    traits        => ['Getopt'],
);

has 'real-raw' => (
    isa           => 'Bool',
    is            => 'rw',
    accessor      => 'real_raw',
    documentation => 'raw content',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/cat show read/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    $args = $self->resolve_ids( $args );
    die "beagle cat id [...]" unless @$args;

    my $first = 1;
    for my $i (@$args) {
        my @ret = resolve_entry($i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }

        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id = $ret[0]->{id};
        my $bh = $ret[0]->{handle};
        my $entry = $ret[0]->{entry};

        puts '=' x term_width() unless $first;
        undef $first if $first;

        if ( $self->verbose ) {
            my $atts = $bh->attachments_map->{ $id };
            if ($atts) {
                puts "attachments: ", join( ', ', keys %$atts );
            }

            my $comments = $bh->comments_map->{ $id };
            if ($comments) {
                puts "comments: ", join( ', ', keys %$comments );
            }
        }

        if ( $self->raw ) {
            puts decode_utf8( $entry->content() );
        }
        elsif ( $self->real_raw ) {
            print $entry->content();
        }
        else {
            puts $entry->serialize(
                $self->verbose
                ? (
                    type      => 1,
                    path      => 1,
                    created   => 1,
                    updated   => 1,
                    id        => 1,
                    format    => 1,
                    parent_id => 1,
                  )
                : (
                    type    => 1,
                    path    => undef,
                    created => undef,
                    updated => undef,
                    id      => undef,
                )
            );
        }

        my $comments = $bh->comments_map->{ $id };
        if ($comments) {
            for my $id (
                sort { $comments->{$a}->created cmp $comments->{$b}->created }
                keys %$comments )
            {
                my $comment = $comments->{$id};
                puts '#' x 8, " comment: $id by " . $comment->author . "\n",
                  $comment->body;
            }
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::cat - show entries

=head1 SYNOPSIS

    $ beagle cat id1     # show content of entry id1
    $ beagle show id1    # ditto
    $ beagle cat id1 id2 # show both id1 and id2
    $ beagle cat id1 --raw       # show content in file(with proper encoding)
    $ beagle cat id1 --real-raw  # show content in file(no encoding tweak)

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

