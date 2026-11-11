use v5.36;

package DBIx::Squirrel::Errors;

use experimental qw(try);

use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_coderef is_ref);

use Ekorn::Pipeline::Errors qw();

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(at_caller croakf failed in_method);

# The packages Carp looks past, to croak at the line that called
# DBIx::Squirrel: the DBI's own, which call DBIx::Squirrel's methods, such
# as prepare from prepare_cached, Ekorn::Pipeline's, which runs
# DBIx::Squirrel's stages, and DBIx::Squirrel's. Each of them that croaks
# takes this list as its @CARP_NOT.
our @INTERNAL = (
    qw(
        DBI                           DBI::db                  DBI::st
        DBD::_::common                DBD::_::db               DBD::_::st
        DBIx::Squirrel                DBIx::Squirrel::db       DBIx::Squirrel::st
        DBIx::Squirrel::Context       DBIx::Squirrel::Errors   DBIx::Squirrel::Gather
        DBIx::Squirrel::Iterator      DBIx::Squirrel::Pipeline DBIx::Squirrel::Pipes
        DBIx::Squirrel::Placeholders  DBIx::Squirrel::Result   DBIx::Squirrel::Results
        DBIx::Squirrel::Sugar         DBIx::Squirrel::Util
        DBIx::Squirrel::Stages::Batch DBIx::Squirrel::Stages::Flow
        DBIx::Squirrel::Stages::Rows  DBIx::Squirrel::Stages::Taps
    ),
    @Ekorn::Pipeline::Errors::INTERNAL,
);
our @CARP_NOT = @INTERNAL;

# The files at_caller has been called from. A warning located at a line
# of one of them is one the DBI gave there.
my %CALLERS;

# Run a block calling the DBI, and return what it returns. If the DBI
# raises an error, as it does under RaiseError, at the line of the block,
# raise it again at the line that called DBIx::Squirrel. Any other error,
# such as an object, or a string from a HandleError callback, is raised
# again as it was. A warning the DBI gives, as it does under PrintError,
# is given at the line that called DBIx::Squirrel too, as plain DBI gives
# it.
#
# The handler of warnings is one sub, not a closure made for each call,
# as this runs for each statement executed; what it needs is in package
# variables, local to the call. When at_caller runs inside itself, as it
# does when the DBI calls a method of DBIx::Squirrel's, the inner call
# keeps the handler the outer one passes warnings on to.
#
# Each branch of the try returns or dies, which Perl::Critic can't see.
sub at_caller : prototype(&) ($code) {    ## no critic (Subroutines::RequireFinalReturn)
    my $file = (caller)[1];
    $CALLERS{$file} = 1;
    my $handler = $SIG{__WARN__};
    local our $OUTER
        = is_coderef($handler) && $handler == \&_moved ? $OUTER : $handler;
    local $SIG{__WARN__} = \&_moved;
    try {
        return $code->();
    }
    catch ($e) {
        my($message, $at) = is_ref($e) ? () : _location($e);
        die $e    ## no critic (ErrorHandling::RequireCarping)
            unless defined $at && $at eq $file;
        croak $message;
    }
}

# Handle a warning given inside at_caller: give one located at a line of a
# file at_caller was called from at the line that called DBIx::Squirrel
# instead, and pass it on.
sub _moved ($warning) {
    my($message, $at) = _location($warning);
    $warning = Carp::shortmess($message)
        if defined $at && $CALLERS{$at};
    _warn(our $OUTER, $warning);
    return;
}

# Return a message Perl located, without its location, and the file it
# was located at, or nothing if it has no location.
sub _location ($message) {
    # Where Perl says a die or warn happened, and the input it was reading.
    state $INPUT = qr( , \ <[^>]*> \ (?: line | chunk ) \ \d+ )x;
    state $AT    = qr( \A (.*) \ at \ (.+?) \ line \ \d+ $INPUT? \. \n \z )xs;
    return $message =~ $AT;
}

# Give a warning to the __WARN__ handler given, or, without one, warn it.
# A warn inside a handler, as this is, isn't handled again.
sub _warn ($handler, $warning) {
    return $handler->($warning) if is_coderef($handler);
    warn $warning;    ## no critic (ErrorHandling::RequireCarping)
    return;
}

# Croak with a message made by sprintf from a format and its arguments,
# as croak itself would, at the same line: goto leaves no frame of its
# own for Carp to see. It's a sub without a signature, as goto passes @_.
sub croakf {    ## no critic (Subroutines::RequireArgUnpacking)
    my $format = shift;
    @_ = (sprintf $format, @_);
    goto &Carp::croak;
}

# Return the message the DBI raises when a handle's method fails, as
# "DBD::SQLite::db prepare failed: ...".
sub failed ($h, $method) {
    return "$h->{ImplementorClass} $method failed: @{[ $h->errstr // '' ]}";
}

# Run code as a method of a database handle, and return what it returns.
# An error the DBI raises for a method the code calls, such as prepare or
# execute, is raised again as the DBI raises one for the handle's method,
# as "DBD::SQLite::db do failed: ...", as plain DBI does, and so is a
# warning the DBI gives for one, as it does under PrintError.
#
# Its handler of warnings is one sub, as at_caller's is. Inside itself,
# the outer call's method is the one named, as plain DBI names the method
# called.
sub in_method ($dbh, $method, $code) {    ## no critic (Subroutines::RequireFinalReturn)
    my $handler = $SIG{__WARN__};
    local our @METHOD
        = is_coderef($handler) && $handler == \&_renaming
        ? @METHOD
        : ($dbh, $method, $handler);
    local $SIG{__WARN__} = \&_renaming;
    try {
        return $code->();
    }
    catch ($e) {
        die $e    ## no critic (ErrorHandling::RequireCarping)
            if is_ref($e);
        die _renamed($e, $dbh, $method);    ## no critic (ErrorHandling::RequireCarping)
    }
}

# Handle a warning given inside in_method: name the method in_method
# was given, and pass it on.
sub _renaming ($warning) {
    my($dbh, $method, $outer) = our @METHOD;
    _warn($outer, _renamed($warning, $dbh, $method));
    return;
}

# Return a message the DBI gave for a method that failed, naming the
# handle's method given in its place.
sub _renamed ($message, $dbh, $method) {
    state $DBI_FAILED = qr( \A DBD:: [\w:]+ :: (?: db | st ) \ \w+ \ failed: )x;
    return $message
        =~ s( $DBI_FAILED )("$dbh->{ImplementorClass} $method failed:")xer;
}

1;
__END__

=encoding utf8

=for stopwords croakf

=head1 NAME

DBIx::Squirrel::Errors - report the DBI's errors at the caller's line

=head1 SYNOPSIS

    use DBIx::Squirrel::Errors qw(at_caller);

    my $sth = at_caller { $self->SUPER::prepare($statement) };

=head1 DESCRIPTION

Under C<RaiseError>, the DBI reports an error at the line that called
it. Inside DBIx::Squirrel, that's a line of DBIx::Squirrel's own, which
is no help to its user. This module moves the error to the user's
line. It does the same for the DBI's warnings, under C<PrintError>.
Nothing is exported by default.

=head1 VARIABLES

=head2 @INTERNAL

    our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

The packages L<Carp> looks past to report an error at the line that
called DBIx::Squirrel: the DBI's, DBIx::Squirrel's, and
L<Ekorn::Pipeline>'s, which runs its stages. A module of stages, or of
functions that take stages, sets its C<@CARP_NOT> to it. Then what it
croaks while a stage runs is reported at the line that asked for the
result, not inside DBIx::Squirrel.

=head1 FUNCTIONS

=head2 at_caller

    @values = at_caller { ... };

Runs the block, which calls the DBI, and returns what it returns, in
the same context. The block may die with a string located at the
block's own file. Then the location is removed, and the message is
raised again with L<Carp/croak>. That reports it at the first line
outside the DBI and DBIx::Squirrel. The DBI's message itself, such as
C<DBD::SQLite::db prepare failed: ...>, is unchanged. Any other error,
such as an object, or a string from a C<HandleError> callback, is
raised again unchanged.

A warning given while the block runs, as the DBI gives one under
C<PrintError>, is moved the same way, if it's located at a line of a
file C<at_caller> has been called from. It's passed on to the
C<__WARN__> handler there was before, or warned if there was none.

=head2 croakf

    croakf 'Expected a value for each placeholder (none for %s)', $names;

Croaks with a message made by C<sprintf> from a format and its
arguments. It reports it at the same line as L<Carp/croak> would.

The format is a literal, written in the code. Values go in as
arguments, through C<%s> and the like, never as the format. A format
made from data does whatever its C<%> directives say. C<%999999999s>,
for example, makes a string of a gigabyte.

=head2 failed

    croak failed($dbh, 'prepare');

Returns the message the DBI raises under C<RaiseError> when a handle's
method fails, such as C<DBD::SQLite::db prepare failed: ...>. It's for
an error DBIx::Squirrel raises itself.

=head2 in_method

    return in_method($dbh, 'do', sub { ... });

Runs the code as one method of a database handle, and returns what it
returns. The DBI may raise an error for a method the code calls, such
as C<DBD::SQLite::st execute failed: ...>. It's raised again as the
DBI raises one for the handle's method, C<DBD::SQLite::db do failed: ...>,
as plain DBI does. Any other error is raised again unchanged.

A warning the DBI gives for a method the code calls, as it does under
C<PrintError>, names the handle's method too. It's passed on to the
C<__WARN__> handler there was before, or warned if there was none.
When C<in_method> runs inside itself, the outer call's method is the
one named.

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI/RaiseError>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
