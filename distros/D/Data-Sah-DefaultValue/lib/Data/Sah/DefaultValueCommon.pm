package Data::Sah::DefaultValueCommon;

use 5.010001;
use strict 'subs', 'vars';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-30'; # DATE
our $DIST = 'Data-Sah-DefaultValue'; # DIST
our $VERSION = '0.003'; # VERSION

our %common_args = (
    default_value_rules => {
        summary => 'A specification of default-value rules to use (or avoid)',
        schema => ['array*', of=>'str*'],
        description => <<'_',

This setting is used to specify which default-value rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either `NAME` to mean
specifically include a rule, or `!NAME` to exclude a rule.

To use the default-value rules R1 and R2:

    ['R1', 'R2']
_
    },
);

our %gen_default_value_code_args = (
    %common_args,
    source => {
        summary => 'If set to true, will return coercer source code string'.
            ' instead of compiled code',
        schema => 'bool',
    },
);

our %SPEC;

$SPEC{get_default_value_rules} = {
    v => 1.1,
    summary => 'Get default-value rules',
    description => <<'_',

This routine determines default-value rule modules to use (based on the
`default_value_rules` specified), loads them, filters out modules with
old/incompatible metadata version, and return the list of rules.

This common routine is used by <pm:Data::Sah> compilers, as well as
<pm:Data::Sah::DefaultValue> and <pm:Data::Sah::DefaultValueJS>.

_
    args => {
        %common_args,
        compiler => {
            schema => 'str*',
            req => 1,
        },
    },
};
sub get_default_value_rules {
    my %args = @_;

    my $compiler = $args{compiler};

    my $prefix = "Data::Sah::Value::$compiler\::";

    my @rules0;
    for my $item (@{ $args{default_value_rules} // [] }) {
        my $rule_name = ref $item eq 'ARRAY' ? $item->[0] : $item;
        my $is_exclude = $rule_name =~ s/\A!//;
        if ($is_exclude) {
            @rules0 = grep { $_ ne $rule_name } @rules0;
        } else {
            push @rules0, $item unless grep { $_ eq $rule_name } @rules0;
        }
    }

    my @rules;
    for my $item (@rules0) {
        my $rule_name = ref $item eq 'ARRAY' ? $item->[0] : $item;
        my $rule_gen_args = ref $item eq 'ARRAY' ? $item->[1] : undef;
        my $mod = $prefix . $rule_name;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $rule_meta = &{"$mod\::meta"};
        my $rule_v = ($rule_meta->{v} // 1);
        if ($rule_v != 1) {
            warn "Only value rule module following metadata version 1 is ".
                "supported, this rule module '$mod' follows metadata version ".
                "$rule_v and will not be used";
            next;
        }
        my $rule = &{"$mod\::value"}(
            (args => $rule_gen_args) x !!$rule_gen_args,
        );
        $rule->{name} = $rule_name;
        $rule->{meta} = $rule_meta;
        push @rules, $rule;
    }

    \@rules;
}

1;
# ABSTRACT: Common stuffs for Data::Sah::DefaultValue and Data::Sah::DefaultValueJS

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::DefaultValueCommon - Common stuffs for Data::Sah::DefaultValue and Data::Sah::DefaultValueJS

=head1 VERSION

This document describes version 0.003 of Data::Sah::DefaultValueCommon (from Perl distribution Data-Sah-DefaultValue), released on 2023-03-30.

=head1 FUNCTIONS


=head2 get_default_value_rules

Usage:

 get_default_value_rules(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get default-value rules.

This routine determines default-value rule modules to use (based on the
C<default_value_rules> specified), loads them, filters out modules with
old/incompatible metadata version, and return the list of rules.

This common routine is used by L<Data::Sah> compilers, as well as
L<Data::Sah::DefaultValue> and L<Data::Sah::DefaultValueJS>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<compiler>* => I<str>

(No description)

=item * B<default_value_rules> => I<array[str]>

A specification of default-value rules to use (or avoid).

This setting is used to specify which default-value rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either C<NAME> to mean
specifically include a rule, or C<!NAME> to exclude a rule.

To use the default-value rules R1 and R2:

 ['R1', 'R2']


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-DefaultValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-DefaultValue>.

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
