package App::Actions::Schema;

use strict;
use warnings;
use Exporter qw(import);
use JSON::PP ();

use App::Actions::Error;
use App::Actions::Schema::Invalid;

our $VERSION = '0.002.1';

our @EXPORT_OK = qw(validate assert_valid describe_errors invalid_exit);

# A small JSON Schema subset: type, const, enum, properties, required, items
# and oneOf.  An object whose schema names properties also rejects keys the
# schema does not name, which is what keeps a key from slipping into a document
# without the schema gaining it too.
#
# It is deliberately smaller than JSON Schema.  The documents validated with it
# are this distribution's own, so every keyword here is one that is used, and a
# document that a full validator would reject for some other reason is a
# document this distribution does not print.
#
# Returns the list of errors, in document order, or an empty list when the
# value matches.  Callers that should stop on a mismatch use assert_valid.
sub validate {
    my ($value, $schema, $path) = @_;

    $path = '$' unless defined $path;

    if (ref $schema->{oneOf} eq 'ARRAY') {
        my $first;
        for my $alternative (@{ $schema->{oneOf} }) {
            my @errors = validate($value, $alternative, $path);
            return () unless @errors;
            $first = $errors[0] unless defined $first;
        }

        return ("$path: matches none of the alternative shapes (first said: $first)");
    }

    if (exists $schema->{const}) {
        return ("$path: expected " . _show($schema->{const}) . ', got ' . _show($value))
            unless _same($value, $schema->{const});
    }

    if (ref $schema->{enum} eq 'ARRAY') {
        return ("$path: " . _show($value) . ' is not one of '
            . join(', ', map { _show($_) } @{ $schema->{enum} }))
            unless grep { _same($value, $_) } @{ $schema->{enum} };
    }

    if (defined(my $type = $schema->{type})) {
        my @types = ref $type eq 'ARRAY' ? @$type : ($type);
        return ("$path: expected " . join(' or ', @types) . ', got ' . _show($value))
            unless grep { _is_type($value, $_) } @types;
    }

    my @errors;

    if (ref $value eq 'HASH' && ref $schema->{properties} eq 'HASH') {
        my $properties = $schema->{properties};

        for my $key (sort keys %$value) {
            push @errors, "$path.$key: unexpected key"
                unless exists $properties->{$key};
        }

        for my $key (@{ $schema->{required} || [] }) {
            push @errors, "$path.$key: missing"
                unless exists $value->{$key};
        }

        for my $key (sort keys %$properties) {
            next unless exists $value->{$key};
            push @errors, validate($value->{$key}, $properties->{$key}, "$path.$key");
        }
    }

    if (ref $value eq 'ARRAY' && ref $schema->{items} eq 'HASH') {
        for my $index (0 .. $#$value) {
            push @errors, validate($value->[$index], $schema->{items}, "$path\[$index]");
        }
    }

    return @errors;
}

# Stop when a document does not match the schema it claims to.  $what is the
# sentence's subject, such as "the action-run check --json document does not
# match App::Actions::Check->json_schema"; the first mismatch is appended, with
# a count of any others, so the message stays one readable line however far the
# document has drifted.
sub assert_valid {
    my ($value, $schema, $what) = @_;

    my @errors = validate($value, $schema);
    return 1 unless @errors;

    # An exception rather than a string: a command can tell a broken document
    # from every other way of failing, and give it the status that says so.
    # The message still carries no source location, because it reports a
    # document rather than a place in the code.
    die App::Actions::Schema::Invalid->new("$what: " . describe_errors(\@errors) . "\n");
}

# The first mismatch, with a count of the others, so a message stays one
# readable line however far a document has drifted.  Shared by assert_valid
# and "action-run validate", which report the same errors the same way.
sub describe_errors {
    my ($errors) = @_;

    my $more = @$errors > 1 ? sprintf(' (and %d more)', @$errors - 1) : '';

    return @$errors ? "$errors->[0]$more" : '';
}

# The exit status a command gives when a document of its own does not match
# the schema it ships.  EX_SOFTWARE from sysexits.h: the drift is a fault in
# this distribution, not in the environment or the workflow, so a caller that
# reads 2 as "the host needs fixing" does not mistake it for one.
sub invalid_exit { return 70 }

sub _is_type {
    my ($value, $type) = @_;

    return !defined $value ? 1 : 0 if $type eq 'null';
    return JSON::PP::is_bool($value) ? 1 : 0 if $type eq 'boolean';
    return ref $value eq 'ARRAY' ? 1 : 0 if $type eq 'array';
    return ref $value eq 'HASH' ? 1 : 0 if $type eq 'object';
    return 0 if !defined $value || ref $value;

    return $value =~ /\A-?\d+\z/ ? 1 : 0 if $type eq 'integer';
    return $value =~ /\A-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?\z/ ? 1 : 0
        if $type eq 'number';
    return 1 if $type eq 'string';

    return 0;
}

sub _same {
    my ($one, $other) = @_;

    # Two nulls are the same; two booleans are the same when both are true
    # or both false (a decoded boolean is an object, so it is not
    # "structured"); a null and a value, a boolean and anything else, or
    # anything structured, are not; two scalars are compared as strings, as
    # JSON compares them.
    my $booleans = JSON::PP::is_bool($one) + JSON::PP::is_bool($other);
    return (!defined $one && !defined $other) ? 1
        : $booleans == 2 ? (!$one == !$other ? 1 : 0)
        : $booleans ? 0
        : (!defined $one || !defined $other || ref $one || ref $other) ? 0
        : $one eq $other ? 1
        : 0;
}

# How a value is shown in a message: a string is quoted, a number and a JSON
# boolean are shown as the document would write them, and anything else is
# named by its kind rather than dumped.
sub _show {
    my ($value) = @_;

    # A value as the JSON document spells it: a number bare, a string quoted.
    return !defined $value ? 'null'
        : JSON::PP::is_bool($value) ? ($value ? 'true' : 'false')
        : ref $value ? ref $value
        : $value =~ /\A-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?\z/ ? $value
        : "'$value'";
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Schema - check that a document matches a small JSON schema

=head1 SYNOPSIS

Get the list of problems:

    use App::Actions::Schema qw(validate);

    my $schema = {
        type       => 'object',
        required   => ['name'],
        properties => { name => { type => 'string' }, count => { type => 'integer' } },
    };

    my @errors = validate({ name => 'x', count => 'many' }, $schema);
    # ("$.count: expected integer, got 'many'")

Stop at the first problem:

    use App::Actions::Schema qw(assert_valid);

    assert_valid($document, $schema, 'the check --json document does not match its schema');

Show the problems in one line, and exit with the right status:

    use App::Actions::Schema qw(validate describe_errors);

    my @errors = validate($document, $schema);
    if (@errors) {
        print STDERR describe_errors(\@errors), "\n";
        exit App::Actions::Schema::invalid_exit();    # 70
    }

=head1 DESCRIPTION

Some commands print a document for other programs to read, for example
C<action-run check --json>.  Each such document has a I<schema>: a
description of which keys it has and what type each value is.  You can print
the schemas with C<action-run schema>.

This module checks a document against its schema.  The commands use it on
their own output before they print it.  So if a programmer adds, removes or
changes a key and forgets to change the schema, the command fails at once,
and the broken document is never printed.

It understands only a small part of JSON Schema - the keywords the
distribution's own schemas use:

=over 4

=item C<type> - one type name, or a list of them: C<null>, C<boolean>,
C<integer>, C<number>, C<string>, C<array> or C<object>.

=item C<const> - the value must be exactly this.

=item C<enum> - the value must be one of these.

=item C<properties> and C<required> - for an object: the schema of each key,
and the keys that must be there.  B<A key that is not listed in
C<properties> is an error.>

=item C<items> - for an array: the schema every element must match.

=item C<oneOf> - the value must match at least one of these schemas.

=back

Any other keyword is ignored.

=head1 FUNCTIONS

All functions can be imported by name; none is imported by default.

=head2 validate

    my @errors = validate($value, $schema);

Compares a value with a schema and lists every difference.

=head3 ARGUMENTS

=over 4

=item * C<$value> - the document, as Perl data (hashes, arrays, scalars, and
L<JSON::PP> booleans).

=item * C<$schema> - the schema, as a hash reference.

=item * C<$path> - optional.  The name to use for the top of the document in
messages.  Default C<$>.

=back

=head3 RETURNS

A list of messages, one for each problem, in document order.  Each message
starts with the path to the problem, for example C<$.jobs[2].name: missing>.
An empty list means the value matches.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my @errors = validate([1, 'two'], { type => 'array', items => { type => 'integer' } });
    # ("$[1]: expected integer, got 'two'")

=head3 API SPECIFICATION

=head4 INPUT

    {
        value  => { type => 'any', optional => 1 },
        schema => { type => 'hashref' },
        path   => { type => 'string', optional => 1, default => '$' },
    }

=head4 OUTPUT

    { type => 'array', element_type => 'string' }

=head3 MESSAGES

These are returned, not thrown.

    +---------------------------------------------+-------------------------------+------------------------------+
    | Message                                     | Meaning                       | What to do                   |
    +---------------------------------------------+-------------------------------+------------------------------+
    | PATH: expected TYPE, got VALUE              | wrong type                    | fix the value or the schema  |
    | PATH: expected X, got Y                     | const did not match           | fix the value or the schema  |
    | PATH: V is not one of A, B                  | enum did not match            | use one of the listed values |
    | PATH.KEY: unexpected key                    | key not in properties         | add it to the schema, or     |
    |                                             |                               | stop producing it            |
    | PATH.KEY: missing                           | required key absent           | add the key                  |
    | PATH: matches none of the alternative       | no oneOf branch matched; the  | read the first branch's      |
    | shapes (first said: ...)                    | first branch's error is shown | error                        |
    +---------------------------------------------+-------------------------------+------------------------------+

=head2 assert_valid

    assert_valid($value, $schema, $what);

Like L</validate>, but throws an exception if there is any problem.

=head3 ARGUMENTS

=over 4

=item * C<$value> - the document.

=item * C<$schema> - its schema.

=item * C<$what> - the start of the error sentence, for example C<the
action-run check --json document does not match its schema>.

=back

=head3 RETURNS

1 if the value matches.  Otherwise it does not return.

=head3 SIDE EFFECTS

Throws an L<App::Actions::Schema::Invalid> exception if there is a problem.
Its message is C<$what>, a colon, the first problem, the number of other
problems if there are any, and a newline.  It has no file name or line
number, because the problem is in a document, not in the code.

=head3 EXAMPLE

    assert_valid({}, { type => 'object', required => ['a'] }, 'the test document is wrong');
    # dies: "the test document is wrong: $.a: missing\n"

=head3 API SPECIFICATION

=head4 INPUT

    {
        value  => { type => 'any', optional => 1 },
        schema => { type => 'hashref' },
        what   => { type => 'string', min => 1 },
    }

=head4 OUTPUT

    { type => 'integer', memberof => [ 1 ] }

=head3 MESSAGES

    +--------------------------------------------+-------------------------+--------------------------------+
    | Exception                                  | Meaning                 | What to do                     |
    +--------------------------------------------+-------------------------+--------------------------------+
    | App::Actions::Schema::Invalid:             | the document does not   | a bug in this distribution:    |
    | "WHAT: FIRST (and N more)\n"               | match its schema        | report it; exit status 70      |
    +--------------------------------------------+-------------------------+--------------------------------+

=head2 describe_errors

    my $text = describe_errors(\@errors);

Makes one short line from a list of problems.

=head3 ARGUMENTS

=over 4

=item * C<\@errors> - a reference to the list L</validate> returned.

=back

=head3 RETURNS

The first problem, followed by C<(and N more)> if there are others.  The
empty string if the list is empty.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    print describe_errors(['$.a: missing', '$.b: missing', '$.c: missing']);
    # $.a: missing (and 2 more)

=head3 API SPECIFICATION

=head4 INPUT

    { errors => { type => 'arrayref', element_type => 'string' } }

=head4 OUTPUT

    { type => 'string' }

=head3 MESSAGES

None.

=head2 invalid_exit

    exit App::Actions::Schema::invalid_exit();

Returns the exit status a command uses when its own document fails the
check.

=head3 ARGUMENTS

None.

=head3 RETURNS

70.  This is C<EX_SOFTWARE> from F<sysexits.h>, which means "a bug in the
program".  It is not 2, because the commands use 2 for "fix your computer
first", and a CI job should be able to tell the two apart.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    exit invalid_exit() if @errors;

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 70 ] }

=head3 MESSAGES

None.

=head1 EXCEPTIONS

L</assert_valid> throws an L<App::Actions::Schema::Invalid>.  It is an
L<App::Actions::Error> with the code C<schema.invalid> and no location.  See
that module.

=head1 COMMON PITFALLS

=over 4

=item * B<Extra keys are errors.>  Unlike full JSON Schema, an object whose
schema has C<properties> may not have any other key.  There is no
C<additionalProperties> keyword to allow them.

=item * B<undef is C<null>.>  An C<undef> value matches only the type
C<null>.  If a key may be missing or C<undef>, give it the type
C<['string', 'null']>, and leave it out of C<required>.

=item * B<Booleans must be JSON booleans.>  The type C<boolean> matches only
C<JSON::PP::true> and C<JSON::PP::false>, not 1 or 0.  And 1 and 0 match
C<integer>, not C<boolean>.

=item * B<Numbers and strings are compared as text.>  For C<const> and
C<enum>, C<1> and C<'1'> are the same, but C<1.0> and C<1> are not.

=item * B<A string type matches numbers.>  Perl does not separate them, so
C<42> matches C<string>.

=item * B<Unknown keywords are ignored, not reported.>  A misspelt keyword
(C<require> for C<required>) silently checks nothing.

=item * B<In list context, call validate in list context.>  C<my $n =
validate(...)> gives the number of problems, which is what you want for a
test; C<my ($first) = validate(...)> gives the first.

=back

=head1 ENCODING

Strings in the document and the schema can be any Perl character string,
including non-ASCII and emoji.  The check compares characters, so decode
JSON text with L<JSON::PP> (which returns characters) before you check it.
Messages quote the values as they are, so encode them when you print.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  The lines below the rule are always true
when the routine returns.  None of these routines has a state.

    [VALUE, SCHEMA, PATH]
    matches : VALUE × SCHEMA → 𝔹
    problems : VALUE × SCHEMA × PATH → seq MESSAGE

    matches(v, s) ⇔ problems(v, s, "$") = ⟨⟩

=head2 validate

    ┌─ Validate ────────────────────────────────────────
    │ value?  : VALUE
    │ schema? : SCHEMA
    │ path?   : optional PATH
    │ errors! : seq MESSAGE
    ├───────────────────────────────────────────────────
    │ errors! = problems(value?, schema?, if path? = ⊥ then "$" else path?)
    │ oneOf ∈ dom schema? ⇒
    │     (∃ a ∈ ran schema?.oneOf • problems(value?, a, path?) = ⟨⟩)
    │         ⇔ errors! = ⟨⟩
    │ value? ∈ OBJECT ∧ properties ∈ dom schema? ⇒
    │     ∀ k ∈ dom value? \ dom schema?.properties • "path?.k: unexpected key" in errors!
    │     ∀ k ∈ ran schema?.required \ dom value? • "path?.k: missing" in errors!
    │ value? ∈ ARRAY ∧ items ∈ dom schema? ⇒
    │     ∀ i ∈ dom value? • problems(value?(i), schema?.items, path?[i]) ⊆ errors!
    └───────────────────────────────────────────────────

=head2 assert_valid

    ┌─ AssertValid ─────────────────────────────────────
    │ value?  : VALUE
    │ schema? : SCHEMA
    │ what?   : seq CHAR
    │ r!      : ℕ
    ├───────────────────────────────────────────────────
    │ problems(value?, schema?, "$") = ⟨⟩ ⇒ r! = 1
    │ problems(value?, schema?, "$") = e ≠ ⟨⟩ ⇒
    │     raises Invalid(what? ⁀ ": " ⁀ describe(e) ⁀ "\n")
    └───────────────────────────────────────────────────

=head2 describe_errors

    ┌─ DescribeErrors ──────────────────────────────────
    │ errors? : seq MESSAGE
    │ text!   : seq CHAR
    ├───────────────────────────────────────────────────
    │ errors? = ⟨⟩ ⇒ text! = ⟨⟩
    │ #errors? = 1 ⇒ text! = head errors?
    │ #errors? > 1 ⇒ text! = head errors? ⁀ " (and " ⁀ show(#errors? − 1) ⁀ " more)"
    └───────────────────────────────────────────────────

=head2 invalid_exit

    ┌─ InvalidExit ─────────────────────────────────────
    │ status! : ℕ
    ├───────────────────────────────────────────────────
    │ status! = 70
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The module keeps no state between calls.  A document goes through these
steps when a command checks it:

      build document
            |
            v
    +---------------+  validate / assert_valid   +-----------+
    |   UNCHECKED   |--------------------------->| CHECKING  |
    +---------------+                            +-----------+
                                                  |         |
                             no problems          |         | one or more problems
                          (validate: ();          |         | (validate: list of messages;
                           assert_valid: 1)       |         |  assert_valid: throws
                                                  v         v  App::Actions::Schema::Invalid)
                                            +-------+   +---------+
                                            | VALID |   | INVALID |
                                            +-------+   +---------+
                                                |            |
                             command prints it  |            | describe_errors; command
                                                v            v exits with invalid_exit() = 70
                                            printed       not printed

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
