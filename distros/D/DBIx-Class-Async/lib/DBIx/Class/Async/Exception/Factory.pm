package DBIx::Class::Async::Exception::Factory;

$DBIx::Class::Async::Exception::Factory::VERSION   = '0.64';
$DBIx::Class::Async::Exception::Factory::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use DBIx::Class::Async::Exception;
use DBIx::Class::Async::Exception::RelationshipAsColumn;
use DBIx::Class::Async::Exception::NotInStorage;
use DBIx::Class::Async::Exception::MissingColumn;
use DBIx::Class::Async::Exception::NoSuchRelationship;
use DBIx::Class::Async::Exception::AmbiguousColumn;

=head1 NAME

DBIx::Class::Async::Exception::Factory - Translate raw DBIx::Class errors into typed exception objects

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    use DBIx::Class::Async::Exception::Factory;
    use Try::Tiny;

    try {
        # ... async DBIC operation ...
    }
    catch {
        # Translates the raw string error into the right typed subclass,
        # then re-throws it.
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
            error        => $_,
            schema       => $self->schema,
            result_class => $result_class,
            operation    => $operation,
        );
    };

=head1 DESCRIPTION

This factory inspects raw L<DBIx::Class> exception strings, matches them
against known error patterns, and throws the appropriate
L<DBIx::Class::Async::Exception> subclass. If no pattern matches, it wraps
the error in the base L<DBIx::Class::Async::Exception> so callers always
receive a structured object rather than a plain string.

=cut

#
#
# Pattern Table
# Each entry: match regex, exception class, builder sub

my @PATTERNS = (

    # relationship name passed where a column was expected
    {
        class => 'DBIx::Class::Async::Exception::RelationshipAsColumn',
        match => qr/No such column '(\w+)' on (\S+)/,
        build => sub {
            my (%p) = @_;
            my ($col, $raw_source) = @{$p{captures}};

            my ($rel_type) = _rel_type($p{schema}, $raw_source, $col);
            my $is_rel     = defined $rel_type;

            return () unless $is_rel;  # let fallback handle genuine unknown columns

            return (
                message           => _fmt_message(
                    "Relationship '$col' passed where a column name was expected on $raw_source"
                ),
                relationship      => $col,
                relationship_type => $rel_type,
                source_class      => $p{result_class} // $raw_source,
                operation         => $p{operation},
                hint              => _rel_hint($col, $p{operation}),
                original_error    => $p{error},
            );
        },
    },

    # Genuinely unknown column (not a relationship -- fallthrough from above)
    {
        class => 'DBIx::Class::Async::Exception',
        match => qr/No such column '(\w+)' on (\S+)/,
        build => sub {
            my (%p) = @_;
            my ($col, $raw_source) = @{$p{captures}};
            return (
                message        => _fmt_message("No such column '$col' on $raw_source"),
                source_class   => $p{result_class} // $raw_source,
                operation      => $p{operation},
                hint           => "Check that '$col' is declared with add_columns() on $raw_source.",
                original_error => $p{error},
            );
        },
    },

    # update/delete on a row not yet inserted
    {
        class => 'DBIx::Class::Async::Exception::NotInStorage',
        match => qr/Unable to perform (\w+) .* not in_storage/i,
        build => sub {
            my (%p) = @_;
            my ($op) = @{$p{captures}};
            return (
                message        => _fmt_message("Cannot $op a row that has not been inserted (in_storage is false)"),
                row_class      => $p{result_class},
                operation      => $op,
                hint           => "Call insert() or create() before calling $op().",
                original_error => $p{error},
            );
        },
    },

    # Missing required column on insert
    {
        class => 'DBIx::Class::Async::Exception::MissingColumn',
        match => qr/Missing value for required column '(\w+)'/,
        build => sub {
            my (%p) = @_;
            my ($col) = @{$p{captures}};
            return (
                message        => _fmt_message("Required column '$col' was not provided"),
                column         => $col,
                source_class   => $p{result_class},
                operation      => $p{operation},
                hint           => "Add '$col' to your insert/create hashref.",
                original_error => $p{error},
            );
        },
    },

    # No such relationship in join/prefetch
    {
        class => 'DBIx::Class::Async::Exception::NoSuchRelationship',
        match => qr/No such relationship (\w+) on (\S+)/,
        build => sub {
            my (%p) = @_;
            my ($rel, $raw_source) = @{$p{captures}};
            return (
                message        => _fmt_message("No relationship '$rel' on $raw_source"),
                relationship   => $rel,
                source_class   => $p{result_class} // $raw_source,
                operation      => $p{operation},
                hint           => "Check that '$rel' is declared with has_many(), belongs_to(), or might_have() on $raw_source.",
                original_error => $p{error},
            );
        },
    },

    # Ambiguous column in multi-table query
    {
        class => 'DBIx::Class::Async::Exception::AmbiguousColumn',
        match => qr/Column '(\w+)' in (?:field|order|group|where) clause is ambiguous/i,
        build => sub {
            my (%p) = @_;
            my ($col) = @{$p{captures}};
            return (
                message        => _fmt_message("Ambiguous column '$col' -- it exists in multiple joined tables"),
                column         => $col,
                source_class   => $p{result_class},
                operation      => $p{operation},
                hint           => "Qualify the column: use 'me.$col' for the primary table or 'relname.$col' for a join.",
                original_error => $p{error},
            );
        },
    },

    # HAVING clause without GROUP BY, produced when DBIC generates
    # a DELETE subquery from a ResultSet that has group_by/having attributes
    # and silently drops the GROUP BY. DBIx::Class::Async routes such
    # deletes through delete_all (fetch PKs first, then DELETE by PK) so
    # this error should not occur in normal use, but may still arrive from
    # raw worker errors or from callers constructing queries outside the
    # standard ResultSet API.
    {
        class => 'DBIx::Class::Async::Exception',
        match => qr/HAVING clause(?: is)? (?:used )?without (?:a )?GROUP BY/i,
        build => sub {
            my (%p) = @_;
            return (
                message        => _fmt_message(
                    "HAVING clause used without GROUP BY -- this is usually caused by "
                    . "deleting from a ResultSet that has group_by/having attributes "
                ),
                source_class   => $p{result_class},
                operation      => $p{operation},
                hint           => "Use delete_all() instead of delete() when your ResultSet "
                               . "has group_by or having attributes, or call search() with "
                               . "only group_by/having before counting/aggregating rather "
                               . "than deleting.",
                original_error => $p{error},
            );
        },
    },

);

=head1 METHODS

=head2 throw_from_dbic_error

    DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
        error        => $raw_error_string,   # required
        schema       => $schema,             # optional, enables relationship detection
        result_class => $result_class,       # optional, e.g. 'My::Schema::Result::Foo'
        operation    => $operation,          # optional, e.g. 'update_or_create'
    );

Matches C<error> against known DBIC error patterns and throws the appropriate
L<DBIx::Class::Async::Exception> subclass. If no pattern matches, wraps the
raw string in the base L<DBIx::Class::Async::Exception> and throws that.

Always throws -- never returns.

=cut

sub throw_from_dbic_error {
    my ($class, %p) = @_;

    my $error = $p{error} // '';

    # If already one of ours, re-throw as-is
    if ( ref $error && $error->isa('DBIx::Class::Async::Exception') ) {
        $error->rethrow;
    }

    # stringify if it's some other object (e.g. DBIx::Class::Exception)
    $error = "$error" if ref $error;

    for my $rule (@PATTERNS) {
        if ( my @captures = ($error =~ $rule->{match}) ) {
            my %args = eval {
                $rule->{build}->(
                    %p,
                    error    => $error,
                    captures => \@captures,
                );
            };
            next if $@ || !%args;  # build failed or returned empty -- try next pattern

            $rule->{class}->throw(%args);
            return;  # unreachable, but explicit
        }
    }

    # No pattern matched -- wrap in base exception
    DBIx::Class::Async::Exception->throw(
        message        => _fmt_message($error),
        original_error => $error,
        operation      => $p{operation},
        source_class   => $p{result_class},
    );
}

=head2 make_from_dbic_error

    my $exception = DBIx::Class::Async::Exception::Factory->make_from_dbic_error(%args);

Like L</throw_from_dbic_error> but returns the exception object instead of
throwing it. Useful when you need to attach the exception to a failed Future
rather than die-ing directly.

=cut

sub make_from_dbic_error {
    my ($class, %p) = @_;

    my $exception;
    eval {
        $class->throw_from_dbic_error(%p);
    };
    $exception = $@;

    # Paranoia: if something went wrong in throw itself, wrap it
    unless ( ref $exception && $exception->isa('DBIx::Class::Async::Exception') ) {
        $exception = DBIx::Class::Async::Exception->new(
            message        => "Exception factory failed: $exception",
            original_error => $p{error},
        );
    }

    return $exception;
}

=head2 validate_or_fail

    my $exception = DBIx::Class::Async::Exception::Factory->validate_or_fail(
        args         => \%hashref,       # the create/update hashref
        schema       => $schema,         # DBIx::Class::Schema instance or class name
        result_class => $result_class,   # e.g. 'My::Schema::Result::Operation'
        operation    => $operation,      # e.g. 'update_or_create'
    );
    return Future->fail($exception) if $exception;

Pre-flight check intended for use in C<_call_worker> before dispatching to the
worker process. Inspects C<args> for relationship keys with C<undef> values and
returns a L<DBIx::Class::Async::Exception::RelationshipAsColumn> object if one
is found, or C<undef> if the args look clean.

Returns an exception object rather than throwing, so the caller can decide how
to surface it -- typically as C<< Future->fail($exception) >> to keep error
handling consistent with the rest of the async pipeline.

=cut

sub validate_or_fail {
    my ($class, %p) = @_;

    my $args         = $p{args}         or return;
    my $schema       = $p{schema}       or return;
    my $result_class = $p{result_class} or return;

    return unless ref($args) eq 'HASH';

    # schema may be a class name string rather than a connected object
    my $schema_obj = ref($schema) ? $schema : eval { $schema->connect } or return;

    my $source = _find_source($schema_obj, $result_class) or return;

    for my $key (keys %$args) {
        next if defined $args->{$key};
        next unless $source->has_relationship($key);

        my $rel_info = $source->relationship_info($key);
        my $rel_type = $rel_info ? ($rel_info->{attrs}{accessor} // 'multi') : 'relationship';
        my $op       = $p{operation} // 'operation';

        return DBIx::Class::Async::Exception::RelationshipAsColumn->new(
            message           => _fmt_message(
                "Relationship '$key' passed as undef in ${op}() on $result_class"
                . " -- omit the key if you have no related rows to insert"
            ),
            relationship      => $key,
            relationship_type => $rel_type,
            source_class      => $result_class,
            operation         => $op,
            hint              => "Omit '$key' from the hashref entirely if there are no "
                               . "related rows to insert. To insert related rows, pass an "
                               . "arrayref of hashrefs: $key => [\\%related_data].",
        );
    }

    return;  # no issues found
}

#
#
# Private Helpers

sub _fmt_message {
    my ($msg) = @_;
    return "[DBIx::Class::Async] $msg";
}

sub _rel_type {
    my ($schema, $raw_source_class, $rel_name) = @_;
    return unless $schema && $raw_source_class && $rel_name;

    my $source = _find_source($schema, $raw_source_class) or return;
    return unless $source->has_relationship($rel_name);

    my $info = $source->relationship_info($rel_name);
    return $info ? ($info->{attrs}{accessor} // 'multi') : 'relationship';
}

sub _find_source {
    my ($schema, $class) = @_;

    # Try direct match on result_class
    for my $name ($schema->sources) {
        my $src = eval { $schema->source($name) } or next;
        return $src if $src->result_class eq $class;
    }

    # Fallback: strip namespace prefix to guess source name
    if ( $class =~ /::(?:Result::)?(\w+)$/ ) {
        return eval { $schema->source($1) } || undef;
    }

    return;
}

sub _rel_hint {
    my ($rel, $op) = @_;
    $op //= 'create';
    return "Omit '$rel' from the hashref entirely if there are no related rows to insert. "
         . "If you do have related rows, pass an arrayref of hashrefs: $rel => [\\%related_data].";
}

=head1 ADDING NEW PATTERNS

Add a new entry to the C<@PATTERNS> array:

    {
        class => 'DBIx::Class::Async::Exception::YourSubclass',  # or base class
        match => qr/your regex with (\w+) captures/,
        build => sub {
            my (%p) = @_;
            # $p{error}        -- raw error string
            # $p{captures}     -- arrayref of regex captures
            # $p{schema}       -- schema object (may be undef)
            # $p{result_class} -- e.g. 'My::Schema::Result::Foo' (may be undef)
            # $p{operation}    -- e.g. 'create' (may be undef)
            #
            # Return a flat %args hash to pass to the exception class constructor.
            # Return an empty list () to skip this pattern and try the next one.
            return (
                message        => _fmt_message("Your friendly message"),
                hint           => "What the user should do.",
                original_error => $p{error},
            );
        },
    },

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

    perldoc DBIx::Class::Async::Exception::Factory

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

1; # End of DBIx::Class::Async::Exception::Factory
