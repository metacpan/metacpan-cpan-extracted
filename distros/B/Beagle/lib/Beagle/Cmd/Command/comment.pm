package Beagle::Cmd::Command::comment;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has 'parent' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'parent id',
    cmd_aliases   => 'p',
    traits        => ['Getopt'],
);

has author => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'author',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force',
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => 'm',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
    traits        => ['Getopt'],
);

has 'inplace' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'save comment to the beagle parent lives',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    require Email::Address;

    my $pid = $self->parent;
    die "beagle comment --parent parent_id ..." unless $pid;

    my @ret = resolve_entry( $pid, handle => current_handle() || undef );
    unless (@ret) {
        @ret = resolve_entry($pid) or die_entry_not_found($pid);
    }
    die_entry_ambiguous( $pid, @ret ) unless @ret == 1;
    $pid = $ret[0]->{id};
    my $bh = $self->inplace ? $ret[0]->{handle} : current_handle();
    $bh ||= $ret[0]->{handle};

    my $author = $self->author || current_user() || '';

    my $body = join ' ', @$args;

    my $comment;

    if ( $body !~ /\S/ || $self->edit ) {
        my $temp = Beagle::Model::Comment->new(
            parent_id => $pid,
            author    => $author,
            body      => $body,
        );
        $temp->timezone( $bh->info->timezone ) if $bh->info->timezone;
        my $template = (
            $self->verbose
            ? $temp->serialize(
                path      => 1,
                created   => 1,
                updated   => 1,
                id        => 1,
                parent_id => 1,
              )
            : $temp->serialize()
        );
        my $message = '';
        if ( $self->message ) {
            $message = $self->message;
            $message =~ s!^!# !mg;
            $message .= newline();
        }
        $template = encode_utf8( $message . $template );

        my $updated = edit_text($template);
        if ( !$self->force && $template eq $updated ) {
            puts "aborted.";
            return;
        }

        $comment =
          Beagle::Model::Comment->new_from_string( decode_utf8 $updated );
        unless ( $self->verbose ) {
            $comment->id( $temp->id );
            $comment->parent_id($pid);
            $comment->created( $temp->created );
            $comment->updated( $temp->updated );
        }
    }
    else {
        $comment = Beagle::Model::Comment->new(
            body   => $body,
            author => $author,
        );
    }

    $comment->parent_id($pid);
    $comment->author($author) if $author && !$comment->author;
    $comment->timezone( $bh->info->timezone ) if $bh->info->timezone;
    $comment->commit_message( $self->message )
      if $self->message && !$comment->commit_message;
    if ( $bh->create_entry($comment) ) {
        puts "created " . $comment->id . ".";
    }
    else {
        die "failed to create the comment.";
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::comment - create a comment

=head1 SYNOPSIS

    $ beagle comment --parent id1  'this rocks'  
    $ beagle comment --parent id1  # use editor

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

