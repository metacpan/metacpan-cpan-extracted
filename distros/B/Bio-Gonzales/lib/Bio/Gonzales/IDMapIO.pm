#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::IDMapIO;

use warnings;
use strict;
use Carp;

use 5.010;

use parent qw/Bio::Root::Root/;
use YAML qw/freeze thaw/;
use Data::Dumper;
our $VERSION = '0.0546'; # VERSION

our $MAP_PREFIX = 's';
our $IDLENGTH   = 9;

=head1 NAME

Bio::Gonzales::IDMapIO - remap ids of 'objects', should be used in IO-classes, like Bio::SeqIO

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 METHODS

=cut
sub _initialize_idmapio {
    my ( $self, @args ) = @_;
    $self->SUPER::_initialize(@args);

    my ( $fh, $file, $prefix, $id_length, $start_idx, $cache )
        = $self->_rearrange( [qw(map_fh map_file map_prefix map_id_length map_start_idx map_cache)], @args );

    $self->{'_map_id_len'} = $IDLENGTH;
    $self->_map_id_len($id_length);
    $self->map_prefix( $prefix // $MAP_PREFIX );
    $self->map_reset_id;
    $self->map_reset_cache;
    $self->{'_mapidx'} = $start_idx - 1
        if ( defined $start_idx );
    $self->{'_cache'} = $cache
        if ( defined $cache );

    if ( $fh || $file ) {
        $self->{'_map_io'} = Bio::Root::IO->new;
        $self->{'_map_io'}->_initialize_io( -fh => $fh, -file => $file );
        $self->_cache_from_io( $self->{'_map_io'} ) if ( $self->{'_map_io'}->mode eq 'r' && !defined($cache) );
    }
}

=head2 $io->map_reset_id

=cut
sub map_reset_id {
    my ($self) = @_;
    $self->{'_mapidx'} = -1;
}

=head2 $io->map_reset_cache

=cut
sub map_reset_cache {
    my ($self) = @_;

    $self->{'_cache'} = {};
}

=head2 $io->map_add

=cut
sub map_add {
    my ( $self, $real_id, $desc ) = @_;

    $self->{'_mapidx'}++;
    $self->map_add_custom( $self->map_id_current, $real_id, $desc );
    $self->warn("map id exceeds id length")
        if ( length( $self->map_prefix . $self->{'_mapidx'} ) > $self->_map_id_len );
    return $self->map_id_current;
}

=head2 $io->map_add_custom

=cut
sub map_add_custom {
    my ( $self, $map_id, $real_id, $desc ) = @_;

    $self->throw("Did not provide a valid custom map id for proper mapping")
        unless defined $map_id;
    $self->throw("Did not provide a valid id for proper mapping")
        unless defined $real_id;
    $desc //= '';

    $self->{'_cache'}->{$map_id} = { real_id => $real_id, desc => $desc };
    return $map_id;
}

=head2 $io->map_write

=cut
sub map_write {
    my ( $self, @args ) = @_;

    my $map_io;
    if ( $self->{'_map_io'} ) {
        $map_io = $self->{'_map_io'};
    } elsif ( @args > 0 ) {
        $map_io = Bio::Root::IO->new;
        $map_io->_initialize_io(@args);
    } else {
        $self->throw("no io args in constructor and no io args in function args");
    }

    $map_io->_print( freeze( $self->{_cache} ) );
    $map_io->close();
}

=head2 $io->map_id_current

=cut
sub map_id_current {
    my ($self) = @_;

    return $self->{'_map_prefix'}
        . sprintf( "%0." . ( $self->_map_id_len - $self->_map_prefix_len ) . "d", $self->{'_mapidx'} );
}

=head2 $io->map_lookup_id

=cut
sub map_lookup_id {
    my ( $self, $map_id ) = @_;

    return $self->{'_cache'}->{$map_id};
}

=head2 $io->map_prefix

=cut
sub map_prefix {
    my ( $self, $value ) = @_;
    if ( defined $value ) {
        $self->throw("map prefix starts with >") if ( $value =~ /^>/ );
        $self->throw("map prefix too long") if ( length($value) > $self->_map_id_len - 1 );
        $self->{'_map_prefix'} = $value;
    }
    return $self->{'_map_prefix'};
}

sub _map_id_len {
    my ( $self, $len ) = @_;
    return $self->{'_map_id_len'} unless ( defined($len) );
    $self->throw("map id shorterd than prefix")
        if ( exists( $self->{'_map_prefix'} ) && $len < length( $self->{'_map_prefix'} ) );
    $self->{'_map_id_len'} = $len;
    return $len;
}

sub _map_prefix_len {
    my ($self) = @_;

    return length( $self->{'_map_prefix'} );
}

=head2 $io->map_idx($new_index_value)

set the index value (00001  in S00001)

=cut
sub map_idx {
    my ( $self, $idx ) = @_;
    $self->{'_mapidx'} = $idx
        if ( defined $idx );

    return $idx;
}

=head2 $io->map

return the map

=cut
sub map {
    my ($self) = @_;
    
    return $self->{'_cache'};
}

=head2 $io->map_read

read the map from a file

=cut
sub map_read {
    my ( $self, @args ) = @_;

    $self->throw("no io args in function args")
        unless ( @args > 0 );

    my $map_io = Bio::Root::IO->new;
    $map_io->_initialize_io(@args);
    $self->{'_map_io'} = $map_io;

    $self->_cache_from_io($map_io);
}

sub _cache_from_io {
    my ( $self, $map_io ) = @_;

    my $yaml_string = '';
    while ( my $l = $map_io->_readline ) {
        $yaml_string .= $l;
    }
    $self->{'_cache'} = thaw($yaml_string);
}

1;
__END__

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
