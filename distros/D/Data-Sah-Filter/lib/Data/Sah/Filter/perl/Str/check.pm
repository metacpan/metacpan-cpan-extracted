package Data::Sah::Filter::perl::Str::check;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-16'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.022'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Perform some checks',
        might_fail => 1,
        args => {
            min_len => {
                schema => 'uint*',
            },
            max_len => {
                schema => 'uint*',
            },
            match => {
                schema => 're*',
            },
            in => {
                schema => ['array*', of=>'str*'],
            },
        },
        examples => [
            {value=>"12", filter_args=>{min_len=>3}, valid=>0},
            {value=>"12345", filter_args=>{min_len=>3}, valid=>1},

            {value=>"123", filter_args=>{max_len=>3}, valid=>1},
            {value=>"12345", filter_args=>{max_len=>3}, valid=>0},

            {value=>"123", filter_args=>{match=>'[abc]'}, valid=>0},
            {value=>"a", filter_args=>{match=>'[abc]'}, valid=>1},

        ],
        description => <<'_',

This is more or less a demo filter rule, to show how a filter rule can be used
to perform some checks. The standard checks performed by this rule, however, are
better done using standard <pm:Sah> schema clauses like `in`, `min_len`, etc.

_
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my @check_exprs;
    if (defined $gen_args->{min_len}) {
        my $val = $gen_args->{min_len} + 0;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq( (length(\$tmp) < $val) { ["Length of data must be at least $val", \$tmp] } );
    }
    if (defined $gen_args->{max_len}) {
        my $val = $gen_args->{max_len} + 0;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq( (length(\$tmp) > $val) { ["Length of data must be at most $val", \$tmp] } );
    }
    if (defined $gen_args->{match}) {
        my $val = ref $gen_args->{match} eq 'Regexp' ? $gen_args->{match} : qr/$gen_args->{match}/;
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq| (\$tmp !~ |.dmp($val).qq|) { ["Data must match $val", \$tmp] } |;
    }
    if (defined $gen_args->{in}) {
        my $val = $gen_args->{in};
        push @check_exprs, (@check_exprs ? "elsif" : "if") . qq| (!grep { \$_ eq \$tmp } \@{ |.dmp($val).qq| }) { ["Data must be one of ".join(", ", \@{|.dmp($val).qq|}), \$tmp] } |;
    }
    unless (@check_exprs) {
        push @check_exprs, qq(if (0) { } );
    }
    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do {\n",
        "  my \$tmp = $dt;\n",
        (map { "  $_\n" } @check_exprs),
        "  else { [undef, \$tmp] }\n",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Perform some checks

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::check - Perform some checks

=head1 VERSION

This document describes version 0.022 of Data::Sah::Filter::perl::Str::check (from Perl distribution Data-Sah-Filter), released on 2023-08-16.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::check"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::check"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::check"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 12 # filtered with args {min_len=>3}, INVALID (Length of data must be at least 3), unchanged
 12345 # filtered with args {min_len=>3}, valid, unchanged
 123 # filtered with args {max_len=>3}, valid, unchanged
 12345 # filtered with args {max_len=>3}, INVALID (Length of data must be at most 3), unchanged
 123 # filtered with args {match=>"[abc]"}, INVALID (Data must match (?^:[abc])), unchanged
 "a" # filtered with args {match=>"[abc]"}, valid, unchanged

=for Pod::Coverage ^(meta|filter)$

=head1 DESCRIPTION

This is more or less a demo filter rule, to show how a filter rule can be used
to perform some checks. The standard checks performed by this rule, however, are
better done using standard L<Sah> schema clauses like C<in>, C<min_len>, etc.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
