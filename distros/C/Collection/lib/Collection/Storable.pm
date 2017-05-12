package Collection::Storable;

=head1 NAME

Collection::Storable - class for collections of data, stored in files.

=head1 SYNOPSIS

    use File::Temp qw/ tempfile tempdir /;
    my $tmp_dir = tempdir();
    my $coll = new Collection::Storable:: $tmp_dir

=head1 DESCRIPTION

Class for collections of data, stored in files.

=head1 METHODS

=head2 new <path_to_root_of_store>

Creates a new Collection::Storable object.

      my $coll = new Collection::Storable:: $tmp_dir

=cut

use Collection;
use Collection::Utl::Base;
use Data::Dumper;
use Collection::Utl::ActiveRecord;
use Storable qw(lock_nstore lock_retrieve);

use strict;
use warnings;

our @ISA     = qw(Collection);
our $VERSION = '0.01';

attributes qw/ _store_path  /;

sub _init {
    my $self = shift;
    my $path = shift || return undef;
    $path .= "/" unless $path =~ m%/$%;
    $self->_store_path($path);
    $self->SUPER::_init();
    return 1;
}

=head2 key2path <key1>[, <key2>, <keyn> ...]

translate keys to store path

return hash of

    {
      <key1> => <relative path to key>

    }

=cut

sub key2path {
    my $self = shift;
    my %res  = ();
    @res{@_} = @_;
    return \%res;
}

=head2 path2key <path1>[, <path1>, <pathX> ...]

translate store path  to key

return hash of

    {
      <relative path to key>=><key1>

    }

=cut

sub path2key {
    my $self = shift;
    my %res  = ();
    @res{@_} = @_;
    return \%res;
}

sub _delete {
    my $self = shift;
    my @ids  =  @_;
    my $path = $self->_store_path;

    #convert ids to pathes
    my $key2path = $self->key2path(@ids);
    unlink( $path . $_ ) for values %$key2path;
    [ keys %$key2path ];
}

sub _create {
    my $self    = shift;
    my %to_save = @_;
    $self->_store( \%to_save );
    return \%to_save;
}

sub _fetch {
    my $self = shift;
    my @ids  =  @_;
    my $path = $self->_store_path;

    #convert keys to path
    my $key2path = $self->key2path(@ids);
    my %res      = ();
    while ( my ( $key, $kpath ) = each %$key2path ) {
        my $fpath = $path . $kpath;
        next unless -e $fpath;
        $res{$key} = lock_retrieve($fpath);
    }
    \%res;
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Collection::Utl::ActiveRecord', hash => $ref;
    return \%hash;
}

sub _store {
    my $self = shift;
    my $in   = shift;
    my $path = $self->_store_path;
    while ( my ( $key, $val ) = each %$in ) {
        my $file_name = $path . $self->key2path($key)->{$key};
        lock_nstore( {%$val} || {}, $file_name );
    }
}

sub __get_list_files {
    my $self = shift;
    my $path = shift;
    my @res  = ();
    if ( opendir DIR, $path ) {
        while ( my $name = readdir DIR ) {
            next if ( $name eq '.' ) or ( $name eq '..' );
            my $fpath = $path . $name;
            if ( -d $fpath ) {
                push @res, $self->__get_list_files($fpath);
            }
            else {
                push @res, $fpath;
            }
        }
        closedir DIR;
    }
    return @res

}

sub list_ids {
    my $self = shift;
    my $path = $self->_store_path;

    #get content of path
    my @paths      = $self->__get_list_files($path);
    my $prefix_len = length $path;

    #cut root path
    $_ = substr( $_, $prefix_len, length($_) - $prefix_len ) for @paths;
    return [ values %{ $self->path2key(@paths) } ];
}

1;
__END__

=head1 SEE ALSO

Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

