package BerkeleyDB::Easy;

use strict;
use warnings;
use BerkeleyDB ();

our $VERSION = '0.06';

sub import {
    my @args = @_;
    
    # TODO: process options and set compile-time globals before
    #       loading any other files
    
    require BerkeleyDB;
    BerkeleyDB->export_to_level(1, @args);
    
    require BerkeleyDB::Easy::Error;
    BerkeleyDB::Easy::Error->export_to_level(1, @args);
}

# This is the frontend module that you `use` in your code
# There are two ways to construct a BTREE handle:
#   1  BerkeleyDB::Easy->new(Type => BerkeleyDB::DB_BTREE);
#   2  BerkeleyDB::Easy::Btree->new();
# This is following the interface of BerkeleyDB.pm. To allow the second
# type of constructor, we provide those subclasses here.

sub new {
    shift;
    require BerkeleyDB::Easy::Handle;
    BerkeleyDB::Easy::Handle->new(@_);
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Btree;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_BTREE());
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Hash;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_HASH());
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Recno;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_RECNO());
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Queue;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_QUEUE());
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Heap;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_HEAP());
}

# --------------------------------------------------------

package BerkeleyDB::Easy::Unknown;
our @ISA = qw(BerkeleyDB::Easy::Handle);

sub new {
    require BerkeleyDB;
    require BerkeleyDB::Easy::Handle;
    shift->SUPER::_new(@_, Type => BerkeleyDB::DB_UNKNOWN());
}

# --------------------------------------------------------

1;

=encoding utf8

=head1 NAME

BerkeleyDB::Easy - BerkeleyDB wrapper with Perlish interface and error handling

=head1 SYNOPSIS

    my $db = BerkeleyDB::Easy::Btree->new(
        -Filename => 'test.db',
        -Flags    => DB_CREATE,
    );

    $db->put('foo', 'bar');

    my $foo = $db->get('foo');

    my $cur = $db->cursor;

    while (my ($key, $val) = $cur->next) {
        $db->del($key);
    }

    $db->sync;

=head1 DESCRIPTION

BerkeleyDB::Easy is a convenience wrapper around BerkeleyDB.pm. It will 
reduce the amount of boilerplate you have to write, with special focus
on comprehensive and customizable error handling and logging, with minimal
overhead.

=head1 ERRORS

When using BerkeleyDB, errors can be generated at many levels. The OS,
the Perl interpreter, the BDB C library, and the BerkeleyDB.pm module.
Each of these need to be handled via different mechanisms, which can be
quite a headache. This module attempts to consolidate and automate error
handling at all these levels, so you don't have to think about it.

Errors are thrown as a versatile structured exception object. It is overloaded
to stringify as a concise message, numberify into an error code, and has various
methods for detailed handling.

    use BerkeleyDB::Easy;

    my $db = BerkeleyDB::Easy::Btree->new();
    my $err;

    use Try::Tiny;
    try { $db->get('asdf', 666) } catch { $err = $_ };

    use feature 'say';
    say $err;

    # [BerkeleyDB::Easy::Handle::get] EINVAL (22): Invalid argument.
    #   DB_READ_COMMITTED, DB_READ_UNCOMMITTED and DB_RMW require locking
    #   at error.pl line 16.

    say 0 + $err;

    # 22

    use Data::Dump;
    dd $err;

    # bless({
    #   code    => 22,
    #   desc    => "Invalid argument",
    #   detail  => "DB_READ_COMMITTED, DB_READ_UNCOMMITTED and DB_RMW require locking",
    #   file    => "error.pl",
    #   level   => "BDB_ERROR",
    #   line    => 16,
    #   message => "Invalid argument. DB_READ_COMMITTED, DB_READ_UNCOMMITTED and "
    #            . "DB_RMW require locking",
    #   name    => "EINVAL",
    #   package => "main",
    #   string  => "[BerkeleyDB::Easy::Handle::get] EINVAL (22): Invalid argument. "
    #            . "DB_READ_COMMITTED, DB_READ_UNCOMMITTED and DB_RMW require locking "
    #            . "at error.pl line 16.",
    #   sub     => "BerkeleyDB::Easy::Handle::get",
    #   time    => 1409926665.1101,
    #   trace   => "at error.pl line 16.",
    # }, "BerkeleyDB::Easy::Error")

=head1 IMPLEMENTATION

Wrapper methods are dynamically generated according to a declarative specification
combined with user-configurable options. This way, dozens of (very similar)
methods can be created without copy and paste coding, and features can be
compiled in or out based on your criteria. By tailoring each wrapper to the
underlying BerkeleyDB function and offering an optimization parameter,
each wrapper uses the minimum number of ops to provide as little overhead as
possible.

For example, here is the specification for BerkeleyDB::Easy::Handle::put()

    ['db_put',[K,V,F],[K,V,F],[V],[],0,0]

The following fields are defined:

    0  FUNC : the underlying BerkeleyDB.pm function we are wrapping
    1  RECV : parameters to our wrapper, passed by the end user
    2  SEND : arguments we call FUNC with, often carried thru from RECV
    3  SUCC : what to return on success
    4  FAIL : what to return on failure
    5  OPTI : integer specifying optimization level
    6  FLAG : default flag to FUNC

As well as these single-letter aliases:

    K  $key         |   R  $return       |   X  $x
    V  $value       |   S  $status       |   Y  $y
    F  $flags       |   T  1  ('True')   |   Z  $z
    A  @_ ('All')   |   N  '' ('Nope')   |   U  undef

And so our wrapper delcaration expands to the following code:

    sub put {
        my @err;
        local ($!, $^E);
        local $SIG{__DIE__} = sub { @err = (BDB_FATAL, $_) };
        local $SIG{__WARN__} = sub { @err = (BDB_WARN, $_) };
        undef $BerkeleyDB::Error;
        my ($self, $key, $value, $flags) = @_;
        my $status = BerkeleyDB::Common::db_put($self, $key, $value, $flags);
        $self->_log(@err) if @err;
        if ($status) {
            $self->_throw($status);
            return();
        }
        return($value);
    }

In BerkeleyDB version < 4.6, there is no C<exists()>, so we fake it:

    ['db_get',[K,F],[K,V,F],[T],[N],1,0]

Here, the optimization flag has been set to true. This results in:

    sub exists {
        undef $BerkeleyDB::Error;
        my ($self, $key, $flags) = @_;
        my ($value);
        my $status = BerkeleyDB::Common::db_get($self, $key, $value, $flags);
        if ($status) {
            $self->_throw($status, undef, 1);
            return('');
        }
        return(1);
    }

You can see that some (not all) of the error-checking has been compiled out.
Namely, we are no longer catching warnings and exceptions from BerkeleyDB
and only checking the status of its return value. This is normally enough
to catch any errors from the module, as it will usually only die in special
circumstances, so it would be reasonable to compile out these (expensive)
extra checks if performance were important.

You can also see the difference between how the two methods operate. C<put()>
takes a key and value, and returns the value upon success and C<undef> on failure.
C<exists()> takes only a key and returns C<1> on success and an empty string on
failure. Currently over 30 methods are defined this way, using a single line
of code each. See the documentation for C<BerkeleyDB::Easy::Handle> and 
C<BerkeleyDB::Easy::Cursor> for a full listing.

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
