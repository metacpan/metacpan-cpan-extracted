package Cwalitee::Common;

our $DATE = '2019-07-07'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

our $schema_indicator_status = [
    'str*', {
        'x.examples' => ['stable', 'optional', 'experimental', 'deprecated'],
    },
];

our $schema_severity = ['int*', between=>[1,5]];

our %arg_prefix = (
    prefix => {
        schema => 'perl::modprefix*',
        default => '',
    },
);

our %args_list = (
    detail => {
        schema => 'bool*',
        cmdline_aliases=>{l=>{}},
    },
    include => {
        summary => 'Include by name',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {I=>{}},
        tags => ['category:filtering'],
    },
    exclude => {
        summary => 'Exclude by name',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {X=>{}},
        tags => ['category:filtering'],
    },

    include_status => {
        summary => 'Include by status',
        schema => ['array*', of=>$schema_indicator_status],
        default => ['stable'],
        tags => ['category:filtering'],
    },
    exclude_status => {
        summary => 'Exclude by status',
        schema => ['array*', of=>$schema_indicator_status],
        tags => ['category:filtering'],
    },

    include_module => {
        summary => 'Include by module',
        schema => ['array*', of=>'perl::modname*'],
        tags => ['category:filtering'],
    },
    exclude_module => {
        summary => 'Exclude by module',
        schema => ['array*', of=>'perl::modname*'],
        tags => ['category:filtering'],
    },

    min_severity => {
        summary => 'Minimum severity',
        schema => $schema_severity,
        default => 1,
        tags => ['category:filtering'],
    },
    max_severity => {
        summary => 'Maximum severity',
        schema => $schema_severity,
        default => 5,
        tags => ['category:filtering'],
    },
);

sub args_list {
    my ($prefix) = @_;
    $prefix .= '::' unless $prefix =~ /::\z/;
    my %res;
    for my $arg (keys %args_list) {
        my $argspec = {%{ $args_list{$arg} }};
        if ($arg =~ /^(include|exclude)$/) {
            $argspec->{element_completion} = sub {
                require Complete::Util;
                my %args = @_;
                my $res = list_cwalitee_indicators(
                    prefix => $prefix,
                    detail => 1,
                );
                return {message=>"Cannot list indicators (prefix=$prefix): $res->[0] - $res->[1]"}
                    unless $res->[0] == 200;
                my (@array, @summaries);
                for (@{ $res->[2] }) {
                    push @array, $_->{name};
                    push @summaries, $_->{summary};
                }
                Complete::Util::complete_array_elem(
                    word => $args{word},
                    array     => \@array,
                    summaries => \@summaries,
                );
            };
        }
        if ($arg =~ /^(include|exclude)_module$/) {
            $argspec->{element_completion} = sub {
                require Complete::Module;
                my %args = @_;
                $args{word} ||= "${prefix}Cwalitee::";
                Complete::Module::complete_module(
                    word => $args{word},
                );
            };
        }
        $res{$arg} = $argspec;
    }
    %res;
}

our %args_calc = (
    include_indicator => {
        summary => 'Only use these indicators',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {I=>{}},
        tags => ['category:indicator-selection'],
    },
    exclude_indicator => {
        summary => 'Do not use these indicators',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {X=>{}},
        tags => ['category:indicator-selection'],
    },

    include_indicator_status => {
        summary => 'Only use indicators having these statuses',
        schema => ['array*', of=>$schema_indicator_status],
        default => ['stable'],
        tags => ['category:indicator-selection'],
    },
    exclude_indicator_status => {
        summary => 'Do not use indicators having these statuses',
        schema => ['array*', of=>$schema_indicator_status],
        tags => ['category:indicator-selection'],
    },

    include_indicator_module => {
        summary => 'Only use indicators from these modules',
        schema => ['array*', of=>'perl::modname*'],
        tags => ['category:indicator-selection'],
    },
    exclude_indicator_module => {
        summary => 'Do not use indicators from these modules',
        schema => ['array*', of=>'perl::modname*'],
        tags => ['category:indicator-selection'],
    },

    min_indicator_severity => {
        summary => 'Minimum indicator severity',
        schema => 'uint*',
        default => 1,
        tags => ['category:indicator-selection'],
    },
    # we don't see much point in specifying max_indicator_severity
);

sub args_calc {
    my ($prefix) = @_;
    $prefix .= '::' unless $prefix =~ /::\z/;
    my %res;
    for my $arg (keys %args_calc) {
        my $argspec = {%{ $args_calc{$arg} }};
        if ($arg =~ /^(include|exclude)_indicator$/) {
            $argspec->{element_completion} = sub {
                require Complete::Util;
                my %args = @_;
                my $res = list_cwalitee_indicators(
                    prefix => $prefix,
                    detail => 1,
                );
                return {message=>"Cannot list indicators (prefix=$prefix): $res->[0] - $res->[1]"}
                    unless $res->[0] == 200;
                my (@array, @summaries);
                for (@{ $res->[2] }) {
                    push @array, $_->{name};
                    push @summaries, $_->{summary};
                }
                Complete::Util::complete_array_elem(
                    word => $args{word},
                    array     => \@array,
                    summaries => \@summaries,
                );
            };
        }
        if ($arg =~ /^(include|exclude)_indicator_module$/) {
            $argspec->{element_completion} = sub {
                require Complete::Module;
                my %args = @_;
                $args{word} ||= "${prefix}Cwalitee::";
                Complete::Module::complete_module(
                    word => $args{word},
                );
            };
        }
        $res{$arg} = $argspec;
    }
    %res;
}

$SPEC{list_cwalitee_indicators} = {
    v => 1.1,
    args => {
        %arg_prefix,
        %args_list,
    },
};
sub list_cwalitee_indicators {
    require PERLANCAR::Module::List;

    my %args = @_;
    my $prefix = $args{prefix} // '';
    $prefix .= "::" if length($prefix) && $prefix !~ /::\z/;

    my @res;

    my $mods = PERLANCAR::Module::List::list_modules(
        "${prefix}Cwalitee::", {list_modules=>1, recurse=>1});
    my %seen_names; # val = module

  MOD:
    for my $mod (sort keys %$mods) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $spec = \%{"$mod\::SPEC"};

      INDICATOR:
        for my $func (sort keys %$spec) {
            my ($name) = $func =~ /\Aindicator_(\w+)\z/ or next;
            warn "Duplicate name $name (module $mod and $seen_names{$mod})"
                if $seen_names{$name};
            $seen_names{$name} = $mod;
            my $funcmeta = $spec->{$func};
            my $status   = $funcmeta->{'x.indicator.status'} // 'stable';
            my $severity = $funcmeta->{'x.indicator.severity'} // 3;
            my $rec = {
                name     => $name,
                module   => $mod,
                summary  => $funcmeta->{summary},
                priority => $funcmeta->{'x.indicator.priority'} // 50,
                severity => $severity,
                status   => $status,
            };
            if ($args{_return_coderef}) {
                $rec->{code} = \&{"$mod\::$func"};
            }

          FILTER: {
                if ($args{include} && @{ $args{include} }) {
                    next INDICATOR unless grep { $name eq $_ } @{ $args{include} };
                }
                if ($args{exclude} && @{ $args{exclude} }) {
                    next INDICATOR if     grep { $name eq $_ } @{ $args{exclude} };
                }

                if ($args{include_status} && @{ $args{include_status} }) {
                    next INDICATOR unless grep { $status eq $_ } @{ $args{include_status} };
                }
                if ($args{exclude_status} && @{ $args{exclude_status} }) {
                    next INDICATOR if     grep { $status eq $_ } @{ $args{exclude_status} };
                }

                if ($args{include_module} && @{ $args{include_module} }) {
                    next INDICATOR unless grep { $mod eq $_ } @{ $args{include_module} };
                }
                if ($args{exclude_module} && @{ $args{exclude_module} }) {
                    next INDICATOR if     grep { $mod eq $_ } @{ $args{exclude_module} };
                }

                next INDICATOR if $severity < ($args{min_severity} // 1);
                next INDICATOR if $severity > ($args{max_severity} // 5);
            } # FILTER

            push @res, $rec;
        }
    }

    unless ($args{detail}) {
        @res = map { $_->{name} } @res;
    }

    [200, "OK", \@res];
}

$SPEC{calc_cwalitee} = {
    v => 1.1,
    args => {
        %arg_prefix,
        %args_calc,
        code_init_r  => {schema=>'code*', req=>1},
        code_fixup_r => {schema=>'code*'},
    },
};
sub calc_cwalitee {
    my %args = @_;

    my $res = list_cwalitee_indicators(
        prefix => $args{prefix},
        detail => 1,
        _return_coderef => 1,
        include        => $args{include_indicator},
        exclude        => $args{exclude_indicator},
        include_status => $args{include_indicator_status} // ['stable'],
        exclude_status => $args{exclude_indicator_status},
        include_module => $args{include_indicator_module},
        exclude_module => $args{exclude_indicator_module},
        min_severity   => $args{min_indicator_severity},
    );
    return $res unless $res->[0] == 200;

    my @res;
    my $r = $args{code_init_r}->();
    my $num_run = 0;
    my $num_success = 0;
    my $num_fail = 0;
    for my $ind (sort {
        $a->{priority} <=> $b->{priority} ||
            $a->{name} cmp $b->{name}
        } @{ $res->[2] }) {

        $args{code_fixup_r}->(indicator=>$ind, r=>$r)
            if $args{code_fixup_r};

        my $indres = $ind->{code}->(r => $r);
        $num_run++;
        my ($result, $result_summary);
        if ($indres->[0] == 200) {
            if ($indres->[2]) {
                $result = 0;
                $num_fail++;
                $result_summary = $indres->[2];
            } else {
                $result = 1;
                $num_success++;
                $result_summary = '';
            }
        } elsif ($indres->[0] == 412) {
            $result = undef;
            $result_summary = "Cannot be run".($indres->[1] ? ": $indres->[1]" : "");
        } else {
            return [500, "Unexpected result when checking indicator ".
                        "'$ind->{name}': $indres->[0] - $indres->[1]"];
        }
        my $res = {
            num => $num_run,
            indicator => $ind->{name},
            #priority => $ind->{priority},
            severity => $ind->{severity},
            #summary  => $ind->{summary},
            result => $result,
            result_summary => $result_summary,
        };
        push @res, $res;

    }

    push @res, {
        indicator      => 'Score',
        result         => sprintf("%.2f", $num_run ? ($num_success / $num_run)*100 : 0),
        result_summary => "$num_success out of $num_run",
    };

    [200, "OK", \@res];
}

1;
# ABSTRACT: Common Cwalitee routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Cwalitee::Common - Common Cwalitee routines

=head1 VERSION

This document describes version 0.002 of Cwalitee::Common (from Perl distribution Cwalitee-Common), released on 2019-07-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<What is cwalitee?> Metric to attempt to gauge the quality of something. Since
actual quality is hard to measure, this metric is called a "cwalitee" instead.
The cwalitee concept follows "kwalitee" [1] which is specifically to measure the
quality of CPAN distribution. I pick a different spelling to avoid confusion
with kwalitee. And unlike kwalitee, the unqualified term "cwalitee" does not
refer to a specific, particular subject. There can be "module abstract cwalitee"
(which is handled by this module), "CPAN Changes cwalitee", and so on.

=head1 FUNCTIONS


=head2 calc_cwalitee

Usage:

 calc_cwalitee(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code_fixup_r> => I<code>

=item * B<code_init_r>* => I<code>

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

=item * B<include_indicator> => I<array[str]>

Only use these indicators.

=item * B<include_indicator_module> => I<array[perl::modname]>

Only use indicators from these modules.

=item * B<include_indicator_status> => I<array[str]> (default: ["stable"])

Only use indicators having these statuses.

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=item * B<prefix> => I<perl::modprefix> (default: "")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_cwalitee_indicators

Usage:

 list_cwalitee_indicators(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exclude> => I<array[str]>

Exclude by name.

=item * B<exclude_module> => I<array[perl::modname]>

Exclude by module.

=item * B<exclude_status> => I<array[str]>

Exclude by status.

=item * B<include> => I<array[str]>

Include by name.

=item * B<include_module> => I<array[perl::modname]>

Include by module.

=item * B<include_status> => I<array[str]> (default: ["stable"])

Include by status.

=item * B<max_severity> => I<int> (default: 5)

Maximum severity.

=item * B<min_severity> => I<int> (default: 1)

Minimum severity.

=item * B<prefix> => I<perl::modprefix> (default: "")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(args?_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Cwalitee-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Cwalitee-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Cwalitee-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Changes::Cwalitee>

L<Module::Abstract::Cwalitee>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
