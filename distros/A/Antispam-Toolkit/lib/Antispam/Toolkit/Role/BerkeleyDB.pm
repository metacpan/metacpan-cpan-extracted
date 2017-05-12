package Antispam::Toolkit::Role::BerkeleyDB;
BEGIN {
  $Antispam::Toolkit::Role::BerkeleyDB::VERSION = '0.08';
}

use strict;
use warnings;
use autodie;
use namespace::autoclean;

use Antispam::Toolkit::Types qw( Bool File NonEmptyStr DataFile );
use BerkeleyDB;
use DateTime;

BEGIN {
    die 'The ' . __PACKAGE__ . ' role requires a BerkeleyDB linked against Berkeley DB 4.4+'
        unless $BerkeleyDB::db_version >= 4.4;
}

use Moose::Role;
use MooseX::Params::Validate qw( validated_list );

with 'Antispam::Toolkit::Role::Database';

has database => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

has name => (
    is      => 'ro',
    isa     => NonEmptyStr,
    lazy    => 1,
    builder => '_build_name',
);

has _db => (
    is       => 'ro',
    isa      => 'BerkeleyDB::Hash',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_db',
);

sub _build_db {
    my $self = shift;

    die "The database file must already exist"
        unless -f $self->database();

    my $env = BerkeleyDB::Env->new(
        -Home  => $self->database()->dir(),
        -Flags => DB_INIT_CDB | DB_INIT_MPOOL,
    );

    return BerkeleyDB::Hash->new(
        -Filename => $self->database(),
        -Env      => $env,
    );
}

sub _build_name {
    my $self = shift;

    my $db_file = $self->database();

    return
        $db_file->basename() . ' - '
        . DateTime->from_epoch( epoch => $db_file->stat()->mtime() )
        ->iso8601();
}

sub build {
    my $class = shift;
    my ( $file, $database, $update ) = validated_list(
        \@_,
        file => {
            isa    => DataFile,
            coerce => 1,
        },
        database => {
            isa    => File,
            coerce => 1,
        },
        update => {
            isa     => Bool,
            default => 0,
        },
    );

    my $env = BerkeleyDB::Env->new(
        -Home  => $database->dir(),
        -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
    );

    my $db = BerkeleyDB::Hash->new(
        -Filename => $database,
        -Flags    => DB_CREATE,
        -Env      => $env,
    ) or die "Could not open $database: $! $BerkeleyDB::Error\n";

    if ($update) {
        $class->_extract_data_from_file( $file, $db );
    }
    else {
        my $lock = $db->cds_lock();

        $db->truncate( my $count )
            and die
            "Fatal error trying to write to the BerkeleyDB file at $database";

        $class->_extract_data_from_file( $file, $db );

        # This seems to return a true value even if there's not a real error
        # (maybe in the case where it doesn't actually comptact?)
        $db->compact();

        $lock->cds_unlock();
    }

    return;
}

sub _extract_data_from_file {
    my $class = shift;
    my $file  = shift;
    my $db    = shift;

    open my $fh, '<', $file;

    while (<$fh>) {
        chomp;
        $class->_store_value( $db, $_ );
    }
}

sub _store_value {
    my $self  = shift;
    my $db    = shift;
    my $value = shift;

    $db->db_put( $value => 1 )
        and die "Fatal error trying to write to the BerkeleyDB file at "
        . $self->database();

    return;
}

sub match_value {
    my $self = shift;
    my $key  = shift;

    my $value;
    # The return value here indicates whether or not the key exists.
    $self->_db()->db_get( $key, $value );

    return $value;
}

1;

# ABSTRACT: A role for classes which store spam check data in a BerkeleyDB file



=pod

=head1 NAME

Antispam::Toolkit::Role::BerkeleyDB - A role for classes which store spam check data in a BerkeleyDB file

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  package MyDBD;

  use Moose;

  with 'Antispam::Toolkit::BerkeleyDB';

  sub _store_value {
      my $class = shift;
      my $db    = shift;
      my $value = shift;

      ...
  }

=head1 DESCRIPTION

This role provides most of what's needed in order to store spam-checking data
in a BerkeleyDB file. The only method you must implement in your class is the
C<< $class->_store_value() >> method.

Typically, this will be a database containing things like bad ip addresses or
usernames.

=head1 ATTRIBUTES

This role provides the following attributes:

=head2 $db->database()

This is a L<Path::Class::File> object representing the path on disk for the
BerkeleyDB file. This attribute also accepts a string, which is coerced to a
file object.

=head2 $db->name()

The name of the database. This can be any non-empty string. It is intended for
use in things like logs, so that you know exactly which database matched a
particular value.

By default, the name will contain the database file's basename and it's mtime
as an ISO8601 datetime, something like "bad-ip.db - 2010-11-16T10:31:03".

=head2 $db->_db()

This attribute contains the L<BerkeleyDB> object for the database. It cannot
be set in the constructor, and is always lazily built.

=head1 REQUIRED METHODS

This role requires one method:

=head1 METHODS

This role provides the following methods:

=head2 $db->_build_db()

This will build the L<BerkeleyDB> object for the database.

=head2 $db->_build_name()

This creates a default name for the object.

=head2 $class->build( ... )

This is a I<class> method that can be used to construct a new L<BerkeleyDB>
file from a data source.

It accepts the following arguments:

=over 4

=item * file

This should be a file containing data to be imported into the database. By
default, this should be a file which lists one value per line. You can provide
your own C<< $class->_extract_data_from_file() >> to handle different data
formats.

=item * database

The path to the BerkeleyDB file that will be created or updated.

If you're using multiple BerkeleyDB files for different types of data, you
probably should put each one in a separate directory, because the BerkeleyDB
library creates identically named log files for each database file.

=item * update

By default, if the database parameter points to an existing BerkeleyDB file,
it will be emptied completely and rebuilt from scratch. If this parameter is
true, it will simply add new data and leave the old data in place.

=back

=head2 $class->_extract_data_from_file( $file, $db )

This method takes a data file and adds that data to the BerkeleyDB file. By
default, this expects that the file contains one value per line, so it chomps
each line and stores that value.

Internally, it calls C<< $class->_store_value() >> to actually store the value.

=head2 $class->_store_value( $db, $value )

This method will be called as a class method. The method is passed a
L<BerkeleyDB> object and value to store in the database.

By default, it just stores the literal value. You can replace this method if
you want to do something different, like handle wildcard values.

=head2 $db->match_value($value)

This method looks up a value to see if it is stored in the database. By
default, it expects the value to match a key stored in the database.

=head1 ROLES

This role does the L<Antispam::Toolkit::Role::Database> role. It provides an
implementation of C<< $db->match_value() >> method, but you can write your own
if necessary.

=head1 BUGS

See L<Antispam::Toolkit> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

