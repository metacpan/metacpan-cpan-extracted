use v5.36;

package DBIx::Squirrel::Placeholders;

use Exporter   qw(import);
use List::Util qw(any         max        uniq);
use Ref::Util  qw(is_arrayref is_hashref is_plain_ref);

use DBIx::Squirrel::Errors qw(croakf);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    expand_lists
    is_numbered
    key_of
    place_values
    study_sql
    trim_sql
    values_for
    values_taken
);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Remove the blank space from around a statement; return what's left, or
# an empty string if it was all blank.
sub trim_sql ($statement) {
    return ($statement // '') =~ s( \A \s+ | \s+ \z )()gxr;
}

# Study a statement, with the options given; return a map of its
# placeholders' positions, from 1, to their names, the statement with each
# placeholder rewritten as "?", and the statement as trimmed. Return
# nothing if the statement is blank. If a placeholder takes a list,
# written with "..." before it, also return a map of each position taking
# a list, and the pieces of the statement around its placeholders, to
# expand the lists with expand_lists.
sub study_sql ($statement, $options = {}) {
    my $trimmed = trim_sql($statement);
    return unless length $trimmed;
    my $dialect = $options->{ekorn_dialect} // '';

    # What isn't SQL code, and is stepped over unchanged: quoted strings and
    # identifiers, comments, PostgreSQL's dollar-quoted bodies, and a
    # backslash before "?", ":" or "$", which DBD::Pg takes to mean the
    # character isn't a placeholder, and removes.
    state $STRING   = qr( ' (?: [^'] | '' )* ' )x;
    state $E_STRING = qr( (?<! \w ) [Ee] ' (?: [^'\\] | \\. | '' )* ' )x;
    state $IDENT    = qr( " (?: [^"] | "" )* " | ` [^`]* ` )x;
    state $COMMENT  = qr( -- [^\n]* | /\* .*? \*/ )xs;
    state $DOLLARS  = qr( \$ (?<tag> (?: [A-Za-z_]\w* )? ) \$ .*? \$ \k<tag> \$ )xs;
    state $ESCAPED  = qr( \\ [?:\$] )x;
    state $NOT_SQL
        = qr( $E_STRING | $STRING | $IDENT | $COMMENT | $DOLLARS | $ESCAPED )x;

    # The same for MySQL and MariaDB, where a backslash escapes a character
    # in a string, "..." is a string, not an identifier, and "#" starts a
    # comment.
    state $MYSQL_STRING
        = qr( ' (?: [^'\\] | \\. | '' )* ' | " (?: [^"\\] | \\. | "" )* " )x;
    state $MYSQL_NOT_SQL = qr( $MYSQL_STRING | ` [^`]* ` | $COMMENT | \# [^\n]* )x;
    state %NOT_SQL_FOR   = (mysql => $MYSQL_NOT_SQL, MariaDB => $MYSQL_NOT_SQL);

    # A placeholder: "?", "?" and a position, or ":" or "$" and a position or
    # a name; not after a colon, as in a cast, or inside an identifier. A
    # position is in the digits 0-9, as \d matches a digit of any script;
    # the /a flag would keep \w to ASCII too, and a name can be in any.
    state $PLACEHOLDER = qr( (?<! [:\w\$] ) (?: \? [0-9]* | [:\$] \w+ ) )x;

    # The same, for DBD::Pg's options: only "$" and a position, or anything
    # but ":" and a position or a name.
    state $DOLLAR_ONLY = qr( (?<! [:\w\$] ) \$ [0-9]+ )x;
    state $NO_COLONS   = qr( (?<! [:\w\$] ) (?: \? [0-9]* | \$ \w+ ) )x;

    # With pg_placeholder_dollaronly, DBD::Pg reads the placeholders itself,
    # so the statement is left as it is.
    my $pg          = $dialect eq 'Pg';
    my $dollar_only = $pg && $options->{pg_placeholder_dollaronly};
    my $placeholder
        = $dollar_only                               ? $DOLLAR_ONLY
        : $pg && $options->{pg_placeholder_nocolons} ? $NO_COLONS
        :                                              $PLACEHOLDER;

    # Each placeholder found, where it is in the trimmed statement, and
    # whether "..." before it makes it take a list.
    my $not_sql = $NOT_SQL_FOR{$dialect} // $NOT_SQL;
    my $splat_or_not
        = qr( (?<! [:\w\$] ) (?<splat> \.\.\. )? (?<placeholder> $placeholder ) )x;
    my(@placeholders, @spans, %lists);
    my $normalised = $trimmed =~ s(
        (?<not_sql> $not_sql ) | $splat_or_not
    )(
        if (exists $+{not_sql}) {
            $+{not_sql};
        }
        else {
            push @placeholders, $+{placeholder};
            push @spans,        [$-[0], $+[0]];
            $lists{ scalar @placeholders } = 1 if defined $+{splat};
            '?';
        }
    )gerx;
    $normalised = $trimmed if $dollar_only;

    # One style of placeholder to a statement.
    my @styles = uniq map { _style($_) } @placeholders;
    croakf 'Expected one placeholder style, not several (%s)', join ', ', @styles
        if @styles > 1;

    my %positions = map { ($_ + 1 => $placeholders[$_]) } keys @placeholders;
    return \%positions, $normalised, $trimmed
        unless %lists;

    # With pg_placeholder_dollaronly, the statement goes to DBD::Pg as
    # written, with no way to expand a list.
    my($first) = sort { $a <=> $b } keys %lists;
    croakf 'Expected no list placeholder with pg_placeholder_dollaronly (%s)',
        "...$positions{$first}"
        if $dollar_only;

    # The pieces around the placeholders, the first before the first, and
    # the last after the last.
    my($from, @pieces) = (0);
    for my $span (@spans) {
        push @pieces, substr $trimmed, $from, $span->[0] - $from;
        $from = $span->[1];
    }
    push @pieces, substr $trimmed, $from;
    return \%positions, $normalised, $trimmed, \%lists, \@pieces;
}

# Return a placeholder's number or name, as a statement's map of its
# placeholders keys it: without its sigil, and a number as a number. A
# bare "?" is keyed by its position, given with it.
sub key_of ($placeholder, $position = undef) {
    return $position if $placeholder eq '?';
    my $key = $placeholder =~ s( \A [?:\$] )()xr;
    return $key =~ m( \A \d+ \z )xa ? 0+ $key : $key;
}

# Return true if a statement's placeholders are numbered, not named,
# given its map of their numbers or names to their positions.
sub is_numbered ($binds) {
    my($key) = keys %$binds;
    return $key =~ m( \A \d+ \z )xa;
}

# Return how many values a statement takes in order, given its map of
# its placeholders' numbers or names to their positions: the highest
# number, or none if they're named.
sub values_taken ($binds) {
    return is_numbered($binds) ? max keys %$binds : 0;
}

# Return each placeholder's number or name, with the value given for it,
# croaking unless there's a value for each, and no other, given the
# statement's map of its placeholders' numbers or names to their
# positions.
sub values_for ($binds, @args) {
    if (is_numbered($binds)) {
        my $needed = values_taken($binds);
        croakf 'Expected %d bind values, not %d', $needed, scalar @args
            unless @args == $needed;
        return map { ($_ => $args[$_ - 1]) } keys %$binds;
    }
    my %values;
    if (@args == 1 && is_hashref($args[0])) {
        %values = %{ $args[0] };
    }
    else {
        croakf 'Expected names and values in pairs'
            if @args % 2;
        %values = @args;
    }
    my(%given, @unknown);
    for my $name (keys %values) {
        my $key = key_of($name);
        $given{$key} = $values{$name};
        push @unknown, $name unless $binds->{$key};
    }
    @unknown = sort @unknown;
    croakf 'Expected a placeholder of the statement (%s)', join ', ', @unknown
        if @unknown;
    my @missing = sort grep { !exists $given{$_} } keys %$binds;
    croakf 'Expected a value for each placeholder (none for %s)',
        join(', ', @missing)
        if @missing;
    return %given;
}

# Return a statement with list placeholders, as a statement handle keeps
# what was studied, with each list's "?" written once for each of its
# values, given the values for its placeholders' numbers or names, as
# values_for returns them; the map of each number or name to its
# positions in the statement returned; and the number of values in each
# list.
sub expand_lists ($state, $values) {
    my($lists, $pieces, $placeholders) = @$state{qw(Lists Pieces Placeholders)};
    my %lengths
        = map { ($_ => scalar _list($lists->{$_}, $values->{$_})) } keys %$lists;
    my($statement, $taken, %binds) = ($pieces->[0], 0);
    for my $position (1 .. keys %$placeholders) {
        my $key   = key_of($placeholders->{$position}, $position);
        my $count = $lengths{$key} // 1;
        push @{ $binds{$key} }, $taken + 1 .. $taken + $count;
        $taken     += $count;
        $statement .= join(', ', ('?') x $count) . $pieces->[$position];
    }
    return $statement, \%binds, \%lengths;
}

# Return each position of a statement's placeholders, from 1, with the
# value for it, given what the statement handle keeps about it and the
# values for its placeholders' numbers or names. A list placeholder's
# positions take the values in its list in turn, and the list must have
# as many as the statement was prepared for.
sub place_values ($state, %values) {
    my($binds, $lists, $lengths) = @$state{qw(Binds Lists Lengths)};
    my @placed;
    for my $key (keys %values) {
        my $positions = $binds->{$key};
        unless ($lists && $lists->{$key}) {
            push @placed, map { ($_ => $values{$key}) } @$positions;
            next;
        }
        my @list = _list($lists->{$key}, $values{$key});
        croakf 'Expected %d values in a list, as prepared, not %d (%s)',
            $lengths->{$key}, scalar @list, $lists->{$key}
            unless @list == $lengths->{$key};
        push @placed, map { ($positions->[$_] => $list[$_ % @list]) } keys @$positions;
    }
    return @placed;
}

# Return the values in a list given for a list placeholder, named as it's
# written, croaking unless it's a reference to an ARRAY of at least one
# plain value.
sub _list ($name, $list) {
    croakf 'Expected a reference to an ARRAY for a list (%s)', $name
        unless is_arrayref($list);
    croakf 'Expected at least one value in a list (%s)', $name
        unless @$list;
    croakf 'Expected plain values in a list (%s)', $name
        if any { is_plain_ref($_) } @$list;
    return @$list;
}

# Return a placeholder's style, as an example of it: "?", "?1", ":1", "$1",
# ":name" or "$name".
sub _style ($placeholder) {
    my($sigil, $rest) = $placeholder =~ m( \A (.) (.*) \z )xs;
    return $sigil      if $rest eq '';
    return "${sigil}1" if $rest =~ m( \A \d+ \z )xa;
    return "${sigil}name";
}

1;
__END__

=encoding utf8

=for stopwords PostgreSQL's

=head1 NAME

DBIx::Squirrel::Placeholders - find the placeholders in a statement, and match values to them

=head1 SYNOPSIS

    use DBIx::Squirrel::Placeholders qw(study_sql trim_sql);

    my($positions, $normalised, $trimmed)
        = study_sql('SELECT * FROM artist WHERE id = :id');
    # ({1 => ':id'}, 'SELECT * FROM artist WHERE id = ?', ...)

    my($positions, $normalised, $trimmed, $lists, $pieces)
        = study_sql('SELECT * FROM artist WHERE id IN (...:ids)');
    # (..., {1 => 1}, ['SELECT * FROM artist WHERE id IN (', ')'])

=head1 DESCRIPTION

The functions L<DBIx::Squirrel::db> and L<DBIx::Squirrel::st> use to
find the placeholders in a statement, rewrite them as C<?> for the DBI,
and match the values given to them. They're for DBIx::Squirrel itself.
None is exported by default.

Several take a statement's map of its placeholders' numbers or names to
their positions, from 1, such as C<< {id => [1, 3], name => [2]} >>.
It's called C<$binds> below. Others take what a statement handle keeps
about its statement, called C<$state>, which holds that map as
C<Binds>.

=head1 FUNCTIONS

=head2 study_sql

    ($positions, $normalised, $trimmed) = study_sql($statement);
    ($positions, $normalised, $trimmed) = study_sql($statement, \%options);
    ($positions, $normalised, $trimmed, $lists, $pieces) = study_sql($statement);

Returns three values:

=over

=item * a hash reference mapping each placeholder's position, from 1,
to the placeholder as written (C<?>, C<?1>, C<:1>, C<$1>, C<:name> or
C<$name>);

=item * the statement with each placeholder rewritten as C<?>;

=item * the statement as L</trim_sql> returns it.

=back

It returns nothing if the statement is blank.

A placeholder with C<...> before it, such as C<...:ids>, takes a list.
The C<...> isn't part of the placeholder as mapped. A statement with
any such placeholders returns two more values. The first is a hash
reference whose keys are the positions taking a list. The second is an
array reference of the pieces of the statement around its
placeholders, one more than there are placeholders, for
L</expand_lists>.

A statement must use one style of placeholder throughout: C<?>, C<?1>,
C<:1>, C<$1>, C<:name> or C<$name>, with C<...> or without it. It
croaks if the statement uses more than one.

Placeholders are looked for only in the SQL itself. They aren't looked
for in quoted strings or identifiers, comments or PostgreSQL's
dollar-quoted bodies. Nor are casts, such as C<x::int>, or identifiers
containing C<$>, such as C<v$session>, placeholders. A C<?>, C<:> or
C<$> with a backslash before it isn't a placeholder either. Both are
left unchanged, for L<DBD::Pg>, which removes the backslash.

C<%options> can hold:

=over

=item ekorn_dialect

The SQL dialect the statement is written in, named as its DBI driver
is, as in C<< $dbh->{Driver}{Name} >>. For C<mysql> and C<MariaDB>, a
backslash escapes a character in a string, C<"..."> is a string, and
C<#> starts a comment. For any other dialect, or none, a backslash is
an ordinary character in a string, except in PostgreSQL's C<E'...'>
strings.

=item pg_placeholder_dollaronly

With C<ekorn_dialect> C<Pg>, only C<$1>-style placeholders are found.
The statement is returned unchanged, for L<DBD::Pg> to read. It croaks
if one of them takes a list, as the statement isn't rewritten.

=item pg_placeholder_nocolons

With C<ekorn_dialect> C<Pg>, the C<:1> and C<:name> styles aren't
placeholders.

=back

Anything else in C<%options> is ignored, so the attributes passed to
C<prepare> can be given unchanged.

=head2 trim_sql

    $trimmed = trim_sql($statement);

Returns the statement without the blank space around it, or an empty
string if it was all blank or C<undef>. Comments are kept.

=head2 key_of

    $key = key_of($placeholder);
    $key = key_of('?', $position);

Returns a placeholder's number or name, as a statement's map of its
placeholders keys it: without its sigil, and a number as a number. So
C<:id> and C<id> give C<id>, and C<$02> gives 2. A bare C<?> is keyed
by its position, given with it.

=head2 is_numbered

    $bool = is_numbered($binds);

Returns true if a statement's placeholders are numbered, not named.

=head2 values_taken

    $count = values_taken($binds);

Returns how many values a statement takes in order. That's its highest
number, or 0 if its placeholders are named.

=head2 values_for

    %values = values_for($binds, @bind_values);

Returns each of a statement's placeholders' numbers or names, with the
value given for it. Values for numbered placeholders are given in
order. Values for named ones are given by name, as pairs or in a hash
reference. It croaks unless there's a value for each, and no other.
See L<DBIx::Squirrel::st/bind>.

=head2 expand_lists

    ($statement, $binds, $lengths) = expand_lists($state, \%values);

Returns a statement with list placeholders, with each list's C<?>
written once for each of its values. It's given two things:

=over

=item * what a statement handle keeps about the statement: its
C<Placeholders>, the C<Pieces> L</study_sql> returns, and C<Lists>, a
map of each list placeholder's number or name to the placeholder as
written, for messages;

=item * the values for its placeholders, as L</values_for> returns
them.

=back

It also returns the map of each number or name to its positions in the
statement returned, and the number of values in each list.

It croaks unless each list is a reference to an ARRAY of at least one
plain value. A list can't be C<undef> or a value on its own, nor hold
an unblessed reference.

=head2 place_values

    %placed = place_values($state, %values);

Returns each position of a statement's placeholders, from 1, with the
value for it. It's given what the statement handle keeps about the
statement, and the values for its placeholders' numbers or names. A
list placeholder's positions take the values in its list in turn,
wherever it's used. The list must have as many values as the statement
was prepared for, in C<Lengths>.

=head1 SEE ALSO

L<DBIx::Squirrel::db>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
