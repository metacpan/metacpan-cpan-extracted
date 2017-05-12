package Beagle::Cmd::Command::info;

use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'set' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set',
    traits        => ['Getopt'],
);

has 'unset' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'unset',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
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

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

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

    my $first = 1;
    for my $bh (@bh) {

        my $info = $bh->info;

        if ( $self->edit || $self->set || $self->unset ) {

            if ( $self->unset ) {

                for my $key ( @{ $self->unset } ) {
                    if ( $info->can($key) ) {
                        $info->$key('');
                    }
                    else {
                        warn "unknown key: $key";
                    }
                }
            }

            if ( $self->set ) {
                for my $item ( @{ $self->set } ) {
                    my ( $key, $value ) = split /=/, $item, 2;
                    if ( $info->can($key) ) {
                        $info->$key($value);
                    }
                    else {
                        warn "unknown key: $key";
                    }
                }
            }


            if ( $self->edit ) {
                my $template = $info->serialize(
                    $self->verbose
                    ? (
                        created => 1,
                        updated => 1,
                        id      => 1,
                      )
                    : (
                        created => undef,
                        updated => undef,
                        id      => undef,
                    )
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

                $info = $info->new_from_string( decode_utf8 $updated);
            }

            $info->commit_message( $self->message )
              if $self->message && !$info->commit_message;
            if ( $bh->update_info( $info ) ) {
                puts "updated info.";
            }
            else {
                die "failed to update info.";
            }
        }
        else {
            puts '=' x term_width() unless $first;
            undef $first if $first;

            if ( @$args ) {
                for my $field ( @$args ) {
                    if ( $info->can($field) ) {
                        puts( $field, ': ', $info->$field );
                    }
                    else {
                        warn 'invalid field: ' . $field;
                    }
                }
            }
            else {
                puts $info->serialize(
                    $self->verbose
                    ? (
                        created => 1,
                        updated => 1,
                        id      => 1,
                      )
                    : (
                        created => undef,
                        updated => undef,
                        id      => undef,
                    )
                );
            }
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::info - manage info

=head1 SYNOPSIS

    $ beagle info
    $ beagle info --edit
    $ beagle info --set url=http://sunnavy.net
    $ beagle info --unset url

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

