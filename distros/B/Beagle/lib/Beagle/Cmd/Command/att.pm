package Beagle::Cmd::Command::att;
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

has 'info' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'att for info',
    traits        => ['Getopt'],
);

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'all the beagles',
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);


has 'add' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'add attachments',
    traits        => ['Getopt'],
);

has 'delete' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'delete attachments',
    traits        => ['Getopt'],
);

has 'prune' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'prune orphans',
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

sub command_names { qw/att attachment attachments/ };

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $sub = 0;
    $sub++ if $self->add;
    $sub++ if $self->delete;
    $sub++ if $self->prune;

    die 'you can only specify one of --add, --delete and --prune' if $sub > 1;

    die "beagle att --add --parent foo /path/to/a.txt [...]"
      if $self->add && !$self->parent && !$self->info;

    die "--parent and --info can't coexist" if $self->parent && $self->info;

    die "beagle att --delete 3 [...]" if $self->delete && !@$args;

    my @bh;
    if ( $self->all ) {
        @bh = values %{handles()};
    }
    elsif ( $self->names ) {
        my $handles = handles();
        my $names = to_array( $self->names );
        for my $name ( @$names ) {
            die "invalid name: $name" unless $handles->{$name};
            push @bh, $handles->{$name};
        }
    }
    else {
        @bh = current_handle or die "please specify beagle by --name or --root";
    }

    if ( $self->prune ) {
        my $pruned;
        for my $bh (@bh) {
            for my $p ( keys %{ $bh->attachments_map } ) {
                unless ( $bh->map->{$p} ) {
                    my $dir = catdir( 'attachments', split_id($p) );
                    if ( -e catdir( $bh->root, $dir ) ) {
                        $bh->backend->delete(
                            undef,
                            path    => $dir,
                            message => "prune $dir"
                        ) or die "failed to delete $dir: $!";
                        $pruned = 1;
                    }
                }
            }
        }
        if ( $pruned ) {
            puts 'pruned.';
        }
        else {
            puts 'no orphans found.';
        }
        return;
    }

    my $bh;
    my $pid;

    if ( $self->info ) {
        $bh = current_handle();
        $pid = $bh->info->id;
    }
    elsif ( $self->parent ) {
        my @ret = resolve_entry( $self->parent, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($pid) or die_entry_not_found($pid);
        }
        die_entry_ambiguous( $pid, @ret ) unless @ret == 1;
        $pid = $ret[0]->{id};
        $bh = $ret[0]->{handle};
    }

    if ( $self->add ) {
        my @added;
        for my $file (@$args) {
            if ( -f $file ) {
                require File::Basename;
                my $basename = decode_utf8 File::Basename::basename $file;
                my $att      = Beagle::Model::Attachment->new(
                    name         => $basename,
                    content_file => $file,
                    parent_id    => $pid,
                );
                if ( $bh->create_attachment( $att, message => $self->message ) ) {
                    push @added, $basename;
                }
                else {
                    die "failed to create attachment $file.";
                }
            }
            else {
                die "$file is not a file or doesn't exist";
            }
        }

        if (@added) {
            puts 'added ', join( ', ', @added ), '.';
        }
        return;
    }

    my %handle_map;


    my @att;
    if ($pid) {
        my $map = $bh->attachments_map->{$pid};
        @att = sort values %$map;
    }
    else {
        for my $bh (@bh) {
            $handle_map{ $bh->root } = $bh;
            for my $p ( keys %{ $bh->attachments_map } ) {
                warn "$p doesn't exist, use 'att --prune' to clean"
                  unless $bh->map->{$p};
            }

            for my $entry (
                sort {
                        $bh->map->{$a}
                      ? $bh->map->{$b}
                          ? $bh->map->{$b}->created <=> $bh->map->{$a}->created
                          : -1
                      : 1
                }
                sort keys %{ $bh->attachments_map }
              )
            {
                push @att, sort values %{ $bh->attachments_map->{$entry} };
            }
        }
    }

    if ( $self->delete ) {
        my @deleted;

        # before deleting anything, let's make sure no invliad index
        for my $i (@$args) {
            die "$i is not a number" unless $i =~ /^\d+$/;
            die "no such attachment with index $i" unless $att[ $i - 1 ];
        }

        for my $i (@$args) {
            my $att = $att[ $i - 1 ];
            my $handle = $bh || $handle_map{ $att->root };
            if ( $handle->delete_attachment( $att, message => $self->message ) )
            {
                push @deleted, { handle => $handle, name => $att->name };
            }
            else {
                die "failed to delete attachment $i: " . $att->name . ".";
            }
        }

        if (@deleted) {
            my $msg = 'deleted ' . join( ', ', map { $_->{name} } @deleted );
            puts $msg . '.';
        }
        return;
    }

    if ( @$args ) {
        my $first = 1;

        for my $i (@$args) {
            die "$i is not a number" unless $i =~ /^\d+$/;
            die "no such attachment with index $i" unless $att[ $i - 1 ];
        }

        for my $i (@$args) {
            puts '=' x term_width() unless $first;
            undef $first if $first;
            my $att = $att[ $i - 1 ];
            binmode *STDOUT;
            print $att->content;
        }
    }
    else {
        return unless @att;

        my $name_length = max_length( map { $_->name } @att ) + 1;
        $name_length = 10 if $name_length < 10;

        require Text::Table;
        my $tb =
          $self->verbose
          ? Text::Table->new( qw/index parent size name/, )
          : Text::Table->new();

        for ( my $i = 1 ; $i <= @att ; $i++ ) {
            my $att  = $att[ $i - 1 ];
            my $name = $att->name;
            $tb->add( $i, ( $self->verbose ? ( $att->parent_id ) : () ),
                $att->size, $att->name );

        }
        puts $tb;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::att - manage attachments

=head1 SYNOPSIS

    $ beagle att                    # list all the attachments
    $ beagle att 1                  # show the first attachment
    $ beagle att --parent id1       # list atttachments of entry id1
 
    $ beagle att --add --parent abcd /path/to/att1 /path/to/att2
    $ beagle att --parent id1 1
    $ beagle att --delete --parent abcd 1
    $ beagle att --prune

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

