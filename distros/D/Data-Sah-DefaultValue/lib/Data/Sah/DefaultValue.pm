package Data::Sah::DefaultValue;

use 5.010001;
use strict;
use warnings;
no warnings 'once';
use Log::ger;

use Data::Sah::DefaultValueCommon;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-30'; # DATE
our $DIST = 'Data-Sah-DefaultValue'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(gen_default_value_code);

our %SPEC;

our $Log_Default_Value_Code = $ENV{LOG_SAH_DEFAULT_VALUE_CODE} // 0;

$SPEC{gen_default_value_code} = {
    v => 1.1,
    summary => 'Generate code to set default value',
    description => <<'_',

This is mostly for testing. Normally the default value rules will be used from
<pm:Data::Sah> via the `x.perl.default_value_rules` or
`x.js.default_value_rules` or `x.default_value_rules` property.

_
    args => {
        %Data::Sah::DefaultValueCommon::gen_default_value_code_args,
    },
    result_naked => 1,
};
sub gen_default_value_code {
    my %args = @_;

    my $rules = Data::Sah::DefaultValueCommon::get_default_value_rules(
        %args,
        compiler=>'perl',
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

        my $expr = '';
        for my $i (reverse 0..$#{$rules}) {
            $expr .= (length($expr) ? ' // ' : '') .
                "($rules->[$i]{expr_value})";
        }

        $code = join(
            "",
            $code_require,
            "sub { shift // $expr };\n",
        );
    } else {
        $code = 'sub { shift }';
    }

    if ($Log_Default_Value_Code) {
        log_trace("Default-value code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    my $default_value_code = eval $code; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die if $@;
    $default_value_code;
}

1;
# ABSTRACT: Default-value rules for Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::DefaultValue - Default-value rules for Data::Sah

=head1 VERSION

This document describes version 0.003 of Data::Sah::DefaultValue (from Perl distribution Data-Sah-DefaultValue), released on 2023-03-30.

=head1 SYNOPSIS

 use Data::Sah::DefaultValue  qw(gen_default_value_code);

 # a utility routine: gen_default_value_code
 my $dv = gen_default_value_code(
     default_value_rules => ['Perl::this_mod'],
 );

 my $val = $c->(123);          # unchanged, 123
 my $val = $c->(undef);        # becomes "Some::Module"

=head1 DESCRIPTION

This module generates code to set default value using value rules.

A value rule is put in C<Data::Sah::Value::$COMPILER::$TOPIC::$DESCRIPTION>
module, for example: L<Data::Sah::Value::perl::Perl::this_mod> contains the
value "this module" (see L<App::ThisDist> for more details on the meaning of
"this module").

Basically, a value rule will provide an expression (C<expr_value>) that return
some value.

The module must contain C<meta> subroutine which must return a hashref that has
the following keys (C<*> marks that the key is required):

=over

=item * v* => int (default: 1)

Metadata specification version. From L<DefHash>. Currently at 4.

=item * summary => str

From L<DefHash>.

=back

The module must also contain C<default_value> subroutine which must generate the
code for default value. The subroutine must accept a hash of arguments (C<*>
indicates required arguments):

=over

=back

The C<value> subroutine must return a hashref with the following keys (C<*>
indicates required keys):

=over

=item * expr_value => str

Expression in the target language that produces the value.

=item * modules => hash

A list of modules required by the expressions.

=back

=head1 VARIABLES

=head2 $Log_Default_Value_Code => bool (default: from ENV or 0)

If set to true, will log the generated default-value code (currently using
L<Log::ger> at trace level). To see the log message, e.g. to the screen, you can
use something like:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
     -MData::Sah::DefaultValue=gen_default_value_code -E'my $c = gen_default_value_code(...)'

=head1 FUNCTIONS


=head2 gen_default_value_code

Usage:

 gen_default_value_code(%args) -> any

Generate code to set default value.

This is mostly for testing. Normally the default value rules will be used from
L<Data::Sah> via the C<x.perl.default_value_rules> or
C<x.js.default_value_rules> or C<x.default_value_rules> property.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_value_rules> => I<array[str]>

A specification of default-value rules to use (or avoid).

This setting is used to specify which default-value rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either C<NAME> to mean
specifically include a rule, or C<!NAME> to exclude a rule.

To use the default-value rules R1 and R2:

 ['R1', 'R2']

=item * B<source> => I<bool>

If set to true, will return coercer source code string instead of compiled code.


=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 LOG_SAH_DEFAULT_VALUE_CODE => bool

Set default for C<$Log_Default_Value_Code>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-DefaultValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-DefaultValue>.

=head1 SEE ALSO

L<Data::Sah::DefaultValueCommon> for detailed syntax of default-value rules
(explicitly including/excluding rules etc).

L<Data::Sah>

L<Data::Sah::DefaultValueJS>

L<App::SahUtils>

=head1 HISTORY

2021-11-28: Created modelled from L<Data::Sah::Coerce> and L<Data::Sah::Filter>
to be able to express dynamic default value into schema.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-DefaultValue>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
