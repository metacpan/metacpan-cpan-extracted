package App::Actions::Expression;

use strict;
use warnings;
use Carp qw(croak);
use JSON::PP ();
use Readonly;
use Scalar::Util qw(looks_like_number);

use App::Actions::Util ();

# The tokenizer matches each token where the previous one ended (\G with
# pos), rather than against substr($text, $pos), which copies the rest of the
# expression for every token and so is quadratic in its length.

# A number literal: 12, 1.5, 1., .5, and any of those with an exponent.
Readonly::Scalar my $NUMBER => qr/
	\G
	(
		(?: \d++ (?: \. \d*+ )?    # 12, 1.5 or 1.
		  | \. \d++               # .5
		)
		(?: [eE] [+-]? \d++ )?     # an exponent
	)
/x;

# An identifier: a letter or underscore, then letters, digits, _ and -.
Readonly::Scalar my $IDENTIFIER => qr/\G([A-Za-z_][A-Za-z0-9_-]*+)/;

our $VERSION = '0.001.0';

sub new {
    my ($class) = @_;

    return bless {
        json    => JSON::PP->new->canonical,
        context => {},
        status  => {},
    }, $class;
}

# Evaluate a single GitHub Actions expression, e.g. "matrix.perl == '5.38'".
sub evaluate {
    my ($self, $expression, $context, $status) = @_;

    croak 'Cannot evaluate an undefined expression' unless defined $expression;
    my $text = "$expression";
    croak 'Cannot evaluate an empty expression' if $text =~ /^\s*$/;

    $self->{context} = $context || {};
    $self->{status}  = $status  || {};
    $self->{tokens}  = $self->_tokenize($text);
    $self->{pos}     = 0;
    # Whether a lookup found nothing, which strict interpolation turns into an
    # error.  An existing value that happens to be empty is not a miss.
    $self->{unresolved} = 0;

    my $value = $self->_parse_expression;
    my $token = $self->_peek;
    croak "Unexpected '$token->{value}' in expression '$text'" if $token->{type} ne 'eof';

    return $value;
}

# Replace every ${{ ... }} in a string.
sub interpolate {
    my ($self, $text, $context, $status) = @_;

    return $text unless defined $text;
    return $text if ref $text;

    my $out   = "$text";
    my $start = 0;

    while (1) {
        my $open = index($out, '${{', $start);
        last if $open < 0;

        my $close = index($out, '}}', $open + 3);
        croak "Unclosed expression in '$text'" if $close < 0;

        my $expression = substr($out, $open + 3, $close - $open - 3);
        my $value      = $self->evaluate($expression, $context, $status);

        if ($self->{strict} && $self->{unresolved}) {
            my $written = App::Actions::Util::trim($expression);
            croak "unable to resolve '\${{ $written }}' from the values available";
        }

        my $replacement = _stringify($value);

        substr($out, $open, $close + 2 - $open, $replacement);
        $start = $open + length($replacement);
    }

    return $out;
}

# Replace every ${{ ... }}, but treat a value that could not be found as an
# error rather than as an empty string.  This is for callers where an empty
# result would be a wrong value rather than a legitimate one, such as an
# image name assembled from values that do not exist yet.
sub interpolate_strict {
    my ($self, $text, $context, $status) = @_;

    local $self->{strict} = 1;

    return $self->interpolate($text, $context, $status);
}

# Replace the ${{ ... }} this context can resolve and leave the others as they
# were written.  A caller that knows some of the values now and the rest later
# can resolve twice, without having to guess whether an empty string means
# "empty" or "not known here".
sub interpolate_known {
    my ($self, $text, $context, $status) = @_;

    return $text unless defined $text;
    return $text if ref $text;

    my $out   = "$text";
    my $start = 0;

    while (1) {
        my $open = index($out, '${{', $start);
        last if $open < 0;

        my $close = index($out, '}}', $open + 3);
        croak "Unclosed expression in '$text'" if $close < 0;

        my $expression = substr($out, $open + 3, $close - $open - 3);
        my $value      = $self->evaluate($expression, $context, $status);

        if ($self->{unresolved}) {
            # Step over the expression, which stays in the text.
            $start = $close + 2;
            next;
        }

        my $replacement = _stringify($value);

        substr($out, $open, $close + 2 - $open, $replacement);
        $start = $open + length($replacement);
    }

    return $out;
}

# Evaluate an "if:" value.
sub condition {
    my ($self, $condition, $context, $status) = @_;

    return 1 unless defined $condition;
    return $condition ? 1 : 0 if ref $condition;

    my $text = "$condition";
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return 1 if $text eq '';

    if ($text =~ /^\$\{\{(.*)\}\}$/s) {
        $text = $1;
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
    }

    return _truthy($self->evaluate($text, $context, $status));
}

sub _tokenize {
    my (undef, $text) = @_;

    my @tokens;
    my $length = length($text);
    my $pos = 0;

    while ($pos < $length) {
        my $char = substr($text, $pos, 1);

        if ($char =~ /\s/) {
            $pos++;
            next;
        }

        if ($char eq q{'}) {
            my $value = '';
            $pos++;
            my $closed = 0;
            while ($pos < $length) {
                my $c = substr($text, $pos, 1);
                if ($c eq q{'}) {
                    if (substr($text, $pos + 1, 1) eq q{'}) {
                        $value .= q{'};
                        $pos += 2;
                        next;
                    }
                    $pos++;
                    $closed = 1;
                    last;
                }
                $value .= $c;
                $pos++;
            }
            croak "Unterminated string in expression '$text'" unless $closed;
            push @tokens, { type => 'str', value => $value };
            next;
        }

        pos($text) = $pos;
        if ($text =~ /$NUMBER/gc) {
            my $number = $1;
            push @tokens, { type => 'num', value => $number + 0 };
            $pos += length($number);
            next;
        }

        pos($text) = $pos;
        if ($text =~ /$IDENTIFIER/gc) {
            my $identifier = $1;
            push @tokens, { type => 'ident', value => $identifier };
            $pos += length($identifier);
            next;
        }

        my $two = substr($text, $pos, 2);
        if ($two eq '==' || $two eq '!=' || $two eq '<=' || $two eq '>='
            || $two eq '&&' || $two eq '||') {
            push @tokens, { type => 'op', value => $two };
            $pos += 2;
            next;
        }

        if ($char eq '!' || $char eq '<' || $char eq '>') {
            push @tokens, { type => 'op', value => $char };
            $pos++;
            next;
        }

        if ($char eq '(' || $char eq ')' || $char eq '[' || $char eq ']'
            || $char eq '.' || $char eq ',') {
            push @tokens, { type => 'punct', value => $char };
            $pos++;
            next;
        }

        croak "Unexpected character '$char' in expression '$text'";
    }

    push @tokens, { type => 'eof', value => '' };

    return \@tokens;
}

sub _peek {
    my ($self) = @_;
    return $self->{tokens}[ $self->{pos} ];
}

sub _next {
    my ($self) = @_;
    my $token = $self->{tokens}[ $self->{pos} ];
    $self->{pos}++ if $token->{type} ne 'eof';
    return $token;
}

sub _peek_value {
    my ($self) = @_;
    return $self->_peek->{value};
}

sub _expect {
    my ($self, $value) = @_;
    my $token = $self->_next;
    croak "Expected '$value' in expression" unless $token->{value} eq $value;
    return $token;
}

sub _parse_expression {
    my ($self) = @_;
    return $self->_parse_or;
}

sub _parse_or {
    my ($self) = @_;

    my $left = $self->_parse_and;
    while ($self->_peek_value eq '||') {
        $self->_next;
        my $right = $self->_parse_and;
        $left = _truthy($left) ? $left : $right;
    }

    return $left;
}

sub _parse_and {
    my ($self) = @_;

    my $left = $self->_parse_equality;
    while ($self->_peek_value eq '&&') {
        $self->_next;
        my $right = $self->_parse_equality;
        $left = _truthy($left) ? $right : $left;
    }

    return $left;
}

sub _parse_equality {
    my ($self) = @_;

    my $left = $self->_parse_relational;
    while (my $operator = $self->_peek_value) {
        last unless $operator eq '==' || $operator eq '!=';
        $self->_next;
        my $right = $self->_parse_relational;
        my $equal = _equal($left, $right);
        $left = $operator eq '==' ? $equal : !$equal;
    }

    return $left;
}

sub _parse_relational {
    my ($self) = @_;

    my $left = $self->_parse_unary;
    while (my $operator = $self->_peek_value) {
        last unless $operator eq '<' || $operator eq '<=' || $operator eq '>'
            || $operator eq '>=';
        $self->_next;
        my $right = $self->_parse_unary;
        my $comparison = _compare($left, $right);
        $left = $operator eq '<'  ? $comparison < 0
              : $operator eq '<=' ? $comparison <= 0
              : $operator eq '>'  ? $comparison > 0
              :                     $comparison >= 0;
    }

    return $left;
}

sub _parse_unary {
    my ($self) = @_;

    # "!" binds tighter than any operator, and may be repeated.
    my $negated = $self->_peek_value eq '!';
    $self->_next if $negated;

    return $negated ? (_truthy($self->_parse_unary) ? 0 : 1) : $self->_parse_primary;
}

sub _parse_primary {
    my ($self) = @_;

    my $token = $self->_peek;

    if ($token->{type} eq 'eof') {
        croak 'Unexpected end of expression';
    }

    if ($token->{type} eq 'num') {
        $self->_next;
        return $self->_postfix($token->{value});
    }

    if ($token->{type} eq 'str') {
        $self->_next;
        return $self->_postfix($token->{value});
    }

    if ($token->{value} eq '(') {
        $self->_next;
        my $value = $self->_parse_expression;
        $self->_expect(')');
        return $self->_postfix($value);
    }

    if ($token->{type} eq 'ident') {
        my $name = $token->{value};
        $self->_next;

        my $lower = lc $name;
        if ($lower eq 'true') {
            return $self->_postfix(1);
        }
        if ($lower eq 'false') {
            return $self->_postfix(0);
        }
        if ($lower eq 'null') {
            return $self->_postfix(undef);
        }

        if ($self->_peek_value eq '(') {
            $self->_next;
            my @args;
            if ($self->_peek_value ne ')') {
                push @args, $self->_parse_expression;
                while ($self->_peek_value eq ',') {
                    $self->_next;
                    push @args, $self->_parse_expression;
                }
            }
            $self->_expect(')');
            return $self->_postfix($self->_call_function($name, \@args));
        }

        return $self->_postfix($self->_lookup($self->{context}, $name));
    }

    croak "Unexpected '$token->{value}' in expression";
}

sub _postfix {
    my ($self, $value) = @_;

    while (1) {
        if ($self->_peek_value eq '.') {
            $self->_next;
            my $key = $self->_next;
            croak 'Expected a property name after dot' unless $key->{type} eq 'ident';
            $value = $self->_lookup($value, $key->{value});
            next;
        }

        if ($self->_peek_value eq '[') {
            $self->_next;
            my $index = $self->_parse_expression;
            $self->_expect(']');
            $value = $self->_lookup($value, $index);
            next;
        }

        last;
    }

    return $value;
}

sub _lookup {
    my ($self, $object, $key) = @_;

    return $self->_missing unless defined $object && defined $key;
    return $self->_missing if ref $key;

    if (ref $object eq 'HASH') {
        return $object->{$key} if exists $object->{$key};
        my $lower = lc $key;
        for my $name (keys %$object) {
            return $object->{$name} if lc $name eq $lower;
        }
        return $self->_missing;
    }

    if (ref $object eq 'ARRAY') {
        return $self->_missing unless $key =~ /\A-?\d+\z/;
        return $object->[$key];
    }

    return $self->_missing;
}

# A lookup found nothing.  The value is still undef, as before; strict
# interpolation is the only caller that cares.
sub _missing {
    my ($self) = @_;

    $self->{unresolved} = 1;

    return undef;
}

sub _call_function {
    my ($self, $name, $args) = @_;

    my $function = lc $name;

    return $self->{status}{success} ? 1 : 0   if $function eq 'success';
    return $self->{status}{failure} ? 1 : 0   if $function eq 'failure';
    return 1                                  if $function eq 'always';
    return $self->{status}{cancelled} ? 1 : 0 if $function eq 'cancelled';

    if ($function eq 'contains') {
        croak 'contains() expects two arguments' unless @$args == 2;
        my ($search, $item) = @$args;
        if (ref $search eq 'ARRAY') {
            for my $candidate (@$search) {
                return 1 if _equal($candidate, $item);
            }
            return 0;
        }
        return index(lc(_stringify($search)), lc(_stringify($item))) >= 0 ? 1 : 0;
    }

    if ($function eq 'startswith' || $function eq 'endswith') {
        croak "$name() expects two arguments" unless @$args == 2;
        my ($haystack, $needle) = map { lc _stringify($_) } @$args;
        return $function eq 'startswith'
            ? (index($haystack, $needle) == 0 ? 1 : 0)
            : (length($needle) <= length($haystack)
                && substr($haystack, -length($needle)) eq $needle ? 1 : 0);
    }

    if ($function eq 'format') {
        croak 'format() expects at least one argument' unless @$args;
        my $format = _stringify(shift @$args);
        $format =~ s/\{\{/\x00/g;
        $format =~ s/\}\}/\x01/g;
        $format =~ s/\{(\d+)\}/defined $args->[$1] ? _stringify($args->[$1]) : ''/ge;
        $format =~ s/\x00/{/g;
        $format =~ s/\x01/}/g;
        return $format;
    }

    if ($function eq 'join') {
        croak 'join() expects two arguments' unless @$args == 2;
        my ($array, $separator) = @$args;
        croak 'join() first argument must be an array' unless ref $array eq 'ARRAY';
        return join(_stringify($separator), map { _stringify($_) } @$array);
    }

    if ($function eq 'tojson') {
        croak 'toJSON() expects one argument' unless @$args == 1;
        return $self->{json}->encode($args->[0]);
    }

    if ($function eq 'fromjson') {
        croak 'fromJSON() expects one argument' unless @$args == 1;
        my $value = eval { $self->{json}->decode(_stringify($args->[0])) };
        croak "fromJSON() failed: $@" if $@;
        return $value;
    }

    if ($function eq 'hashfiles') {
        croak 'hashFiles() is not supported by local action-run';
    }

    croak "Unknown function '$name()' in expression";
}

sub _truthy {
    my ($value) = @_;

    return 0 unless defined $value;
    # A boolean (JSON::PP's, or a core one from YAML::PP) is its own truth;
    # a JSON::PP false is a reference, so this must come before the ref test.
    return $value ? 1 : 0 if JSON::PP::is_bool($value);
    return 1 if ref $value;
    return 0 if $value eq '';
    return 0 if $value eq '0';
    return 1;
}

sub _equal {
    my ($left, $right) = @_;

    return _compare($left, $right) == 0 ? 1 : 0;
}

sub _compare {
    my ($left, $right) = @_;

    # Numbers compare as numbers; anything else as text, ignoring case.
    return (_is_number($left) && _is_number($right))
        ? $left <=> $right
        : lc(_stringify($left)) cmp lc(_stringify($right));
}

sub _is_number {
    my ($value) = @_;
    # GitHub compares a boolean with a number as 1 or 0, which is what lets
    # "matrix.debug == false" match a matrix value of false.
    return !defined $value ? 0
        : JSON::PP::is_bool($value) ? 1
        : (ref $value || $value eq '') ? 0
        : looks_like_number($value) ? 1
        : 0;
}

# The string a workflow sees for a value: one definition for the whole
# distribution, so a boolean interpolates as true/false here exactly as it is
# shown in a job's display name.
sub _stringify {
    return App::Actions::Util::stringify($_[0]);
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Expression - work out the value of a GitHub Actions C<${{ }}> expression

=head1 SYNOPSIS

Work out one expression:

    use App::Actions::Expression;

    my $expression = App::Actions::Expression->new;
    my $context = { matrix => { perl => '5.40', os => 'ubuntu-latest' } };

    my $value = $expression->evaluate(q{matrix.perl == '5.40'}, $context);    # 1

Fill in the expressions in a text:

    my $name = $expression->interpolate('Test on Perl ${{ matrix.perl }}', $context);
    # "Test on Perl 5.40"

Decide whether a step runs (an C<if:> value):

    my $runs = $expression->condition(
        q{${{ failure() && startsWith(matrix.os, 'ubuntu') }}},
        $context,
        { success => 0, failure => 1, cancelled => 0 },
    );

Refuse a value that does not exist yet:

    my $image = eval { $expression->interpolate_strict('perl:${{ matrix.perl }}', {}) };
    # dies: unable to resolve '${{ matrix.perl }}' from the values available

Fill in only what is known now, and the rest later:

    my $half = $expression->interpolate_known('${{ env.A }}-${{ steps.x.outputs.y }}',
        { env => { A => 'a' } });
    # "a-${{ steps.x.outputs.y }}"

=head1 DESCRIPTION

GitHub Actions workflows contain I<expressions>: small formulas written as
C<${{ ... }}>, for example C<${{ matrix.perl }}> or C<${{ github.ref ==
'refs/heads/main' }}>.  This module works out their values, so that
workflows can run on your own computer.

It supports the part of the language that matters when you run a workflow
locally:

=over 4

=item * B<Values:> strings in single quotes (write two quotes for one quote
inside: C<'it''s'>), numbers (C<42>, C<1.5>, C<1e3>), and C<true>,
C<false> and C<null>.

=item * B<Looking up values:> C<matrix.perl>, C<env['HOME']>,
C<steps.build.outputs.path>, C<list[0]>.  Names are matched without regard
to upper and lower case, as on GitHub.  A name that does not exist gives
C<null>; it is not an error (but see L</interpolate_strict>).

=item * B<Operators,> from loosest to tightest: C<||>, C<&&>, C<==> and
C<!=>, C<E<lt>> C<E<lt>=> C<E<gt>> C<E<gt>=>, C<!>, and brackets C<( )>.
C<||> and C<&&> return one of their operands, as on GitHub: C<a || 'x'> is
C<a> if it is true, otherwise C<'x'>.

=item * B<Comparisons:> two numbers are compared as numbers.  Anything else
is compared as text, without regard to case, so C<'ABC' == 'abc'> is true.
C<true> and C<false> count as 1 and 0 when compared with a number.

=item * B<Functions:> C<contains>, C<startsWith>, C<endsWith>, C<format>,
C<join>, C<toJSON>, C<fromJSON>, and the status functions C<success>,
C<failure>, C<cancelled> and C<always>.  Function names are not case
sensitive.

=back

I<Truth:> C<null>, C<false>, the empty string, C<0> and C<'0'> are false.
Everything else is true, including every array and object, even empty ones.

=head1 METHODS

=head2 new

    my $expression = App::Actions::Expression->new;

Makes an evaluator.  One evaluator can be used for any number of
expressions, but not by two threads at once.

=head3 ARGUMENTS

None.

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

None.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'object', isa => 'App::Actions::Expression' }

=head3 MESSAGES

None.

=head2 evaluate

    my $value = $expression->evaluate($text, \%context, \%status);

Works out the value of one expression.  The text is the part inside
C<${{ }}>, without the braces.

=head3 ARGUMENTS

=over 4

=item * C<$text> - the expression, for example C<matrix.perl == '5.40'>.

=item * C<\%context> - optional.  The values names look up: a hash
reference such as C<{ matrix =E<gt> {...}, env =E<gt> {...}, github =E<gt>
{...} }>.

=item * C<\%status> - optional.  The answers for the status functions:
C<{ success =E<gt> 1, failure =E<gt> 0, cancelled =E<gt> 0 }>.  Missing keys
are false.  C<always()> is always true.

=back

=head3 RETURNS

The value: a string, a number, 1 or 0 for a comparison, a reference for an
array or object, or C<undef> for C<null> or a missing name.

=head3 SIDE EFFECTS

Remembers whether a name was missing, for L</interpolate_strict> and
L</interpolate_known>.

=head3 EXAMPLE

    my $list = $expression->evaluate(q{fromJSON('[1, 2, 3]')});            # [1, 2, 3]
    my $has  = $expression->evaluate(q{contains(matrix.os, 'ubuntu')},
        { matrix => { os => 'Ubuntu-24.04' } });                          # 1

=head3 API SPECIFICATION

=head4 INPUT

    {
        expression => { type => 'string', min => 1 },
        context    => { type => 'hashref', optional => 1 },
        status     => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'any', optional => 1 }

=head3 MESSAGES

All are thrown with C<croak>.  Fix the expression in the workflow.

    +----------------------------------------------+------------------------------------------+
    | Message                                      | Meaning                                  |
    +----------------------------------------------+------------------------------------------+
    | Cannot evaluate an undefined expression      | $text was undef                          |
    | Cannot evaluate an empty expression          | $text was empty or only spaces           |
    | Unterminated string in expression 'T'        | a ' has no closing '                     |
    | Unexpected character 'C' in expression 'T'   | C is not part of the language (e.g. + *) |
    | Unexpected 'X' in expression ['T']           | X is in the wrong place, or extra text   |
    |                                              | follows a complete expression            |
    | Unexpected end of expression                 | the expression stops too early           |
    | Expected 'X' in expression                   | a ) or ] is missing                      |
    | Expected a property name after dot           | "a." with no name, or "a.1"              |
    | F() expects N argument(s)                    | wrong number of arguments to function F  |
    | join() first argument must be an array       | join('a', ',') - use an array            |
    | fromJSON() failed: ERR                       | the text is not valid JSON               |
    | hashFiles() is not supported by local        | this function is not implemented         |
    | action-run                                   |                                          |
    | Unknown function 'F()' in expression         | F is not one of the functions above      |
    +----------------------------------------------+------------------------------------------+

=head2 interpolate

    my $result = $expression->interpolate($text, \%context, \%status);

Replaces every C<${{ ... }}> in a text with its value.

=head3 ARGUMENTS

=over 4

=item * C<$text> - the text.  C<undef> and references are returned
unchanged.

=item * C<\%context>, C<\%status> - as for L</evaluate>.

=back

=head3 RETURNS

The new text.  Values are written as GitHub writes them: C<null> and missing
names as the empty string, an array or object as JSON.  Text that comes from
a value is not searched again for C<${{>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    print $expression->interpolate('${{ format(\'{0}-{1}\', 1, 2) }}');    # 1-2

=head3 API SPECIFICATION

=head4 INPUT

    {
        text    => { type => 'string', optional => 1 },
        context => { type => 'hashref', optional => 1 },
        status  => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string', optional => 1 }

=head3 MESSAGES

    +--------------------------------+---------------------------------+----------------------+
    | Message (croak)                | Meaning                         | What to do           |
    +--------------------------------+---------------------------------+----------------------+
    | Unclosed expression in 'T'     | a ${{ has no }} after it        | add the }}           |
    | (any message of evaluate)      | an expression inside is invalid | fix that expression  |
    +--------------------------------+---------------------------------+----------------------+

=head2 interpolate_strict

    my $result = $expression->interpolate_strict($text, \%context, \%status);

Like L</interpolate>, but a name that does not exist is an error instead of
an empty string.  Use it when an empty value would be wrong, for example in
an image name.

=head3 ARGUMENTS

As for L</interpolate>.

=head3 RETURNS

As for L</interpolate>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    $expression->interpolate_strict('node:${{ matrix.node }}', { matrix => { node => 20 } });    # node:20

=head3 API SPECIFICATION

=head4 INPUT

    {
        text    => { type => 'string', optional => 1 },
        context => { type => 'hashref', optional => 1 },
        status  => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string', optional => 1 }

=head3 MESSAGES

As for L</interpolate>, and:

    +------------------------------------------------+-------------------------+--------------------------+
    | Message (croak)                                | Meaning                 | What to do               |
    +------------------------------------------------+-------------------------+--------------------------+
    | unable to resolve '${{ E }}' from the values   | E names something that  | give that value, or      |
    | available                                      | does not exist          | correct the name         |
    +------------------------------------------------+-------------------------+--------------------------+

A name that exists but whose value is empty is not an error.

=head2 interpolate_known

    my $result = $expression->interpolate_known($text, \%context, \%status);

Like L</interpolate>, but an expression that names something missing is
left in the text, exactly as written.  Use it when you know some values now
and the others later: call it again later with the full context.

=head3 ARGUMENTS

As for L</interpolate>.

=head3 RETURNS

The text with the known expressions replaced.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    $expression->interpolate_known('${{ a }}/${{ b }}', { a => 1 });    # 1/${{ b }}

=head3 API SPECIFICATION

=head4 INPUT

    {
        text    => { type => 'string', optional => 1 },
        context => { type => 'hashref', optional => 1 },
        status  => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string', optional => 1 }

=head3 MESSAGES

As for L</interpolate>.

=head2 condition

    my $runs = $expression->condition($if, \%context, \%status);

Works out a workflow's C<if:> value: should this job or step run?

=head3 ARGUMENTS

=over 4

=item * C<$if> - the C<if:> value.  It may be written with or without
C<${{ }}> around it.  C<undef> or empty means "no condition".  A YAML
boolean (C<if: false>) is used as it is.

=item * C<\%context>, C<\%status> - as for L</evaluate>.

=back

=head3 RETURNS

1 to run, 0 not to run.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    $expression->condition("github.event_name == 'push'", { github => { event_name => 'push' } });    # 1
    $expression->condition(undef);                                                              # 1

=head3 API SPECIFICATION

=head4 INPUT

    {
        condition => { type => 'string', optional => 1 },
        context   => { type => 'hashref', optional => 1 },
        status    => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

As for L</evaluate>.

=head1 COMMON PITFALLS

=over 4

=item * B<Strings use single quotes.>  C<"main"> is not a string; write
C<'main'>.  Inside a string, write C<''> for one quote.

=item * B<A missing name is not an error.>  C<matrix.pearl> (a typing
mistake) quietly gives C<null>.  Use L</interpolate_strict> where that
matters.

=item * B<Text comparison ignores case.>  C<'Main' == 'main'> is true, and
so are C<contains>, C<startsWith> and C<endsWith> with different case.

=item * B<C<'1.0' == 1> is true, C<'1.0' == '1'> is also true.>  Values that
look like numbers are compared as numbers.

=item * B<C<||> and C<&&> do not always return true or false.>  They return
an operand, so C<${{ a || 'default' }}> is a common way to give a default.

=item * B<Booleans in text are not always C<true>/C<false>.>  In this
version, C<${{ true }}> and C<${{ 1 == 1 }}> are written as C<1>, and
C<${{ 1 == 2 }}> as C<0>, but C<${{ 1 != 1 }}> as C<false>.  GitHub writes
C<true> or C<false> for all of them.  Use comparisons in C<if:>, where they
work the same, rather than in text.

=item * B<An empty array is true.>  C<if: ${{ fromJSON('[]') }}> runs.

=item * B<No arithmetic.>  C<+>, C<->, C<*> and C</> are not part of the
language; they are errors.

=item * B<Status functions need the status hash.>  Without it,
C<success()> is false, so C<if: success()> does not run.

=item * B<The context is not copied.>  Values from it, such as arrays, are
returned as the same references.  Do not change them.

=back

=head1 ENCODING

Expressions, contexts and results are Perl character strings.  String
literals and values may contain any Unicode text, including non-ASCII and
emoji, as long as the workflow was decoded as UTF-8 (L<App::Actions::Util>
does this).  Names (C<matrix.perl>) must be ASCII letters, digits, C<_> and
C<->.  Case-insensitive comparison uses Perl's C<lc>, which handles
non-ASCII letters too.

=head1 LIMITATIONS

=over 4

=item * C<hashFiles()> is not supported.

=item * The object filter C<*> (as in C<github.event.*.name>) is not
supported.

=item * Booleans made by an expression are not written as C<true>/C<false>
in text; see L</COMMON PITFALLS>.

=item * Arithmetic is not part of the GitHub Actions expression language and
is not implemented.

=back

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞEvaluator> means the routine leaves
the evaluator's visible state alone.  The lines below the rule are always
true when the routine returns.

    [VALUE, TEXT]
    CONTEXT == NAME ⇸ VALUE
    STATUS == {success, failure, cancelled} ⇸ 𝔹
    value : TEXT × CONTEXT × STATUS ⇸ VALUE       the language's meaning
    missing : TEXT × CONTEXT → 𝔹                  some lookup found nothing
    truthy : VALUE → 𝔹
    truthy(v) ⇔ v ∉ {⊥, false, ⟨⟩, 0, "0"}
    show : VALUE → TEXT                           as App::Actions::Util::stringify

    ┌─ Evaluator ───────────────────────────────────────
    │ unresolved : 𝔹
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Evaluator'
    ├───────────────────────────────────────────────────
    │ unresolved' = false
    └───────────────────────────────────────────────────

=head2 evaluate

    ┌─ Evaluate ────────────────────────────────────────
    │ ΔEvaluator
    │ text?    : TEXT
    │ context? : CONTEXT
    │ status?  : STATUS
    │ v!       : VALUE
    ├───────────────────────────────────────────────────
    │ text? = ⊥ ⇒ raises Undefined
    │ text? is only white space ⇒ raises Empty
    │ text? ∉ dom value ⇒ raises Syntax
    │ otherwise v! = value(text?, context?, status?)
    │     ∧ unresolved' = missing(text?, context?)
    └───────────────────────────────────────────────────

=head2 interpolate

    ┌─ Interpolate ─────────────────────────────────────
    │ ΞEvaluator
    │ text?  : optional TEXT
    │ r!     : optional TEXT
    ├───────────────────────────────────────────────────
    │ text? = ⊥ ∨ text? ∈ REF ⇒ r! = text?
    │ text? = p₀ ⁀ "${{" ⁀ e₁ ⁀ "}}" ⁀ p₁ ⁀ … ⁀ "${{" ⁀ eₙ ⁀ "}}" ⁀ pₙ
    │     where no pᵢ contains "${{" and no eᵢ contains "}}"
    │     ⇒ r! = p₀ ⁀ show(value(e₁)) ⁀ p₁ ⁀ … ⁀ show(value(eₙ)) ⁀ pₙ
    │ "${{" in pₙ with no "}}" after it ⇒ raises Unclosed
    └───────────────────────────────────────────────────

=head2 interpolate_strict

    ┌─ InterpolateStrict ───────────────────────────────
    │ Interpolate
    ├───────────────────────────────────────────────────
    │ ∃ i • missing(eᵢ, context?) ⇒ raises Unresolved(eᵢ)
    └───────────────────────────────────────────────────

=head2 interpolate_known

    ┌─ InterpolateKnown ────────────────────────────────
    │ Interpolate
    ├───────────────────────────────────────────────────
    │ r! = p₀ ⁀ k₁ ⁀ p₁ ⁀ … ⁀ kₙ ⁀ pₙ where
    │     kᵢ = "${{" ⁀ eᵢ ⁀ "}}"   if missing(eᵢ, context?)
    │     kᵢ = show(value(eᵢ))     otherwise
    └───────────────────────────────────────────────────

=head2 condition

    ┌─ Condition ───────────────────────────────────────
    │ ΞEvaluator
    │ if?     : optional (TEXT ∪ BOOLEAN)
    │ r!      : {0, 1}
    ├───────────────────────────────────────────────────
    │ if? = ⊥ ∨ trim(if?) = ⟨⟩ ⇒ r! = 1
    │ if? ∈ BOOLEAN ⇒ r! = (if if? then 1 else 0)
    │ trim(if?) = "${{" ⁀ e ⁀ "}}" ⇒ r! = truthy(value(trim(e))) as 0/1
    │ otherwise r! = truthy(value(trim(if?))) as 0/1
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The evaluator has one piece of state: whether the last lookup found
nothing.  Each call to L</evaluate> goes through these steps:

                         evaluate($text, $context, $status)
                                     |
                                     v
                           +-------------------+   undef / empty
                           |  CHECK INPUT      |------------------> croak
                           +-------------------+
                                     |  unresolved := false
                                     v
                           +-------------------+   bad character,
                           |  TOKENIZE         |   open string
                           |  (one pass, \G)   |------------------> croak
                           +-------------------+
                                     |
                                     v
                           +-------------------+   unexpected token,
                           |  PARSE + COMPUTE  |   bad function call
                           |  || && == < ! ()  |------------------> croak
                           +-------------------+
                              |            |
               lookup found   |            | lookup found nothing
               a value        |            v
                              |   +-------------------+
                              |   | unresolved := true|
                              |   | value := undef    |
                              |   +-------------------+
                              |            |
                              v            v
                           +-------------------+
                           |  DONE: value      |
                           +-------------------+
                              |
         interpolate ---------+--> insert show(value) into the text
         interpolate_strict --+--> unresolved ? croak : insert
         interpolate_known ---+--> unresolved ? keep "${{ ... }}" : insert
         condition -----------+--> truthy(value) ? 1 : 0

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
