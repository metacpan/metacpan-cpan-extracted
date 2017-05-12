package Beagle::Cmd::Command::relation;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has 'update' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'update',
    cmd_aliases   => 'u',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    if ( $self->update ) {
        my $roots = roots();
        require Beagle::Handle;
        my $map = {};

        for my $name ( keys %$roots ) {
            my $bh = Beagle::Handle->new( root => $roots->{$name}{local} );
            for my $entry ( @{ $bh->comments }, @{ $bh->entries } ) {
                $map->{ $entry->id } = $name;
            }
        }

        set_relation($map);
        puts "updated relation.";
    }
    else {
        my $map = relation;
        my @ids;

        $args = $self->resolve_ids( $args );
        if (@$args) {
            for my $id (@$args) {
                push @ids, grep { /^$id/ } keys %$map;
            }
        }
        else {
            @ids = keys %$map;
        }

        return unless @ids;

        my $name_length = max_length( map { $map->{$_} } @ids ) + 1;
        $name_length = 5 if $name_length < 5;

        require Text::Table;
        my $tb = Text::Table->new();
        $tb->load( map { [ $_, $map->{$_} ] } @ids );
        puts $tb;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::relation - show beagle names of entries

=head1 SYNOPSIS

    $ beagle relation 
    $ beagle relation  --update
    $ beagle relation  id1 id2

=head1 DESCRIPTION

This relation/map is stored in a file locally in kennel by default.

The file path can be customized via env C<BEAGLE_RELATION_PATH> or config
item C<relation_path>.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

