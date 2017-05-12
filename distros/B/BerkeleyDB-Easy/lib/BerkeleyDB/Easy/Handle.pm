package BerkeleyDB::Easy::Handle;
our @ISA = qw(BerkeleyDB::Common);

use strict;
use warnings;

use BerkeleyDB::Easy::Common;
use BerkeleyDB::Easy::Error;
use BerkeleyDB qw(
    DB_BTREE
    DB_HASH
    DB_RECNO
    DB_QUEUE
    DB_HEAP
    DB_UNKNOWN
    DB_NOTFOUND
);

sub _handle { shift }

sub new {
    my ($self, @args) = @_;
    $self->_wrap(sub { $self->_new(@args) });
}

sub _new {
    my $self = shift;
    my %opts = $self->_options(@_);
    
    # Ignore NOTFOUND by default, otherwise die
    my $errors = delete $opts{Errors} || { DB_NOTFOUND() => BDB_IGNORE };
    ref $errors eq 'HASH'
        or $self->_throw(BDB_PARAM, q("Errors" option must be HASH ref));

    # What kind of handle are we? BTREE if not specified
    my $type   = $self->_type(delete $opts{Type} or DB_BTREE);
    (my $class = ref $self || $self) =~ s/::Handle$/::$type/;
    
    NOTICE and $self->_notice(qq(Creating $type handle));

    my $handle = $self->_wrap(sub {
        my $db = qq(BerkeleyDB::$type)->new(%opts)
            or $self->_throw(BDB_HANDLE);
        my $status = $db->status;
        $status and $self->_throw($status);
        $db;
    });
    bless $handle, $class;
    
    # Assign severity levels to errors if user passed any
    $handle->_assign($_, $errors->{$_}) for keys %$errors;
    $handle;
}

sub _options {
    my $self = shift;
    my %opts;

    # Got a single param, must be hash of options
    if (@_ == 1) {
        $self->_throw(BDB_PLACE) unless ref $_[0] eq 'HASH';
        %opts = %{$_[0]};
    }

    # Got an even list of options
    elsif (@_ > 1 and not @_ % 2) {
        %opts = @_;
    }

    # Got something else. Throw an error
    elsif (@_ > 0) {
        $self->_throw(BDB_PLACE);
    }

    map { $self->_normalize($_) => $opts{$_} } keys %opts;
}

#
# Convert underscore_flags to CamelCase for BerkeleyDB.pm
#
sub _normalize {
    my $self = shift;
    (my $key = shift) =~ s/^-//g;
    join '', map { ucfirst lc } split /_/, $key;
}

sub _type {
    my ($self, $type) = @_;
    (our $Types ||= {
                     &DB_BTREE        => 'Btree',
                     &DB_HASH         => 'Hash',
        $self->_try(\&DB_RECNO) || '' => 'Recno',    # v3
        $self->_try(\&DB_QUEUE) || '' => 'Queue',    # v3
        $self->_try(\&DB_HEAP ) || '' => 'Heap',     # v5.2
                     &DB_UNKNOWN      => 'Unknown',  # v? TODO
    })->{$type} or $self->_throw(BDB_TYPE);
}

# Each hash elem in %subs defines a wrapper specification. Look at Common.pm
# for how these work. Briefly, the key is our wrapper's name, and the value
# is an array ref with the following fields:
#
#   0  FUNC : the underlying BerkeleyDB.pm function we are wrapping
#   1  RECV : parameters to our wrapper, passed by the end user
#   2  SEND : arguments we call FUNC with, often carried thru from RECV
#   3  SUCC : what to return on success
#   4  FAIL : what to return on failure
#   5  OPTI : integer specifying optimization level
#   6  FLAG : default flag to FUNC
#
# Single-letter aliases expand as:
#
#   K  $key         |   R  $return       |   X  $x
#   V  $value       |   S  $status       |   Y  $y
#   F  $flags       |   T  1  ('True')   |   Z  $z
#   A  @_ ('All')   |   N  '' ('Nope')   |   U  undef

my %subs = (
    db_get    => ['db_get'   ,[     ],[A    ],[S  ],[S],0, ],
    get       => ['db_get'   ,[K,F  ],[K,V,F],[V  ],[ ],0, ],
    db_put    => ['db_put'   ,[     ],[A    ],[S  ],[S],0, ],
    put       => ['db_put'   ,[K,V,F],[K,V,F],[V  ],[ ],0, ],
    db_del    => ['db_del'   ,[     ],[A    ],[S  ],[S],0, ],
    del       => ['db_del'   ,[K,F  ],[K,F  ],[K  ],[ ],0, ],
    db_sync   => ['db_sync'  ,[     ],[A    ],[S  ],[S],0, ],
    sync      => ['db_sync'  ,[F    ],[F    ],[T  ],[ ],0, ],
    db_cursor => ['db_cursor',[     ],[A    ],[R  ],[R],0, ],
    associate => ['associate',[     ],[A    ],[S  ],[S],0, ],
    pget      => ['db_pget'  ,[X    ],[X,K,V],[K,V],[ ],0, ],
);

$subs{exists} = $BerkeleyDB::db_version >= 4.6
    ? ['exists',[K,F],[K,F  ],[T],[N],0]
    : ['db_get',[K,F],[K,V,F],[T],[N],0];

# Install the stubs
while (my ($name, $spec) = each %subs) {
    __PACKAGE__->_install($name, $spec);
}

#
# Constructor for a cursor to this DB handle. It could/should probably live
# at Cursor->new() but it's here for now.
#
sub cursor {
    my ($self, $flags) = @_;
    my $cursor = $self->db_cursor($flags);
    my $class  = $self->_Cursor;
    (my $file  = $class) =~ s(::)(\/)g;
    require $file . q(.pm);
    return bless $cursor, $class;
}

# Method aliases for naming consistency
*delete = \&del;
*cur    = \&cursor;

INFO and __PACKAGE__->_info(q(Handle.pm finished loading));

1;

=encoding utf8

=head1 NAME

BerkeleyDB::Easy::Handle - Generic class for Btree, Hash, Recno, Queue, and
Heap handles.

=head1 METHODS

You can optionally provide flags for most methods, but first check to see
if there isn't a dedicated wrapper method to accomplish what you want.

=head2 get

    $val = $db->get($key);

=head2 put

    $val = $db->put($key, $val);

=head2 exists

    $bool = $db->exists($key);

=head2 sync

    $status = $db->sync();

=head2 cursor

    $cursor = $db->cursor();

=head1 BUGS

This module is functional but unfinished.

=head1 AUTHOR

Rob Schaber, C<< <robschaber at gmail.com> >>

=head1 LICENSE

Copyright 2013 Rob Schaber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
