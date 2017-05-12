package CHI::Driver::BerkeleyDB;
use 5.006;
use BerkeleyDB;
use CHI::Util qw(read_dir);
use File::Path qw(mkpath);
use Moose;
use strict;
use warnings;

extends 'CHI::Driver';

our $VERSION = '0.03';

has 'db'       => ( is => 'ro', lazy_build => 1 );
has 'db_class' => ( is => 'ro', default    => 'BerkeleyDB::Hash' );
has 'dir_create_mode' => ( is => 'ro', isa => 'Int', default => oct(775) );
has 'env' => ( is => 'ro', lazy_build => 1 );
has 'filename' => ( is => 'ro', init_arg => undef, lazy_build => 1 );
has 'root_dir' => ( is => 'ro' );

__PACKAGE__->meta->make_immutable();

sub _build_filename {
    my $self = shift;
    return $self->escape_for_filename( $self->namespace ) . ".db";
}

sub _build_env {
    my $self = shift;

    my $root_dir = $self->root_dir;
    die "must specify one of env or root_dir" if !defined($root_dir);
    mkpath( $root_dir, 0, $self->dir_create_mode )
      if !-d $root_dir;
    my $env = BerkeleyDB::Env->new(
        '-Home'   => $self->root_dir,
        '-Config' => {},
        '-Flags'  => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
      )
      or die sprintf( "cannot open Berkeley DB environment in '%s': %s",
        $root_dir, $BerkeleyDB::Error );
    return $env;
}

sub _build_db {
    my $self = shift;

    my $filename = $self->filename;
    my $db       = $self->db_class->new(
        '-Filename' => $filename,
        '-Flags'    => DB_CREATE,
        '-Env'      => $self->env
      )
      or die
      sprintf( "cannot open Berkeley DB file '%s' in environment '%s': %s",
        $filename, $self->root_dir, $BerkeleyDB::Error );
    return $db;
}

sub fetch {
    my ( $self, $key ) = @_;

    my $data;
    return ( $self->db->db_get( $key, $data ) == 0 ) ? $data : undef;
}

sub store {
    my ( $self, $key, $data ) = @_;

    $self->db->db_put( $key, $data ) == 0
      or die $BerkeleyDB::Error;
}

sub remove {
    my ( $self, $key ) = @_;

    $self->db->db_del($key) == 0
      or die $BerkeleyDB::Error;
}

sub clear {
    my ($self) = @_;

    my $count = 0;
    $self->db->truncate($count) == 0
      or die $BerkeleyDB::Error;
}

sub get_keys {
    my ($self) = @_;

    my @keys;
    my $cursor = $self->db->db_cursor();
    my ( $key, $value ) = ( "", "" );
    while ( $cursor->c_get( $key, $value, BerkeleyDB::DB_NEXT() ) == 0 ) {
        push( @keys, $key );
    }
    return @keys;
}

sub get_namespaces {
    my ($self) = @_;

    my @contents = read_dir( $self->root_dir );
    my @namespaces =
      map { $self->unescape_for_filename( substr( $_, 0, -3 ) ) }
      grep { /\.db$/ } @contents;
    return @namespaces;
}

1;

__END__

=pod

=head1 NAME

CHI::Driver::BerkeleyDB -- Using BerkeleyDB for cache

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver     => 'BerkeleyDB',
        root_dir   => '/path/to/cache/root'
    );

=head1 DESCRIPTION

This cache driver uses L<Berkeley DB|BerkeleyDB> files to store data. Each
namespace is stored in its own db file.

By default, the driver configures the Berkeley DB environment to use the
Concurrent Data Store (CDS), making it safe for multiple processes to read and
write the cache without explicit locking.

=head1 CONSTRUCTOR OPTIONS

=over

=item root_dir

Path to the directory that will contain the Berkeley DB environment, also known
as the "Home".

=item db_class

BerkeleyDB class, defaults to BerkeleyDB::Hash.

=item env

Use this Berkeley DB environment instead of creating one.

=item db

Use this Berkeley DB object instead of creating one.

=back

=head1 SUPPORT AND DOCUMENTATION

Questions and feedback are welcome, and should be directed to the perl-cache
mailing list:

    http://groups.google.com/group/perl-cache-discuss

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-BerkeleyDB

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-chi-driver-bdb/tree/master
    git clone git://github.com/jonswar/perl-chi-driver-bdb.git

=head1 AUTHOR

Jonathan Swartz

=head1 SEE ALSO

L<CHI>, L<BerkeleyDB>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007 Jonathan Swartz.

CHI::Driver::BerkeleyDB is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
