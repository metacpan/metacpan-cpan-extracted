package Beagle::Cmd::Command::rewrite;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;

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

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    local $ENV{BEAGLE_CACHE};    # no cache

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

    require Email::Address;
    for my $bh (@bh) {
        for my $id ( keys %{ $bh->map } ) {
            my $entry = $bh->map->{$id};
            $bh->update_entry( $entry, commit => 0 )
              or die "failed to update entry " . $entry->id;
        }
        $bh->backend->commit( message => $self->message
              || 'rewrote the whole beagle' );
    }
    puts "rewrote.";
}

sub usage_desc { "rewrite all the entries" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::rewrite - rewrite all the entries

=head1 SYNOPSIS

    $ beagle rewrite

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

