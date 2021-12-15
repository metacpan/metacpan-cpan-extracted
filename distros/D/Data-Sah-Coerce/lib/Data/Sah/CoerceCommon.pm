package Data::Sah::CoerceCommon;

use 5.010001;
use strict 'subs', 'vars';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.052'; # VERSION

our $SUPPORT_OLD_PREFIX = $ENV{PERL_DATA_SAH_COERCE_SUPPORT_OLD_PREFIX} // 1;

our %Default_Rules = (
    perl => {
        bool       => [qw//],
        datenotime => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        date       => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        datetime   => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        duration   => [qw/From_float::seconds From_obj::datetime_duration From_str::human From_str::iso8601/],
        float      => [qw/From_str::percent/],
        num        => [qw/From_str::percent/],
        timeofday  => [qw/From_obj::date_timeofday From_str::hms/],
    },
    js => {
        bool       => [qw/From_float::zero_one From_str::common_words/],
        datenotime => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        date       => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        datetime   => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        duration   => [qw/From_float::seconds From_str::iso8601/],
        #float      => [qw/From_str::percent/],
        #num        => [qw/From_str::percent/],
        timeofday  => [qw/From_str::hms/],
    },
);

our %common_args = (
    type => {
        schema => 'sah::type_name*',
            req => 1,
        pos => 0,
    },
    coerce_to => {
        schema => 'str*',
        description => <<'_',

Some Sah types, like `date`, can be represented in a choice of types in the
target language. For example, in Perl you can store it as a floating number
a.k.a. `float(epoch)`, or as a <pm:DateTime> object, or <pm:Time::Moment>
object. Storing in DateTime can be convenient for date manipulation but requires
an overhead of loading the module and storing in a bulky format. The choice is
yours to make, via this setting.

_
    },
    coerce_rules => {
        summary => 'A specification of coercion rules to use (or avoid)',
        schema => ['array*', of=>'str*'],
        description => <<'_',

This setting is used to specify which coercion rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either `NAME` to mean
specifically include a rule, or `!NAME` to exclude a rule.

Some coercion modules are used by default, unless explicitly avoided using the
'!NAME' rule.

To not use any rules:

To use the default rules plus R1 and R2:

    ['R1', 'R2']

To use the default rules but not R1 and R2:

    ['!R1', '!R2']

_
    },
);

our %gen_coercer_args = (
    %common_args,
    return_type => {
        schema => ['str*', {
            in => [qw/val bool_coerced+val bool_coerced+str_errmsg+val/],
            prefilters => [
                ["Str::replace_map", {map=>{
                    "status+val"     => "bool_coerced+val",
                    "status+err+val" => "bool_coerced+str_errmsg+val",
                }}],
            ],
        }],
        default => 'val',
        description => <<'_',

`val` means the coercer will return the input (possibly) coerced or undef if
coercion fails.

`bool_coerced+val` means the coercer will return a 2-element array. The first
element is a bool value set to 1 if coercion has been performed or 0 if
otherwise. The second element is the (possibly) coerced input.

`bool_coerced+str_errmsg+val` means the coercer will return a 3-element array.
The first element is a bool value set to 1 if coercion has been performed or 0
if otherwise. The second element is the error message string which will be set
if there is a failure in coercion (or undef if coercion is successful). The
third element is the (possibly) coerced input.

_
    },
    source => {
        summary => 'If set to true, will return coercer source code string'.
            ' instead of compiled code',
        schema => 'bool',
    },
);

our %SPEC;

$SPEC{get_coerce_rules} = {
    v => 1.1,
    summary => 'Get coerce rules',
    description => <<'_',

This routine determines coerce rule modules to use (based on the default set and
`coerce_rules` specified), loads them, filters out modules with old/incompatible
metadata version, and return the list of rules.

This common routine is used by <pm:Data::Sah> compilers, as well as
<pm:Data::Sah::Coerce> and <pm:Data::Sah::CoerceJS>.

_
    args => {
        %common_args,
        compiler => {
            schema => 'str*',
            req => 1,
        },
        data_term => {
            schema => 'str*',
            req => 1,
        },
    },
};
sub get_coerce_rules {
    my %args = @_;

    my $type     = $args{type};
    my $compiler = $args{compiler};
    my $dt       = $args{data_term};

    my $typen = $type; $typen =~ s/::/__/g;
    my $old_prefix = "Data::Sah::Coerce::$compiler\::$typen\::"; # deprecated, <0.034, will be removed in the future
    my $prefix = "Data::Sah::Coerce::$compiler\::To_$typen\::";

    my @rules0 = @{ $Default_Rules{$compiler}{$typen} || [] };
    for my $item (@{ $args{coerce_rules} // [] }) {
        my $rule_name = ref $item eq 'ARRAY' ? $item->[0] : $item;
        my $is_exclude = $rule_name =~ s/\A!//;
        if ($SUPPORT_OLD_PREFIX && $rule_name =~ /\A\w+\z/) {
            # old name
        } elsif ($rule_name =~ /\AFrom_[A-Za-z0-9_]+::[A-Za-z0-9_]+\z/) {
            # new name
        } else {
            die "Invalid syntax for coercion rule item '$item', please ".
                "only use From_<type>::<description>";
        }
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
        my $is_old_name = $SUPPORT_OLD_PREFIX && $rule_name =~ /\A\w+\z/;
        my $mod = ($is_old_name ? $old_prefix : $prefix) . $rule_name;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $rule_meta = &{"$mod\::meta"};
        my $rule_v = ($rule_meta->{v} // 1);
        if ($rule_v != 3 && $rule_v != 4) {
            warn "Only coercion rule module following metadata version 3/4 is ".
                "supported, this rule module '$mod' follows metadata version ".
                "$rule_v and will not be used";
            next;
        }
        my $rule = &{"$mod\::coerce"}(
            data_term => $dt,
            coerce_to => $args{coerce_to},
            (args => $rule_gen_args) x !!$rule_gen_args,
        );
        $rule->{name} = $rule_name;
        $rule->{meta} = $rule_meta;
        push @rules, $rule;
    }

    # sort by priority (then name)
    @rules = sort {
        ($a->{meta}{prio}//50) <=> ($b->{meta}{prio}//50) ||
            $a->{name} cmp $b->{name}
        } @rules;

    # precludes
    {
        my $i = 0;
        while ($i < @rules) {
            my $rule = $rules[$i];
            if ($rule->{meta}{precludes}) {
                for my $j (reverse 0 .. $#rules) {
                    next if $j == $i;
                    my $match;
                    for my $p (@{ $rule->{meta}{precludes} }) {
                        if (ref($p) eq 'Regexp' && $rules[$j]{name} =~ $p ||
                                $rules[$j]{name} eq $p) {
                            $match = 1;
                            last;
                        }
                    }
                    next unless $match;
                    warn "Coercion rule $rules[$j]{name} is precluded by rule $rule->{name}";
                    splice @rules, $j, 1;
                }
            }
            $i++;
        }
    }

    \@rules;
}

1;
# ABSTRACT: Common stuffs for Data::Sah::Coerce and Data::Sah::CoerceJS

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::CoerceCommon - Common stuffs for Data::Sah::Coerce and Data::Sah::CoerceJS

=head1 VERSION

This document describes version 0.052 of Data::Sah::CoerceCommon (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 FUNCTIONS


=head2 get_coerce_rules

Usage:

 get_coerce_rules(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get coerce rules.

This routine determines coerce rule modules to use (based on the default set and
C<coerce_rules> specified), loads them, filters out modules with old/incompatible
metadata version, and return the list of rules.

This common routine is used by L<Data::Sah> compilers, as well as
L<Data::Sah::Coerce> and L<Data::Sah::CoerceJS>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coerce_rules> => I<array[str]>

A specification of coercion rules to use (or avoid).

This setting is used to specify which coercion rules to use (or avoid) in a
flexible way. Each element is a string, in the form of either C<NAME> to mean
specifically include a rule, or C<!NAME> to exclude a rule.

Some coercion modules are used by default, unless explicitly avoided using the
'!NAME' rule.

To not use any rules:

To use the default rules plus R1 and R2:

 ['R1', 'R2']

To use the default rules but not R1 and R2:

 ['!R1', '!R2']

=item * B<coerce_to> => I<str>

Some Sah types, like C<date>, can be represented in a choice of types in the
target language. For example, in Perl you can store it as a floating number
a.k.a. C<float(epoch)>, or as a L<DateTime> object, or L<Time::Moment>
object. Storing in DateTime can be convenient for date manipulation but requires
an overhead of loading the module and storing in a bulky format. The choice is
yours to make, via this setting.

=item * B<compiler>* => I<str>

=item * B<data_term>* => I<str>

=item * B<type>* => I<sah::type_name>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head2 PERL_DATA_SAH_COERCE_SUPPORT_OLD_PREFIX

If set to false, will not support old prefix
(Data::Sah::Coerce::<$TARGET_TYPE>::<$SOURCE_TYPE_AND_DESC>. Mainly for testing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
