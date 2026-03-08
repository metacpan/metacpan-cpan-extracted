package DBIx::Class::Async::Exception;

$DBIx::Class::Async::Exception::VERSION   = '0.64';
$DBIx::Class::Async::Exception::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use overload
    '""'     => \&message,
    'bool'   => sub { 1 },
    fallback => 1;

=head1 NAME

DBIx::Class::Async::Exception - Base class for DBIx::Class::Async exceptions

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    # In application code -- catch any async exception
    use Try::Tiny;

    try {
        $rs->async_update_or_create(\%data)->get;
    } catch {
        if ( ref $_ && $_->isa('DBIx::Class::Async::Exception::RelationshipAsColumn') ) {
            warn "Fix your hashref: " . $_->hint;
        }
        elsif ( ref $_ && $_->isa('DBIx::Class::Async::Exception') ) {
            warn "Async DBIC error: " . $_->message;
            warn "Original: "         . $_->original_error if $_->original_error;
        }
        else {
            die $_;  # re-throw unknown exceptions
        }
    };

    # Load a specific subclass directly when you need to throw or catch it by name
    use DBIx::Class::Async::Exception::RelationshipAsColumn;

    DBIx::Class::Async::Exception::RelationshipAsColumn->throw(
        message      => "Relationship 'Details' passed where a column was expected",
        relationship => 'Details',
        source_class => 'My::Schema::Result::Operation',
        operation    => 'update_or_create',
        hint         => "Omit 'Details' from the hashref if you have no related rows.",
    );

=head1 DESCRIPTION

Base class for all structured exceptions thrown by L<DBIx::Class::Async>.
Consistent with the interface of L<DBIx::Class::Exception>: objects stringify
to their message, support boolean overload, and provide C<throw>/C<rethrow>.

This module defines only the base class. Each subclass lives in its own file
and must be loaded explicitly, or loaded transitively by
L<DBIx::Class::Async::Exception::Factory> which loads all subclasses as part
of its own initialisation.

In normal use you do not need to load this module directly. Loading
L<DBIx::Class::Async::Exception::Factory> in C<Async.pm> is sufficient --
the Factory loads the base class and all subclasses, and is the sole entry
point for translating raw L<DBIx::Class> errors into typed exception objects.

=head2 Exception hierarchy

    DBIx::Class::Async::Exception
    +-- DBIx::Class::Async::Exception::RelationshipAsColumn
    +-- DBIx::Class::Async::Exception::NotInStorage
    +-- DBIx::Class::Async::Exception::MissingColumn
    +-- DBIx::Class::Async::Exception::NoSuchRelationship
    +-- DBIx::Class::Async::Exception::AmbiguousColumn

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        message        => $args{message}        // '(no message)',
        hint           => $args{hint}           // undef,
        original_error => $args{original_error} // undef,
        operation      => $args{operation}      // undef,
        source_class   => $args{source_class}   // undef,
        stacktrace     => $args{stacktrace}     // undef,
    }, $class;
}

=head1 METHODS

=head2 throw

    DBIx::Class::Async::Exception->throw(%args);
    DBIx::Class::Async::Exception->throw($exception_object);

Constructs and throws an exception. C<%args> are passed to C<new()>. If a
single argument is passed and is already an instance of this class or a
subclass, it is re-thrown as-is -- consistent with L<DBIx::Class::Exception/throw>.

=cut

sub throw {
    my ($class, @args) = @_;

    if ( @args == 1 && ref $args[0] && $args[0]->isa(__PACKAGE__) ) {
        $args[0]->rethrow;
    }

    my %args = @args == 1 ? (message => $args[0]) : @args;
    die $class->new(%args);
}

=head2 rethrow

    $exception->rethrow;

Re-throws the exception object without modifying it.

=cut

sub rethrow {
    my ($self) = @_;
    die $self;
}

=head2 message

The human-readable error message. Also what the object stringifies to.

=cut

sub message        { $_[0]->{message}        }

=head2 hint

An optional actionable suggestion for how to fix the problem.

=cut

sub hint           { $_[0]->{hint}           }

=head2 original_error

The raw exception string from L<DBIx::Class>, preserved for debugging or logging.

=cut

sub original_error { $_[0]->{original_error} }

=head2 operation

The DBIC operation being performed when the error occurred,
e.g. C<'update_or_create'>, C<'create'>, C<'find'>. May be undef.

=cut

sub operation      { $_[0]->{operation}      }

=head2 source_class

The fully-qualified result class associated with the error,
e.g. C<'My::Schema::Result::Operation'>. May be undef.

=cut

sub source_class   { $_[0]->{source_class}   }

=head2 stacktrace

Optional stack trace string, populated when C<< stacktrace => 1 >> is passed
to C<throw> or C<new>, mirroring L<DBIx::Class::Exception> behaviour.

=cut

sub stacktrace     { $_[0]->{stacktrace}     }

=head2 stringify

Alias for C<message>. Called automatically by the C<""> overload.

=cut

sub stringify      { $_[0]->message          }

=head1 SUBCLASSES

Each subclass lives in its own file. Load a subclass directly when you need
to reference it by name, or use L<DBIx::Class::Async::Exception::Factory>
which loads all subclasses as part of its own initialisation.

=over 4

=item L<DBIx::Class::Async::Exception::RelationshipAsColumn>

Thrown when a relationship name is passed as a hashref key with an C<undef>
value (RT#127065). Adds: C<relationship>, C<relationship_type>.

=item L<DBIx::Class::Async::Exception::NotInStorage>

Thrown when C<update()> or C<delete()> is called on an un-inserted row.
Adds: C<row_class>.

=item L<DBIx::Class::Async::Exception::MissingColumn>

Thrown when a required column is absent from a create/insert hashref.
Adds: C<column>.

=item L<DBIx::Class::Async::Exception::NoSuchRelationship>

Thrown when a relationship name used in C<join>/C<prefetch> is not declared.
Adds: C<relationship>.

=item L<DBIx::Class::Async::Exception::AmbiguousColumn>

Thrown when a column name is ambiguous across joined tables.
Adds: C<column>.

=back

=head1 SEE ALSO

L<DBIx::Class::Async::Exception::Factory>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Async::Exception

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Async::Exception
