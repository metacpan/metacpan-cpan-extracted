package Data::Sah::CoerceCommon;

our $DATE = '2020-01-03'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.046'; # VERSION

use 5.010001;
use strict 'subs', 'vars';

our $SUPPORT_OLD_PREFIX = $ENV{PERL_DATA_SAH_COERCE_SUPPORT_OLD_PREFIX} // 1;

our %Default_Rules = (
    perl => {
        bool       => [qw//],
        date       => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        datenotime => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        datetime   => [qw/From_float::epoch From_obj::datetime From_obj::time_moment From_str::iso8601/],
        duration   => [qw/From_float::seconds From_obj::datetime_duration From_str::human From_str::iso8601/],
        timeofday  => [qw/From_obj::date_timeofday From_str::hms/],
    },
    js => {
        bool       => [qw/From_float::zero_one From_str::common_words/],
        date       => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        datetime   => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        datenotime => [qw/From_float::epoch From_obj::date From_str::date_parse/],
        duration   => [qw/From_float::seconds From_str::iso8601/],
        timeofday  => [qw/From_str::hms/],
    },
);

my %common_args = (
    type => {
        schema => 'str*', # XXX sah::typename
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

my %gen_coercer_args = (
    %common_args,
    return_type => {
        schema => ['str*', in=>[qw/val status+val status+err+val/]],
        default => 'val',
        description => <<'_',

`val` means the coercer will return the input (possibly) coerced or undef if
coercion fails.

`status+val` means the coercer will return a 2-element array. The first element
is a bool value set to 1 if coercion has been performed or 0 if otherwise. The
second element is the (possibly) coerced input (or undef if there is a failure
during coercion).

`status+err+val` means the coercer will return a 3-element array. The first
element is a bool value set to 1 if coercion has been performed or 0 if
otherwise. The second element is the error message string which will be set if
there is a failure in coercion. The third element is the (possibly) coerced
input (or undef if there is a failure during coercion).

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

    my @rule_names = @{ $Default_Rules{$compiler}{$typen} || [] };
    for my $item (@{ $args{coerce_rules} // [] }) {
        my $is_exclude = $item =~ s/\A!//;
        if ($SUPPORT_OLD_PREFIX && $item =~ /\A\w+\z/) {
            # old name
        } elsif ($item =~ /\AFrom_[A-Za-z0-9_]+::[A-Za-z0-9_]+\z/) {
            # new name
        } else {
            die "Invalid syntax for coercion rule item '$item', please ".
                "only use From_<type>::<description>";
        }
        if ($is_exclude) {
            @rule_names = grep { $_ ne $item } @rule_names;
        } else {
            push @rule_names, $item unless grep { $_ eq $item } @rule_names;
        }
    }

    my @rules;
    for my $rule_name (@rule_names) {
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

This document describes version 0.046 of Data::Sah::CoerceCommon (from Perl distribution Data-Sah-Coerce), released on 2020-01-03.

=head1 FUNCTIONS


=head2 get_coerce_rules

Usage:

 get_coerce_rules(%args) -> [status, msg, payload, meta]

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

=item * B<type>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 PERL_DATA_SAH_COERCE_SUPPORT_OLD_PREFIX

If set to false, will not support old prefix
(Data::Sah::Coerce::<$TARGET_TYPE>::<$SOURCE_TYPE_AND_DESC>. Mainly for testing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
