package Class::AlzaboWrapper::Cursor;

use strict;

use Class::AlzaboWrapper;

use Params::Validate qw( validate_with SCALAR ARRAYREF );
Params::Validate::validation_options
    ( on_fail =>
      sub { Class::AlzaboWrapper::Exception::Params->throw
                ( message => join '', @_ ) } );

sub new
{
    my $class = shift;

    my %p = validate_with( params => \@_,
                           spec =>
                           { cursor => { can => 'next' },
                             args   => { type => ARRAYREF, default => [] },
                             constructor_method => { type => SCALAR, default => 'new' },
                           },
                           allow_extra => 1,
                         );

    my $self = bless { %p,
                     }, $class;

    return $self;
}

sub _new_from_row
{
    my $self = shift;
    my $row = shift;

    return undef unless defined $row;
    return $row if $row->isa( 'Class::AlzaboWrapper' );

    my $class = Class::AlzaboWrapper->TableToClass( $row->table );
    Class::AlzaboWrapper::Exception->throw
        ( error => "Cannot find a class for " . $row->table->name . " table" )
            unless $class;

    my $meth = $self->{constructor_method};

    return
        $class->$meth
            ( object => $row,
              @{ $self->{args} },
            );
}

sub next
{
    my $self = shift;

    my @things;
    if (wantarray)
    {
        @things = $self->{cursor}->next
            or return;
    }
    else
    {
        $things[0] = $self->{cursor}->next
            or return;
    }

    my @r = map { $self->_new_from_row($_) } @things;

    return wantarray ? @r : $r[0];
}

sub next_as_hash
{
    my $self = shift;

    my %hash = $self->{cursor}->next_as_hash or return;
    map { $hash{$_} = $self->_new_from_row($hash{$_}) } keys %hash;

    return %hash;
}

sub all
{
    my $self = shift;

    my @all;
    while ( my @a = $self->next )
    {
        push @all, @a == 1 ? $a[0] : \@a;
    }

    return @all;
}

sub count { $_[0]->{cursor}->count }


1;

__END__

=head1 NAME

Class::AlzaboWrapper::Cursor - Higher level wrapper around Alzabo cursor objects

=head1 SYNOPSIS

  my $cursor = Class::AlzaboWrapper::Cursor->new( cursor => $cursor );

=head1 DESCRIPTION

This module works with C<Class::AlzaboWrapper> to make sure that
objects returned from cursors are of the appropriate
C<Class::AlzaboWrapper> subclass, not raw C<Alzabo::Runtime::Cursor>
objects.

THIS MODULE IS STILL AN ALPHA RELEASE.  THE INTERFACE MAY CHANGE IN
FUTURE RELEASES.

=head1 USAGE

This module provides the following methods:

=over 4

=item * new

This method expects a C<cursor> parameter, which should be an
C<Alzabo::Runtime::Cursor> object.  This is the cursor being wrapped
by this class.

It also takes an "args" parameter.  This is an optional array
reference.  If given, then the arguments specified will be passed when
calling C<new()> for the appropriate subclass(es).

The "constructor_method" argument allows you to specify what method to
call when fetching the next object via C<next()>.  This defaults to
"new".

=item * next

This method is called to get the next object (or objects) in the
cursor.  Internally, it calls C<new()> on the appropriate
C<Class::AlzaboWrapper> subclass for each C<Alzabo::Runtime::Row>
object returned by the wrapped cursor.  It can be called in scalar or
array context, but in scalar context it will only return the first
object when there are more than one, so be careful.

=item * next_as_hash

Wrapper for the cursor's C<next_as_hash()> method, it behaves the same
as C<next> in that each row is returned as an appropriate
C<Class::AlzaboWrapper> subclass object.  Returns a hash keyed to the
table name(s).

=item * all

Returns an array containing all the remaining objects in the cursor.
If the wrapped cursor just returned single rows, then it returns an
array of objects.  Otherwise, it returns an array of array references,
with each reference containing one set of objects.

=item * count

A simple wrapper around the underlying cursor's C<count()> method.

=back

=head1 SUPPORT

The Alzabo docs are conveniently located online at
http://www.alzabo.org/docs/.

There is also a mailing list.  You can sign up at
http://lists.sourceforge.net/lists/listinfo/alzabo-general.

Please don't email me directly.  Use the list instead so others can
see your questions.

=head1 COPYRIGHT

Copyright (c) 2002-2005 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
