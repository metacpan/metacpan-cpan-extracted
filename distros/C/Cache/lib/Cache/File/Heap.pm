=head1 NAME

Cache::File::Heap - A file based heap for use by Cache::File

=head1 SYNOPSIS

  use Cache::File::Heap;

  $heap = Cache::File::Heap->new('/path/to/some/heap/file');
  $heap->add($key, $val);
  ($key, $val) = $heap->minimum;
  ($key, $val) = $heap->extract_minimum;
  $heap->delete($key, $val);

=head1 DESCRIPTION

This module is a wrapper around a Berkeley DB using a btree structure to
implement a heap.  It is specifically for use by Cache::File for storing
expiry times (although with a bit of work it could be made more general).

See LIMITATIONS below.

=cut
package Cache::File::Heap;

require 5.006;
use strict;
use warnings;
use DB_File;
use Carp;

use fields qw(db dbhash);

our $VERSION = '2.11';

# common info object
my $BTREEINFO = new DB_File::BTREEINFO;
$BTREEINFO->{compare} = \&_Num_Compare;
$BTREEINFO->{flags} = R_DUP;


=head1 CONSTRUCTOR

  my $heap = Cache::File::Heap->new( [$dbfile] );

The heap constructor takes an optional argument which is the name of the
database file to open.  If specified, it will attempt to open the database
during construction.  A new Cache::File::Heap blessed reference will be
returned, or undef if the open failed.

=cut

sub new {
    my Cache::File::Heap $self = shift;

    $self = fields::new($self) unless ref $self;

    if (@_) {
        $self->open(@_) or return undef;
    }

    return $self;
}


=head1 METHODS

=over

=item $h->open($dbfile)

Opens the specified database file.

=cut

sub open {
    my Cache::File::Heap $self = shift;
    my ($dbfile) = @_;

    $self->close();

    my %dbhash;
    my $db = tie %dbhash, 'DB_File', $dbfile, O_CREAT|O_RDWR, 0666, $BTREEINFO
        or return undef;

    $self->{db} = $db;
    $self->{dbhash} = \%dbhash;

    return 1;
}

=item $h->close()

Closes a previously opened heap database.  Note that the database will be
automatically closed when the heap reference is destroyed.

=cut

sub close {
    my Cache::File::Heap $self = shift;
    $self->{db} = undef;
    untie %{$self->{dbhash}};
    $self->{dbhash} = undef;
}

=item $h->add($key, $val)

Adds a key and value pair to the heap.  Currently the key should be a number,
whilst the value may be any scalar.  Invokes 'die' on failure (use eval to
catch it).

=cut

sub add {
    my Cache::File::Heap $self = shift;
    my ($key, $val) = @_;
    defined $key or croak "key undefined";
    defined $val or croak "value undefined";
    # return code from DB_File is 0 on success.....
    $self->_db->put($key, $val) and die "Heap add failed: $@";
}

=item $h->delete($key, $val)

Removes a key and value pair from the heap.  Returns 1 if the pair was found
and removed, or 0 otherwise.

=cut

sub delete {
    my Cache::File::Heap $self = shift;
    my ($key, $val) = @_;
    defined $key or croak "key undefined";
    defined $val or croak "value undefined";
    # return code from DB_File is 0 on success.....
    $self->_db->del_dup($key, $val) and return 0;
    return 1;
}

=item ($key, $val) = $h->minimum()

In list context, returns the smallest key and value pair from the heap.  In
scalar context only the key is returned.  Note smallest is defined via a
numerical comparison (hence keys should always be numbers).

=cut

sub minimum {
    my Cache::File::Heap $self = shift;
    my ($key, $val) = (0,0);
    $self->_db->seq($key, $val, R_FIRST)
        and return undef;
    return wantarray? ($key, $val) : $key;
}

=item ($key, $vals) = $h->minimum_dup()

In list context, returns the smallest key and an array reference containing
all the values for that key from the heap.  In scalar context only the key is
returned.

=cut

sub minimum_dup {
    my Cache::File::Heap $self = shift;
    my $db = $self->_db;
    my ($key, $val) = (0,0);
    $db->seq($key, $val, R_FIRST)
        and return undef;
    return wantarray? ($key, [ $db->get_dup($key) ]) : $key;
}

=item ($key, $val) = $h->extract_minimum()

As for $h->minimum(), but the key and value pair is removed from the heap.

=cut

sub extract_minimum {
    my Cache::File::Heap $self = shift;
    my $db = $self->_db;
    my ($key, $val) = (0,0);
    $db->seq($key, $val, R_FIRST)
        and return undef;
    $db->del_dup($key, $val);
    return wantarray? ($key, $val) : $key;
}

=item ($key, $vals) = $h->extract_minimum_dup()

As for $h->minimum_dup(), but all the values are removed from the heap.

=cut

sub extract_minimum_dup {
    my Cache::File::Heap $self = shift;
    my $db = $self->_db;
    my ($key, $val) = (0,0);
    $db->seq($key, $val, R_FIRST)
        and return undef;
    my @values = $db->get_dup($key) if wantarray;
    $db->del($key);
    # bugfix for broken db1 - not all values are removed the first time
    $db->del($key);
    return wantarray? ($key, \@values) : $key;
}

=back

=cut


sub _db {
    my Cache::File::Heap $self = shift;
    my $db = $self->{db};
    croak "Heap not opened" unless $db;
}

sub _Num_Compare {
    my ($key1, $key2) = @_;

    # somehow we can get undefined keys here?  Probably a db bug.

    if (not defined $key1 and not defined $key2) {
        return 0
    }
    elsif (defined $key1 and not defined $key2) {
        return 1;
    }
    elsif (not defined $key1 and defined $key2) {
        return -1;
    }
    else {
        return $key1 <=> $key2;
    }
}


1;
__END__

=head1 SEE ALSO

Cache::File

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Heap.pm,v 1.6 2006/01/31 15:23:58 caleishm Exp $

=cut
