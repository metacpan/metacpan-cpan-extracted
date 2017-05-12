package Beagle::Cmd::Command::cache;
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

has 'update' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'update',
    cmd_aliases   => 'u',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'force update',
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my @roots;
    my $root = current_root('not die');

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

    if ( $self->update ) {
        for my $bh (@bh) {
            if ( $self->force ) {
                my $name = root_name($bh->root);
                unlink catfile( cache_root(), $name . '.drafts' );
                unlink catfile( cache_root(), $name );
            }

            Beagle::Handle->new( root => $bh->root, drafts => 0 );
            Beagle::Handle->new( root => $bh->root, drafts => 1 );
        }
        puts 'updated cache.';
    }
    else {
        return unless @bh;

        my $name_length = max_length( map { $_->name } @bh ) + 1;

        require Text::Table;
        my $tb = Text::Table->new( qw/name with_drafts normal/ );

        for my $bh (@bh) {

            # Beagle::Handle->new will update cache for us
            require Storable;

            my %info;
            require Beagle::Backend;
            my $backend = Beagle::Backend->new( root => $bh->root, );
            my $latest = $backend->updated;

            for my $p ( '', '.drafts' ) {
                my $name = $bh->name;
                $name =~ s![/\\]!_!g;
                my $file = catfile( kennel(), 'cache', "$name$p" );
                my $type = $p ? 'drafts' : 'normal';
                if ( -e $file ) {
                    my $bh = Storable::retrieve($file);
                    if ( $bh->updated ne $latest ) {
                        $info{$type} = 'outdated';
                    }
                    else {
                        $info{$type} = 'latest';
                    }

                    if ( $bh->updated =~ /\d{11}/ ) {
                        $info{$type} .=
                          '(' . pretty_datetime( $bh->updated ) . ')';
                    }
                    else {
                        $info{$type} .= '(' . $bh->updated . ')';
                    }
                }
                else {
                    $info{$type} = 'none';
                }
            }

            $tb->add( $bh->name, $info{drafts}, $info{normal} );
        }
        puts $tb;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::cache - manage cache

=head1 SYNOPSIS

    $ beagle cache # show cache info
    $ beagle cache --update
    $ beagle cache --update --force # force the update

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

