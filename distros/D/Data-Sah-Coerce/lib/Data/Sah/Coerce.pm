package Data::Sah::Coerce;

our $DATE = '2020-01-03'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.046'; # VERSION

use 5.010001;
use strict;
use warnings;
no warnings 'once';
use Log::ger;

use Data::Sah::CoerceCommon;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate coercer code',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
<pm:Data::Sah>.

_
    args => {
        %Data::Sah::CoerceCommon::gen_coercer_args,
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $rt = $args{return_type} // 'val';

    my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
        %args,
        compiler=>'perl',
        data_term=>'$data',
    );

    my $code;
    if (@$rules) {
        my $code_require = '';
        my %mem;
        for my $rule (@$rules) {
            next unless $rule->{modules};
            for my $mod (keys %{$rule->{modules}}) {
                next if $mem{$mod}++;
                $code_require .= "require $mod;\n";
            }
        }

        my $expr;
        for my $i (reverse 0..$#{$rules}) {
            my $rule = $rules->[$i];
            my $prev_term;
            if ($i == $#{$rules}) {
                if ($rt eq 'val') {
                    $prev_term = '$data';
                } elsif ($rt eq 'status+val') {
                    $prev_term = '[undef, $data]';
                } else { # status+err+val
                    $prev_term = '[undef, undef, $data]';
                }
            } else {
                $prev_term = $expr;
            }

            if ($rt eq 'val') {
                if ($rule->{meta}{might_fail}) {
                    $expr = "do { if ($rule->{expr_match}) { my \$res = $rule->{expr_coerce}; \$res->[0] ? undef : \$res->[1] } else { $prev_term } }";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : $prev_term";
                }
            } elsif ($rt eq 'status+val') {
                if ($rule->{meta}{might_fail}) {
                    $expr = "do { if ($rule->{expr_match}) { my \$res = $rule->{expr_coerce}; \$res->[0] ? [1,undef] : [1,\$res->[1]] } else { $prev_term } }";
                } else {
                    $expr = "($rule->{expr_match}) ? [1, $rule->{expr_coerce}] : $prev_term";
                }
            } else { # status+err+val
                if ($rule->{meta}{might_fail}) {
                    $expr = "do { if ($rule->{expr_match}) { my \$res = $rule->{expr_coerce}; \$res->[0] ? [1, \$res->[0], undef] : [1, undef, \$res->[1]] } else { $prev_term } }";
                } else {
                    $expr = "($rule->{expr_match}) ? [1, undef, $rule->{expr_coerce}] : $prev_term";
                }
            }
        }

        $code = join(
            "",
            $code_require,
            "sub {\n",
            "    my \$data = shift;\n",
            "    unless (defined \$data) {\n",
            "        ", ($rt eq 'val' ? "return undef;" :
                             $rt eq 'status+val' ? "return [undef, undef];" :
                             "return [undef, undef, undef];" # status+err+val
                         ), "\n",
            "    }\n",
            "    $expr;\n",
            "}",
        );
    } else {
        if ($rt eq 'val') {
            $code = 'sub { $_[0] }';
        } elsif ($rt eq 'status+val') {
            $code = 'sub { [undef, $_[0]] }';
        } else {
            $code = 'sub { [undef, undef, $_[0]] }';
        }
    }

    if ($Log_Coercer_Code) {
        log_trace("Coercer code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    my $coercer = eval $code;
    die if $@;
    $coercer;
}

1;
# ABSTRACT: Coercion rules for Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce - Coercion rules for Data::Sah

=head1 VERSION

This document describes version 0.046 of Data::Sah::Coerce (from Perl distribution Data-Sah-Coerce), released on 2020-01-03.

=head1 SYNOPSIS

 use Data::Sah::Coerce qw(gen_coercer);

 # a utility routine: gen_coercer
 my $c = gen_coercer(
     type               => 'date',
     coerce_to          => 'DateTime',
     coerce_rules       => ['From_str::natural'],  # explicitly enable a rule, etc
     # return_type      => 'str+val',              # default is 'val'
 );

 my $val = $c->(123);          # unchanged, 123
 my $val = $c->(1463307881);   # becomes a DateTime object
 my $val = $c->("2016-05-15"); # becomes a DateTime object
 my $val = $c->("2016foo");    # unchanged, "2016foo"

=head1 DESCRIPTION

This distribution contains a standard set of coercion rules for L<Data::Sah>. It
is separated from the C<Data-Sah> distribution and can be used independently.

A coercion rule is put in
C<Data::Sah::Coerce::$COMPILER::To_$TARGET_TYPE::From_$SOURCE_TYPE::DESCRIPTION>
module, for example: L<Data::Sah::Coerce::perl::To_date::From_float::epoch> for
converting date from integer (Unix epoch) or
L<Data::Sah::Coerce::perl::To_date::From_str::iso8601> for converting date from
ISO8601 strings like "2016-05-15".

Basically, a coercion rule will provide an expression (C<expr_match>) that
evaluates to true when data can be coerced, and an expression (C<expr_coerce>)
to actually coerce/convert data to the target type. This rule can be combined
with other rules to form the final coercion code.

The module must contain C<meta> subroutine which must return a hashref that has
the following keys (C<*> marks that the key is required):

=over

=item * v* => int (default: 1)

Metadata specification version. From L<DefHash>. Currently at 4.

History: bumped from 3 to 4 to remove C<enable_by_default> property. Now the
list of standard (enabled-by-default) coercion rules is maintained in
Data::Sah::Coerce itself. This allows us to skip scanning all
Data::Sah::Coerce::* coercion modules installed on the system. Data::Sah::Coerce
still accepts version 3; it just ignores the C<enable_by_default> property.

History: bumped from 2 to 3 to allow coercion expression to return error message
explaining why coercion fails. The C<might_die> metadata property is replaced
with C<might_fail>. When C<might_fail> is set to true, C<expr_coerce> must
return array containing error message and coerced data, instead of just coerced
data.

History: Bumped from 1 to 2 to exclude old module names.

=item * summary => str

From L<DefHash>.

=item * might_fail => bool (default: 0)

Whether coercion might fail, e.g. because of invalid input. If set to 1,
C<expr_coerce> key that the C<coerce()> routine returns must be an expression
that returns an array (envelope) of C<< (error_msg, data) >> instead of just
coerced data. Error message should be a string that is set when coercion fails
and explains why. Otherwise, if coercion succeeds, the string should be set to
undefined value.

An example of a rule like this is coercing from string in the form of
"YYYY-MM-DD" to a DateTime object. The rule might match any string in the form
of C<< /\A(\d{4})-(\d{2})-(\d{2})\z/ >> while it might not be a valid date.

=item * prio => int (0-100, default: 50)

This is to regulate the ordering of rules. The higher the number, the lower the
priority (meaning the rule will be put further back). Rules that are
computationally more expensive and/or match more broadly in general should be
put further back (lower priority, higher number).

=item * precludes => array of (str|re)

List the other rules or rule patterns that are precluded by this rule. Rules
that are mutually exclusive or pure alternatives to one another (e.g. date
coercien rules
L<From_str::natural|Data::Sah::Coerce::To_date::From_str::natural> vs
L<From_str::flexible|Data::Sah::Coerce::To_date::From_str::flexible> both parse
natural language date string; there is usually little to none of usefulness in
using both; besides, both rules match all string and dies when failing to parse
the string. So in C<From_str::natural> rule, you'll find this metadata:

 precludes => [qr/\A(From_str::alami(_.+)?|From_str::natural)\z/]

and in C<From_str::flexible> rule you'll find this metadata:

 precludes => [qr/\A(From_str::alami(_.+)?|From_str::flexible)\z/]

Also note that rules which are specifically requested to be used (e.g. using
C<x.perl.coerce_rules> attribute in Sah schema) will still be precluded.

=back

The module must also contain C<coerce> subroutine which must generate the code
for coercion. The subroutine must accept a hash of arguments (C<*> indicates
required arguments):

=over

=item * data_term => str

=item * coerce_to => str

Some Sah types are "abstract" and can be represented using a choice of several
actual types in the target programming language. For example, "date" can be
represented in Perl as an integer (Unix epoch value), or a DateTime object, or a
Time::Moment object.

Not all target Sah types will need this argument.

=back

The C<coerce> subroutine must return a hashref with the following keys (C<*>
indicates required keys):

=over

=item * expr_match => str

Expression in the target language to test whether the data can be coerced. For
example, in C<Data::Sah::Coerce::perl::To_date::From_float::epoch>, only
integers ranging from 10^8 to 2^31 are converted into date. Non-integers or
integers outside this range are not coerced.

=item * expr_coerce => str

Expression in the target language to actually convert data to the target type.

=item * modules => hash

A list of modules required by the expressions.

=back

Basically, the C<coerce> subroutine must generates a code that accepts a
non-undef data and must convert this data to the desired type/format under the
right condition. The code to match the right condition must be put in
C<expr_match> and the code to convert data must be put in C<expr_coerce>.

Program/library that uses Data::Sah::Coerce can collect rules from the rule
modules then compose them into the final code, something like (in pseudocode):

 if (data is undef) {
   return undef;
 } elsif (data matches expr-match-from-rule1) {
   return expr-coerce-from-rule1;
 } elsif (data matches expr-match-from-rule2) {
   return expr-coerce-from-rule1;
 ...
 } else {
   # does not match any expr-match
   return original data;
 }

=head1 VARIABLES

=head2 $Log_Coercer_Code => bool (default: from ENV or 0)

If set to true, will log the generated coercer code (currently using L<Log::ger>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::Coerce=gen_coercer -E'my $c = gen_coercer(...)'

=head1 FUNCTIONS


=head2 gen_coercer

Usage:

 gen_coercer() -> any

Generate coercer code.

This is mostly for testing. Normally the coercion rules will be used from
L<Data::Sah>.

This function is not exported by default, but exportable.

No arguments.

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_COERCER_CODE => bool

Set default for C<$Log_Coercer_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

L<Data::Sah::CoerceJS>

L<App::SahUtils>, including L<coerce-with-sah> to conveniently test coercion
from the command-line.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
