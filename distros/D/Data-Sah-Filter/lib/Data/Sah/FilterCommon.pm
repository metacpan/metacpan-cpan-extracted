package Data::Sah::FilterCommon;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-04'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.010'; # VERSION

our %SPEC;

our %common_args = (
    filter_names => {
        schema => ['array*', of=>'str*'],
        req => 1,
    },
);

our %gen_filter_args = (
    %common_args,
    return_type => {
        schema => ['str*', in=>['val', 'errstr+val']],
        default => 'val',
    },
);

$SPEC{get_filter_rules} = {
    v => 1.1,
    summary => 'Get filter rules from filter rule modules',
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
sub get_filter_rules {
    my %args = @_;

    my $compiler = $args{compiler};
    my $dt       = $args{data_term};
    my $prefix = "Data::Sah::Filter::$compiler\::";

    my @rules;
    for my $entry (@{ $args{filter_names} }) {
        my $filter_name = ref $entry eq 'ARRAY' ? $entry->[0] : $entry;
        my $filter_gen_args = ref $entry eq 'ARRAY' ? $entry->[1] : undef;

        my $mod = $prefix . $filter_name;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $filter_meta = &{"$mod\::meta"};
        my $filter_v = ($filter_meta->{v} // 1);
        if ($filter_v != 1) {
            die "Only filter module following metadata version 1 is ".
                "supported, this filter module '$mod' follows metadata version ".
                "$filter_v and cannot be used";
        }
        my $rule = &{"$mod\::filter"}(
            data_term => $dt,
            (args => $filter_gen_args) x !!$filter_gen_args,
        );
        $rule->{name} = $filter_name;
        $rule->{meta} = $filter_meta;
        push @rules, $rule;
    }

    \@rules;
}

1;
# ABSTRACT: Common stuffs for Data::Sah::Filter and Data::Sah::FilterJS

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::FilterCommon - Common stuffs for Data::Sah::Filter and Data::Sah::FilterJS

=head1 VERSION

This document describes version 0.010 of Data::Sah::FilterCommon (from Perl distribution Data-Sah-Filter), released on 2022-07-04.

=head1 FUNCTIONS


=head2 get_filter_rules

Usage:

 get_filter_rules(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get filter rules from filter rule modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<compiler>* => I<str>

=item * B<data_term>* => I<str>

=item * B<filter_names>* => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
